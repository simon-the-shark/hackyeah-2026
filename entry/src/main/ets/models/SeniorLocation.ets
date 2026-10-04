import { formatClockTime } from './Safety';

/** Heartbeats younger than this are shown as recent. The senior app reports on location changes. */
export const AGING_AFTER_MS: number = 5 * 60 * 1000;
/** Matches the backend's default `HEARTBEAT_STALE_SECONDS` (900 s); the app cannot read the server value. */
export const STALE_AFTER_MS: number = 15 * 60 * 1000;

export enum Freshness {
  Recent,
  Aging,
  Stale
}

/** The care service's `location` on a heartbeat. Optional fields can arrive as absent or null. */
export interface HeartbeatPoint {
  lat: number;
  lng: number;
  accuracyM?: number | null;
  measuredBy?: string | null;
  sampledAt?: string | null;
}

/** One device's latest heartbeat from `GET /seniors/:id/status`. */
export interface RemoteHeartbeat {
  monitoringState: string;
  location?: HeartbeatPoint | null;
  battery?: number | null;
  reportedAt: string;
  staleAlertedAt?: string | null;
  deviceKind?: string;
  source?: string;
}

export interface RemoteStatusResponse {
  /** The newest heartbeat of any device; read only from a backend that does not send `devices`. */
  status: RemoteHeartbeat | null;
  /** Latest heartbeat per device, newest first. */
  devices?: RemoteHeartbeat[];
  serverTime: string;
}

export const PHONE: string = 'phone';
export const WATCH: string = 'watch';

/** One device's last report. A phone and a watch are never mixed: each keeps its own position. */
export class DeviceReport {
  /** `PHONE` or `WATCH`. */
  kind: string = PHONE;
  monitoringState: string = 'unknown';
  hasLocation: boolean = false;
  lat: number = 0;
  lng: number = 0;
  /** Negative when the device did not report accuracy. */
  accuracyM: number = -1;
  /** Negative when the device did not report a battery level. */
  battery: number = -1;
  /** Age of the heartbeat when it was fetched, on the server clock. */
  reportedAgeMs: number = 0;
  /** Original fix time on the measuring device, distinct from server heartbeat receipt. */
  sampledAt: string = '';
  /** Sent by a trace replay or an emulator, not measured by a real device. */
  simulated: boolean = false;
}

/**
 * What the guardian knows about the senior's last reports. Ages are measured on
 * the server clock (`serverTime - reportedAt`) so a wrong clock on either phone
 * cannot make an old position look fresh. The headline fields describe the
 * newest report from either device.
 */
export class SeniorSnapshot {
  seniorName: string = 'Your senior';
  hasStatus: boolean = false;
  /** Kind of the device that sent the newest report. */
  latestKind: string = PHONE;
  monitoringState: string = 'unknown';
  /** Age of the newest heartbeat when it was fetched, on the server clock. */
  reportedAgeMs: number = 0;
  /** Local clock time of the fetch, used to keep the age ticking between refreshes. */
  fetchedAt: number = 0;
  /** The server already raised a `monitoring_lost` alert for the current gap. */
  monitoringLostRaised: boolean = false;
  phone: DeviceReport | undefined = undefined;
  watch: DeviceReport | undefined = undefined;
  hasSafeArea: boolean = false;
  /** False when the safe area could not be loaded for a reason other than "not set up". */
  safeAreaKnown: boolean = true;
  areaLat: number = 0;
  areaLng: number = 0;
  areaRadiusM: number = 0;
}

function isNumber(value: number | null | undefined): boolean {
  return typeof value === 'number' && isFinite(value);
}

function ageOnServerClock(serverTime: string, reportedAt: string): number {
  const serverNow = Date.parse(serverTime);
  const reported = Date.parse(reportedAt);
  return isFinite(serverNow) && isFinite(reported) ? Math.max(0, serverNow - reported) : 0;
}

function deviceReport(heartbeat: RemoteHeartbeat | null | undefined, kind: string,
  serverTime: string): DeviceReport | undefined {
  if (heartbeat === null || heartbeat === undefined) {
    return undefined;
  }
  const report = new DeviceReport();
  report.kind = kind;
  report.monitoringState = heartbeat.monitoringState;
  report.reportedAgeMs = ageOnServerClock(serverTime, heartbeat.reportedAt);
  report.simulated = heartbeat.source !== undefined && heartbeat.source !== 'device';
  const battery = heartbeat.battery;
  if (battery !== null && battery !== undefined && isNumber(battery)) {
    report.battery = battery;
  }
  const location = heartbeat.location;
  // A phone fix relayed by the watch is the phone's position, not the watch's.
  const relayed = kind === WATCH && location !== null && location !== undefined && location.measuredBy === PHONE;
  if (location !== null && location !== undefined && !relayed && isNumber(location.lat) && isNumber(location.lng)) {
    report.hasLocation = true;
    report.lat = location.lat;
    report.lng = location.lng;
    if (typeof location.sampledAt === 'string' && isFinite(Date.parse(location.sampledAt))) {
      report.sampledAt = location.sampledAt;
    }
    const accuracy = location.accuracyM;
    if (accuracy !== null && accuracy !== undefined && isNumber(accuracy)) {
      report.accuracyM = accuracy;
    }
  }
  return report;
}

