import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { window } from '@kit.ArkUI';
import {
  HeartRateEpisode,
  HeartRateSample,
  HeartRateUpload,
  RemoteSafeArea,
  StatusReport,
  WatchEventRequest,
  WatchLocationPoint
} from '../models/WatchRequests';
import {
  K_BATTERY,
  K_HR_ALERTING,
  K_HR_AT,
  K_HR_BPM,
  K_HR_SHARED_AT,
  K_HR_SIMULATED,
  K_HR_STATE,
  K_LOC_SHARED_AT,
  K_LOC_STATE,
  K_SYNC_ERROR,
  MonitorState
} from '../models/WatchState';
import { batteryPercent, runningOnEmulator } from '../platform/DeviceEnvironment';
import { HeartRateSensor, SensorAvailability } from '../platform/HeartRateSensor';
import {
  HEALTH_PERMISSIONS,
  LOCATION_PERMISSIONS,
  requestLocationSwitch,
  requestPermissions
} from '../platform/Permissions';
import {
  EpisodeEventKind,
  HeartRateAlertDetector,
  HeartRateEpisodeEvent,
  isPlausibleBpm,
  medianBpm
} from './HeartRateAlertDetector';
import { generateEventId, watchApi, WatchApiError, watchSession } from './WatchApi';

/** Upload cadence: readings are reduced to one median sample per window and sent in batches. */
const TICK_MS = 30 * 1000;
const SAMPLE_WINDOW_MS = 30 * 1000;
/** Well under a third of the backend's default 15-minute staleness threshold. */
const HEARTBEAT_MS = 60 * 1000;
/** A fix older than this is not shared as the watch's current location. */
const FIX_FRESH_MS = 2 * 60 * 1000;
/** The backend accepts at most 500 samples per batch; older ones are dropped first when offline. */
const MAX_PENDING_SAMPLES = 500;
const DISPLAY_UPDATE_MS = 5 * 1000;
/** Location Kit error when the device-wide location switch is off. */
const LOCATION_SWITCH_OFF = 3301100;

function distanceMeters(latA: number, lngA: number, latB: number, lngB: number): number {
  const earthRadiusMeters = 6371000;
  const toRadians = Math.PI / 180;
  const dLat = (latB - latA) * toRadians;
  const dLng = (lngB - lngA) * toRadians;
  const value = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(latA * toRadians) * Math.cos(latB * toRadians) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}

/**
 * Runs the watch's monitoring while the app is in the foreground: heart rate
 * (Sensor Service Kit), its own location (Location Kit) and the uploads to the
 * care service. Sensors must not run in the background, so the ability pauses
 * this on `onBackground` and resumes it on `onForeground`. State for the screens
 * goes through AppStorage (see WatchState).
 */
export class WatchMonitor {
  private context: common.UIAbilityContext | undefined = undefined;
  /** The home screen asked for monitoring; it resumes whenever the app returns to the foreground. */
  private wanted: boolean = false;
  private running: boolean = false;
  /** Bumped on every resume and pause, so a start that was waiting on a permission prompt can tell it is stale. */
  private generation: number = 0;
  private timer: number = -1;
  private readonly heartRate: HeartRateSensor = new HeartRateSensor();
  private readonly detector: HeartRateAlertDetector = new HeartRateAlertDetector();
  private windowValues: number[] = [];
  private windowStart: number = 0;
  private lastDisplayAt: number = 0;
  private pendingSamples: HeartRateSample[] = [];
  private pendingEvents: WatchEventRequest[] = [];
  private uploadingSamples: boolean = false;
  private flushingEvents: boolean = false;
  private sendingHeartbeat: boolean = false;
  private lastFix: WatchLocationPoint | undefined = undefined;
  private lastFixAt: number = 0;
  private lastHeartbeatAt: number = 0;
  private safeArea: RemoteSafeArea | undefined = undefined;
  private readonly locationCallback: (location: geoLocationManager.Location) => void =
    (location: geoLocationManager.Location): void => this.onLocation(location);

  async start(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    this.wanted = true;
    await this.resume();
  }

  async resume(): Promise<void> {
    if (!this.wanted || this.running || this.context === undefined) {
      return;
    }
    this.running = true;
    const generation = ++this.generation;
    this.timer = setInterval(() => this.tick(), TICK_MS);
    this.keepScreenOn(true);
    await this.startHeartRate(generation);
    if (!this.isCurrent(generation)) {
      return;
    }
    await this.startLocation(generation);
    if (!this.isCurrent(generation)) {
      return;
    }
    this.loadSafeArea();
    this.tick();
  }

