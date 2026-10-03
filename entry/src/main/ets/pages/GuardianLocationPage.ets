import { common } from '@kit.AbilityKit';
import { CareButtonStyle } from '../components/DesignSystem';
import { IconBadge, NoticeBanner } from '../components/Common';
import { MapMarker, MapScene, SeniorMap, markerIcon, markerLabel } from '../components/SeniorMap';
import {
  DeviceReport,
  Freshness,
  PHONE,
  SeniorSnapshot,
  WATCH,
  ageHeadline,
  deviceAgeText,
  deviceClockTime,
  deviceIsStale,
  deviceName,
  distanceMeters,
  formatDistance,
  freshnessOf,
  hasAnyLocation,
  stateSentence
} from '../models/SeniorLocation';
import { formatClockTime } from '../models/Safety';
import { MapsHandOff, openInMaps } from '../platform/MapsLauncher';
import { apiSession } from '../services/CareApi';
import { seniorStatusApi } from '../services/SeniorStatusApi';

/** Light polling while the tab is visible; the senior's phone and watch report on their own schedules. */
const POLL_INTERVAL_MS: number = 30000;
const EMPTY_SNAPSHOT: SeniorSnapshot = new SeniorSnapshot();
const EMPTY_DEVICE: DeviceReport = new DeviceReport();

/**
 * Guardian Location tab: the last reported positions of the senior's phone and
 * watch from `GET /seniors/:id/status`, drawn on one map with the safe area,
 * plus how old each one is. It shows past reports, never live tracking, and
 * never says "safe".
 */
@Component
export struct GuardianLocationView {
  /** Bumped by the host whenever the tab or page becomes visible. */
  @Prop @Watch('onRefreshKey') refreshKey: number = 0;
  /** Polls only while the Location tab is the selected tab. */
  @Prop @Watch('onVisibility') visible: boolean = false;
  @State private snapshot: SeniorSnapshot | undefined = undefined;
  @State private scene: MapScene = new MapScene();
  @State private loading: boolean = false;
  @State private loadError: string = '';
  @State private now: number = Date.now();
  @State private lastCheckedAt: number = 0;
  private pollTimer: number = -1;

  aboutToAppear(): void {
    this.reload();
    this.updatePolling();
  }

  aboutToDisappear(): void {
    this.stopPolling();
  }

  private onRefreshKey(): void {
    if (this.visible) {
      this.reload();
    }
  }

  private onVisibility(): void {
    this.updatePolling();
    if (this.visible) {
      this.reload();
    }
  }

  private updatePolling(): void {
    if (this.visible && this.pollTimer === -1) {
      this.pollTimer = setInterval(() => this.reload(), POLL_INTERVAL_MS);
    } else if (!this.visible) {
      this.stopPolling();
    }
  }

  private stopPolling(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  /**
   * Builders read the snapshot through this accessor instead of taking it as a
   * parameter, because @Builder arguments are passed by value and would not
   * update after a refresh.
   */
  private current(): SeniorSnapshot {
    return this.snapshot ?? EMPTY_SNAPSHOT;
  }

  private pairedAsGuardian(): boolean {
    return apiSession.configured() && apiSession.role === 'guardian';
  }

  private async reload(): Promise<void> {
    this.now = Date.now();
    if (!this.pairedAsGuardian()) {
      this.snapshot = undefined;
      this.loadError = 'This phone is not paired as a guardian.';
      return;
    }
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      const snapshot = await seniorStatusApi.load();
      this.now = Date.now();
      this.lastCheckedAt = this.now;
      this.snapshot = snapshot;
      this.scene = this.sceneFor(snapshot);
      this.loadError = '';
    } catch (error) {
      this.loadError = this.snapshot === undefined
        ? 'Could not reach the care service. Check the connection and try again.'
        : 'Could not refresh. Showing the last location loaded on this phone.';
    } finally {
      this.loading = false;
    }
  }

  /** The report of one device, or an empty one when that device never reported. */
  private device(kind: string): DeviceReport {
    const snapshot = this.current();
    return (kind === WATCH ? snapshot.watch : snapshot.phone) ?? EMPTY_DEVICE;
  }

  private hasDevice(kind: string): boolean {
    const snapshot = this.current();
    return (kind === WATCH ? snapshot.watch : snapshot.phone) !== undefined;
  }