/** Splits the status response into the phone's and the watch's reports; the newest one fills the headline. */
export function snapshotFromStatus(response: RemoteStatusResponse, fetchedAt: number): SeniorSnapshot {
  const snapshot = new SeniorSnapshot();
  snapshot.fetchedAt = fetchedAt;
  const devices = response.devices;
  let newest: RemoteHeartbeat | null | undefined = undefined;
  if (devices !== undefined) {
    snapshot.phone = deviceReport(devices.find((device: RemoteHeartbeat) => device.deviceKind === PHONE), PHONE,
      response.serverTime);
    snapshot.watch = deviceReport(devices.find((device: RemoteHeartbeat) => device.deviceKind === WATCH), WATCH,
      response.serverTime);
    newest = devices.find((device: RemoteHeartbeat) => device.deviceKind === PHONE || device.deviceKind === WATCH);
  } else {
    // A backend without `devices` only knows the phone.
    snapshot.phone = deviceReport(response.status, PHONE, response.serverTime);
    newest = response.status;
  }
  if (newest !== null && newest !== undefined) {
    snapshot.hasStatus = true;
    snapshot.latestKind = newest.deviceKind === WATCH ? WATCH : PHONE;
    snapshot.monitoringState = newest.monitoringState;
    snapshot.reportedAgeMs = ageOnServerClock(response.serverTime, newest.reportedAt);
    snapshot.monitoringLostRaised = newest.staleAlertedAt !== null && newest.staleAlertedAt !== undefined;
  }
  return snapshot;
}

export function deviceName(kind: string): string {
  return kind === WATCH ? 'watch' : 'phone';
}

export function hasAnyLocation(snapshot: SeniorSnapshot): boolean {
  return (snapshot.phone?.hasLocation ?? false) || (snapshot.watch?.hasLocation ?? false);
}

export function currentAgeMs(snapshot: SeniorSnapshot, now: number): number {
  return Math.max(0, snapshot.reportedAgeMs + (now - snapshot.fetchedAt));
}

export function freshnessOf(snapshot: SeniorSnapshot, now: number): Freshness {
  const age = currentAgeMs(snapshot, now);
  if (snapshot.monitoringLostRaised || age >= STALE_AFTER_MS) {
    return Freshness.Stale;
  }
  return age >= AGING_AFTER_MS ? Freshness.Aging : Freshness.Recent;
}

export function deviceAgeMs(device: DeviceReport, snapshot: SeniorSnapshot, now: number): number {
  return Math.max(0, device.reportedAgeMs + (now - snapshot.fetchedAt));
}

export function deviceIsStale(device: DeviceReport, snapshot: SeniorSnapshot, now: number): boolean {
  return deviceAgeMs(device, snapshot, now) >= STALE_AFTER_MS;
}

function ageText(ageMs: number, stale: boolean): string {
  if (stale) {
    return `No update for ${formatDuration(ageMs)}`;
  }
  return ageMs < 60000 ? 'Updated just now' : `Updated ${formatDuration(ageMs)} ago`;
}

/** "Updated 3 min ago" for one device. */
export function deviceAgeText(device: DeviceReport, snapshot: SeniorSnapshot, now: number): string {
  return ageText(deviceAgeMs(device, snapshot, now), deviceIsStale(device, snapshot, now));
}

export function deviceClockTime(device: DeviceReport, snapshot: SeniorSnapshot, now: number): string {
  return formatClockTime(now - deviceAgeMs(device, snapshot, now));
}

export function formatDuration(ms: number): string {
  const minutes = Math.floor(ms / 60000);
  if (minutes < 1) {
    return 'less than a minute';
  }
  if (minutes < 60) {
    return `${minutes} min`;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    const rest = minutes % 60;
    return rest === 0 ? `${hours} h` : `${hours} h ${rest} min`;
  }
  const days = Math.floor(hours / 24);
  return days === 1 ? '1 day' : `${days} days`;
}

/** "Updated 3 min ago" style headline for the newest report; never claims the senior is safe. */
export function ageHeadline(snapshot: SeniorSnapshot, now: number): string {
  return ageText(currentAgeMs(snapshot, now), freshnessOf(snapshot, now) === Freshness.Stale);
}

/** Describes the monitoring state as a past observation, qualified by its age. */
export function stateSentence(snapshot: SeniorSnapshot, now: number): string {
  const stale = freshnessOf(snapshot, now) === Freshness.Stale;
  const device = deviceName(snapshot.latestKind);
  let sentence: string;
  if (snapshot.monitoringState === 'inside') {
    sentence = `Was inside the safe area at the last update from the ${device}.`;
  } else if (snapshot.monitoringState === 'outside') {
    sentence = `Was outside the safe area at the last update from the ${device}.`;
  } else if (snapshot.monitoringState === 'unavailable') {
    sentence = `Location was unavailable on the senior's ${device} at the last update.`;
  } else {
    sentence = `Safe-area status was unknown at the last update from the ${device}.`;
  }
  if (stale) {
    sentence += ' This may be out of date. Consider calling to check in.';
  }
  return sentence;
}

export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.round(meters / 10) * 10} m`;
  }
  return `${(meters / 1000).toFixed(meters < 10000 ? 1 : 0)} km`;
}