  private isCurrent(generation: number): boolean {
    return this.running && generation === this.generation;
  }

  /** Stops sensors and location; pending samples and events stay queued for the next resume. */
  pause(): void {
    if (!this.running) {
      return;
    }
    this.running = false;
    this.generation++;
    if (this.timer >= 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    this.heartRate.stop();
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
    } catch (error) {
      console.error(`[WatchMonitor] location off failed: ${(error as BusinessError).code}`);
    }
    this.closeWindow(Date.now());
    this.detector.resetTiming();
    this.keepScreenOn(false);
    AppStorage.set<string>(K_HR_STATE, MonitorState.OFF);
    AppStorage.set<string>(K_LOC_STATE, MonitorState.OFF);
  }

  /** Used when the watch is unpaired: nothing resumes and nothing queued is sent with a cleared token. */
  stop(): void {
    this.wanted = false;
    this.pause();
    this.pendingSamples = [];
    this.pendingEvents = [];
    this.lastFix = undefined;
  }

  /**
   * The SOS screen sends through here so the request carries the watch's own
   * last known location. Unlike heartbeats, an older fix is still attached:
   * its `sampledAt` lets the guardian judge how old it is.
   */
  async sendSos(id: string, occurredAt: number): Promise<void> {
    const request = new WatchEventRequest(id, 'sos', occurredAt, 'device');
    const fix = this.lastKnownFix();
    if (fix !== undefined) {
      request.location = fix;
    }
    await watchApi.request(`/seniors/${watchSession.seniorId}/events`, http.RequestMethod.POST, request);
  }

  private source(): string {
    return this.heartRate.simulated ? 'simulated' : 'device';
  }

  private locationSource(): string {
    return runningOnEmulator() ? 'simulated' : 'device';
  }

  private async startHeartRate(generation: number): Promise<void> {
    AppStorage.set<string>(K_HR_STATE, MonitorState.STARTING);
    const granted = await requestPermissions(this.context as common.UIAbilityContext, HEALTH_PERMISSIONS);
    if (!this.isCurrent(generation)) {
      return;
    }
    if (!granted) {
      AppStorage.set<string>(K_HR_STATE, MonitorState.DENIED);
      return;
    }
    const availability = this.heartRate.probe();
    if (availability !== SensorAvailability.Available) {
      AppStorage.set<string>(K_HR_STATE,
        availability === SensorAvailability.Missing ? MonitorState.MISSING : MonitorState.FAILED);
      return;
    }
    AppStorage.set<boolean>(K_HR_SIMULATED, this.heartRate.simulated);
    const started = this.heartRate.start((bpm: number) => this.onHeartRate(bpm));
    AppStorage.set<string>(K_HR_STATE, started ? MonitorState.ACTIVE : MonitorState.FAILED);
  }

  private onHeartRate(bpm: number): void {
    // 0 means an unreliable reading (e.g. the watch is not worn): never shown, shared or evaluated.
    if (!isPlausibleBpm(bpm)) {
      return;
    }
    const now = Date.now();
    if (bpm !== AppStorage.get<number>(K_HR_BPM) || now - this.lastDisplayAt >= DISPLAY_UPDATE_MS) {
      AppStorage.set<number>(K_HR_BPM, bpm);
      AppStorage.set<number>(K_HR_AT, now);
      this.lastDisplayAt = now;
    }
    if (this.windowStart === 0) {
      this.windowStart = now;
    }
    this.windowValues.push(bpm);
    if (now - this.windowStart >= SAMPLE_WINDOW_MS) {
      this.closeWindow(now);
    }
    const event = this.detector.feed(bpm, now);
    if (event !== undefined) {
      this.queueEpisode(event);
    }
  }

  private closeWindow(now: number): void {
    if (this.windowValues.length > 0) {
      this.pendingSamples.push(new HeartRateSample(medianBpm(this.windowValues), now));
      // While an upload is in flight its batch is at the front, so only trim between uploads.
      if (!this.uploadingSamples && this.pendingSamples.length > MAX_PENDING_SAMPLES) {
        this.pendingSamples.splice(0, this.pendingSamples.length - MAX_PENDING_SAMPLES);
      }
    }
    this.windowValues = [];
    this.windowStart = 0;
  }