  private sceneFor(snapshot: SeniorSnapshot): MapScene {
    const scene = new MapScene();
    const reports: (DeviceReport | undefined)[] = [snapshot.phone, snapshot.watch];
    reports.forEach((report: DeviceReport | undefined) => {
      if (report !== undefined && report.hasLocation) {
        const marker = new MapMarker();
        marker.kind = report.kind;
        marker.lat = report.lat;
        marker.lng = report.lng;
        marker.accuracyM = report.accuracyM;
        marker.stale = deviceIsStale(report, snapshot, this.now);
        scene.markers.push(marker);
      }
    });
    scene.hasArea = snapshot.hasSafeArea;
    scene.areaLat = snapshot.areaLat;
    scene.areaLng = snapshot.areaLng;
    scene.areaRadiusM = snapshot.areaRadiusM;
    return scene;
  }

  private async openMap(kind: string): Promise<void> {
    const report = this.device(kind);
    const handOff = await openInMaps(this.getUIContext().getHostContext() as common.UIAbilityContext,
      report.lat, report.lng, `${this.current().seniorName}'s ${deviceName(kind)}, last known location`);
    if (handOff === MapsHandOff.None) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: 'No maps app or browser could open this location' });
      } catch (toastError) {
        console.error('[GuardianLocation] toast failed');
      }
    }
  }

  private heroAccent(snapshot: SeniorSnapshot): Resource {
    const freshness = freshnessOf(snapshot, this.now);
    if (freshness === Freshness.Stale) {
      return $r('app.color.warning');
    }
    return snapshot.monitoringState === 'outside' ? $r('app.color.sos') : $r('app.color.guardian_accent');
  }

  private heroTint(snapshot: SeniorSnapshot): Resource {
    const freshness = freshnessOf(snapshot, this.now);
    if (freshness === Freshness.Stale) {
      return $r('app.color.warning_tint');
    }
    return snapshot.monitoringState === 'outside' ? $r('app.color.sos_tint') : $r('app.color.guardian_tint');
  }

  private heroIcon(snapshot: SeniorSnapshot): Resource {
    if (freshnessOf(snapshot, this.now) === Freshness.Stale) {
      return $r('sys.symbol.exclamationmark_triangle_fill');
    }
    return snapshot.monitoringState === 'outside' ? $r('sys.symbol.figure_walk') : $r('sys.symbol.clock_fill');
  }

  private accuracyText(report: DeviceReport): string {
    if (!report.hasLocation) {
      return 'No position in last update';
    }
    return report.accuracyM >= 0 ? `Within about ${formatDistance(report.accuracyM)}` : 'Not reported';
  }

  private distanceText(report: DeviceReport): string {
    const snapshot = this.current();
    if (!snapshot.hasSafeArea || !report.hasLocation) {
      return 'Unknown';
    }
    return `About ${formatDistance(distanceMeters(snapshot.areaLat, snapshot.areaLng, report.lat, report.lng))}`;
  }

  private safeAreaText(snapshot: SeniorSnapshot): string {
    if (snapshot.hasSafeArea) {
      return `${formatDistance(snapshot.areaRadiusM)} around home`;
    }
    return snapshot.safeAreaKnown ? 'Not set up' : 'Could not load';
  }

  private batteryText(report: DeviceReport): string {
    return report.battery >= 0 ? `${report.battery}%` : 'Not reported';
  }

  @Builder
  hero() {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        IconBadge({
          icon: this.heroIcon(this.current()),
          accent: this.heroAccent(this.current()),
          tint: $r('app.color.surface'),
          badgeSize: 48
        })
        Text(this.current().seniorName)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      Text(ageHeadline(this.current(), this.now))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(stateSentence(this.current(), this.now))
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .opacity(0.85)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(24)
    .backgroundColor(this.heroTint(this.current()))
    .accessibilityGroup(true)
  }

  @Builder
  deviceCard(kind: string) {
    DeviceLocationCard({
      kind: kind,
      ageText: deviceAgeText(this.device(kind), this.current(), this.now),
      stale: deviceIsStale(this.device(kind), this.current(), this.now),
      simulated: this.device(kind).simulated,
      hasLocation: this.device(kind).hasLocation,
      lastUpdate: deviceClockTime(this.device(kind), this.current(), this.now),
      accuracy: this.accuracyText(this.device(kind)),
      distance: this.distanceText(this.device(kind)),
      battery: this.batteryText(this.device(kind)),
      onOpenMap: () => this.openMap(kind)
    })
  }

  @Builder
  details() {
    Column({ space: 16 }) {
      if (this.hasDevice(PHONE)) {
        this.deviceCard(PHONE)
      }
      if (this.hasDevice(WATCH)) {
        this.deviceCard(WATCH)
      }
      Column() {
        LocationInfoRow({ label: 'Safe area', value: this.safeAreaText(this.current()), showDivider: false })
      }
      .width('100%')
      .borderRadius(20)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
  }

  @Builder
  noReportYet() {
    Column({ space: 12 }) {
      IconBadge({
        icon: $r('sys.symbol.location_up_fill'),
        accent: $r('app.color.guardian_accent'),
        tint: $r('app.color.guardian_tint'),
        badgeSize: 80
      })
      Text('No location yet')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(`Neither ${this.current().seniorName}'s phone nor watch has shared an update. The phone shares after location sharing is turned on in Safe Area; the watch shares while Carely is open on it.`)
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 32, bottom: 16, left: 16, right: 16 })
  }

  @Builder
  actions() {
    Column({ space: 12 }) {
      Button() {
        Row({ space: 8 }) {
          if (this.loading) {
            LoadingProgress()
              .width(22)
              .height(22)
              .color(Color.White)
          } else {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontSize(20)
              .fontColor([Color.White])
          }
          Text(this.loading ? 'Checking…' : 'Refresh')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(56)
      .attributeModifier(new CareButtonStyle())
      .enabled(!this.loading)
      .onClick(() => this.reload())
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loadError !== '') {
          NoticeBanner({ text: this.loadError })
        }

        if (this.snapshot === undefined) {
          if (this.loading) {
            Column({ space: 12 }) {
              LoadingProgress()
                .width(40)
                .height(40)
                .color($r('app.color.guardian_accent'))
              Text('Loading the last known location…')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding({ top: 64, bottom: 32 })
          }
        } else if (!this.snapshot.hasStatus) {
          this.noReportYet()
          if (this.snapshot.hasSafeArea) {
            SeniorMap({ scene: this.scene })
          }
        } else {
          this.hero()
          if (!hasAnyLocation(this.snapshot)) {
            NoticeBanner({
              icon: $r('sys.symbol.questionmark_circle_fill'),
              text: 'The last updates did not include a position.'
            })
          }
          if (hasAnyLocation(this.snapshot) || this.snapshot.hasSafeArea) {
            SeniorMap({ scene: this.scene })
          }
          this.details()
        }

        if (this.pairedAsGuardian()) {
          this.actions()
        }

        Text(this.footerText())
          .fontSize(17)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  private footerText(): string {
    const base = 'Shared by the senior\'s phone while location sharing is on, and by the watch while Carely is open on it. These are the last reports, not live tracking.';
    return this.lastCheckedAt > 0 ? `${base} Checked at ${formatClockTime(this.lastCheckedAt)}.` : base;
  }
}

/** A component rather than a @Builder so its value updates after each refresh. */
@Component
struct LocationInfoRow {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop showDivider: boolean = false;

  build() {
    Column() {
      Row({ space: 16 }) {
        Text(this.label)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
        Text(this.value)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (this.showDivider) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 16, right: 16 })
      }
    }
    .accessibilityGroup(true)
  }
}

/** One device's last report, with the same icon as its map marker. A component so it updates after each refresh. */
@Component
struct DeviceLocationCard {
  @Prop kind: string = PHONE;
  @Prop ageText: string = '';
  @Prop stale: boolean = false;
  @Prop simulated: boolean = false;
  @Prop hasLocation: boolean = false;
  @Prop lastUpdate: string = '';
  @Prop accuracy: string = '';
  @Prop distance: string = '';
  @Prop battery: string = '';
  onOpenMap: () => void = () => {};

  build() {
    Column() {
      Row({ space: 12 }) {
        Row() {
          SymbolGlyph(markerIcon(this.kind))
            .fontSize(22)
            .fontColor([Color.White])
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.stale ? $r('app.color.action_danger') : $r('app.color.action_primary'))

        Column({ space: 2 }) {
          Text(markerLabel(this.kind))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(this.ageText)
            .fontSize(15)
            .fontColor(this.stale ? $r('app.color.warning') : $r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.simulated) {
          Text('Simulated')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.warning'))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor($r('app.color.warning_tint'))
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 6 })
      .accessibilityGroup(true)

      LocationInfoRow({ label: 'Last update', value: this.lastUpdate, showDivider: true })
      LocationInfoRow({ label: 'Accuracy', value: this.accuracy, showDivider: true })
      LocationInfoRow({ label: 'From home centre', value: this.distance, showDivider: true })
      LocationInfoRow({ label: 'Battery', value: this.battery, showDivider: this.hasLocation })

      if (this.hasLocation) {
        Column() {
          Button() {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.map'))
                .fontSize(20)
                .fontColor([$r('app.color.guardian_accent')])
              Text('Open in Maps')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.guardian_accent'))
            }
          }
          .width('100%')
          .height(56)
          .attributeModifier(new CareButtonStyle('secondary'))
          .accessibilityText(`Open the ${markerLabel(this.kind).toLowerCase()}'s last known location in Maps`)
          .onClick(() => this.onOpenMap())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })
      }
    }
    .width('100%')
    .padding({ bottom: 16 })
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
  }
}