  private queueEpisode(event: HeartRateEpisodeEvent): void {
    const outOfRange = event.kind === EpisodeEventKind.OutOfRange;
    const request = new WatchEventRequest(generateEventId(),
      outOfRange ? 'heart_rate_out_of_range' : 'heart_rate_in_range', event.at, this.source());
    if (outOfRange) {
      const thresholds = this.detector.thresholds;
      request.heartRate = new HeartRateEpisode(event.bpm, event.direction, thresholds.lowBpm, thresholds.highBpm,
        Math.round(thresholds.sustainedMs / 1000));
    }
    this.pendingEvents.push(request);
    AppStorage.set<boolean>(K_HR_ALERTING, this.detector.isAlerting());
    this.flushEvents();
  }

  private async startLocation(generation: number): Promise<void> {
    AppStorage.set<string>(K_LOC_STATE, MonitorState.STARTING);
    const granted = await requestPermissions(this.context as common.UIAbilityContext, LOCATION_PERMISSIONS);
    if (!this.isCurrent(generation)) {
      return;
    }
    if (!granted) {
      AppStorage.set<string>(K_LOC_STATE, MonitorState.DENIED);
      return;
    }
    // The permission is useless while the watch's own location switch is off; ask the system to turn it on.
    if (!this.locationEnabled()) {
      await requestLocationSwitch(this.context as common.UIAbilityContext);
      if (!this.isCurrent(generation)) {
        return;
      }
      if (!this.locationEnabled()) {
        AppStorage.set<string>(K_LOC_STATE, MonitorState.SWITCH_OFF);
        return;
      }
    }
    const request: geoLocationManager.LocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      timeInterval: 30,
      distanceInterval: 0
    };
    try {
      geoLocationManager.on('locationChange', request, this.locationCallback);
      AppStorage.set<string>(K_LOC_STATE, MonitorState.ACTIVE);
    } catch (error) {
      const code = (error as BusinessError).code;
      console.error(`[WatchMonitor] location on failed: ${code}`);
      AppStorage.set<string>(K_LOC_STATE,
        code === LOCATION_SWITCH_OFF ? MonitorState.SWITCH_OFF : MonitorState.FAILED);
    }
  }

  private locationEnabled(): boolean {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (error) {
      return false;
    }
  }

  private onLocation(location: geoLocationManager.Location): void {
    const now = Date.now();
    const sampledAt = location.timeStamp > 0 ? location.timeStamp : now;
    this.lastFix = new WatchLocationPoint(location.latitude, location.longitude, location.accuracy, sampledAt);
    this.lastFixAt = now;
    // Share the first fix right away instead of waiting for the next heartbeat.
    if (now - this.lastHeartbeatAt >= HEARTBEAT_MS) {
      this.sendHeartbeat(now);
    }
  }

  /** This watch's last fix or the system's cached one, whichever is newer; never waits for a new fix. */
  private lastKnownFix(): WatchLocationPoint | undefined {
    let system: WatchLocationPoint | undefined = undefined;
    try {
      const location = geoLocationManager.getLastLocation();
      system = new WatchLocationPoint(location.latitude, location.longitude, location.accuracy,
        location.timeStamp > 0 ? location.timeStamp : Date.now());
    } catch (error) {
      // No permission, location switched off, or no cached fix yet.
      console.info(`[WatchMonitor] no system last location: ${(error as BusinessError).code}`);
    }
    if (system === undefined || this.lastFix === undefined) {
      return system ?? this.lastFix;
    }
    return Date.parse(system.sampledAt) > Date.parse(this.lastFix.sampledAt) ? system : this.lastFix;
  }

  private freshFix(now: number): WatchLocationPoint | undefined {
    return this.lastFix !== undefined && now - this.lastFixAt <= FIX_FRESH_MS ? this.lastFix : undefined;
  }

  private async loadSafeArea(): Promise<void> {
    try {
      this.safeArea = await watchApi.request(`/seniors/${watchSession.seniorId}/safe-area`,
        http.RequestMethod.GET) as RemoteSafeArea;
    } catch (error) {
      // No safe area configured yet (404) or offline: the heartbeat then reports "unknown".
      this.safeArea = undefined;
    }
  }

  /** Inside/outside of the guardian's safe area, judged from this watch's own fix (watches have no geofence API). */
  private monitoringState(fix: WatchLocationPoint | undefined): string {
    if (fix === undefined) {
      const state = AppStorage.get<string>(K_LOC_STATE);
      return state === MonitorState.DENIED || state === MonitorState.SWITCH_OFF ? 'unavailable' : 'unknown';
    }
    const area = this.safeArea;
    if (area === undefined || fix.accuracyM > area.radiusM) {
      return 'unknown';
    }
    return distanceMeters(area.lat, area.lng, fix.lat, fix.lng) <= area.radiusM ? 'inside' : 'outside';
  }

  private tick(): void {
    if (!this.running) {
      return;
    }
    const now = Date.now();
    AppStorage.set<number>(K_BATTERY, batteryPercent());
    if (this.windowStart > 0 && now - this.windowStart >= SAMPLE_WINDOW_MS) {
      this.closeWindow(now);
    }
    this.flushEvents();
    this.uploadSamples();
    if (now - this.lastHeartbeatAt >= HEARTBEAT_MS) {
      this.sendHeartbeat(now);
    }
  }

  private async sendHeartbeat(now: number): Promise<void> {
    if (this.sendingHeartbeat || !watchSession.configured()) {
      return;
    }
    this.sendingHeartbeat = true;
    const fix = this.freshFix(now);
    const report = new StatusReport(this.monitoringState(fix), this.locationSource());
    if (fix !== undefined) {
      report.location = fix;
    }
    const battery = batteryPercent();
    if (battery >= 0) {
      report.battery = battery;
    }
    try {
      await watchApi.request(`/seniors/${watchSession.seniorId}/status`, http.RequestMethod.PUT, report);
      this.lastHeartbeatAt = now;
      if (fix !== undefined) {
        AppStorage.set<number>(K_LOC_SHARED_AT, now);
      }
      AppStorage.set<string>(K_SYNC_ERROR, '');
    } catch (error) {
      this.reportFailure(error);
    } finally {
      this.sendingHeartbeat = false;
    }
  }

  private async uploadSamples(): Promise<void> {
    if (this.uploadingSamples || this.pendingSamples.length === 0 || !watchSession.configured()) {
      return;
    }
    this.uploadingSamples = true;
    const batch = this.pendingSamples.slice(0, MAX_PENDING_SAMPLES);
    try {
      await watchApi.request(`/seniors/${watchSession.seniorId}/vitals`, http.RequestMethod.POST,
        new HeartRateUpload(this.source(), batch));
      this.pendingSamples.splice(0, batch.length);
      AppStorage.set<number>(K_HR_SHARED_AT, Date.now());
      AppStorage.set<string>(K_SYNC_ERROR, '');
    } catch (error) {
      // A rejected batch would be rejected again: drop it. Anything else is retried with the same batch.
      if (error instanceof WatchApiError && error.isRejected()) {
        this.pendingSamples.splice(0, batch.length);
      }
      this.reportFailure(error);
    } finally {
      this.uploadingSamples = false;
    }
  }

  /** Sends heart-rate episode events in order, each with its own stable id, so retries never duplicate alerts. */
  private async flushEvents(): Promise<void> {
    if (this.flushingEvents || !watchSession.configured()) {
      return;
    }
    this.flushingEvents = true;
    try {
      while (this.pendingEvents.length > 0) {
        try {
          await watchApi.request(`/seniors/${watchSession.seniorId}/events`, http.RequestMethod.POST,
            this.pendingEvents[0]);
          this.pendingEvents.shift();
        } catch (error) {
          if (error instanceof WatchApiError && error.isRejected()) {
            this.pendingEvents.shift();
            this.reportFailure(error);
            continue;
          }
          this.reportFailure(error);
          return;
        }
      }
    } finally {
      this.flushingEvents = false;
    }
  }

  private reportFailure(error: Object): void {
    const status = error instanceof WatchApiError ? error.status : 0;
    const message = status === 0 ? 'Care service not reachable. Will retry.'
      : status === 401 ? 'This watch was removed. Pair it again.'
        : `Care service error ${status}.`;
    AppStorage.set<string>(K_SYNC_ERROR, message);
  }

  private async keepScreenOn(on: boolean): Promise<void> {
    if (this.context === undefined) {
      return;
    }
    try {
      const mainWindow = await window.getLastWindow(this.context);
      await mainWindow.setWindowKeepScreenOn(on);
    } catch (error) {
      console.error(`[WatchMonitor] keep screen on failed: ${(error as BusinessError).code}`);
    }
  }
}

export const watchMonitor: WatchMonitor = new WatchMonitor();
