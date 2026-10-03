import { common } from '@kit.AbilityKit';
import { mapCommon, petalMaps } from '@kit.MapKit';
import { IconBadge, NoticeBanner } from '../components/Common';
import { MapScene, SeniorMap } from '../components/SeniorMap';
import {
  Freshness,
  SeniorSnapshot,
  ageHeadline,
  distanceMeters,
  formatDistance,
  freshnessOf,
  reportClockTime,
  stateSentence
} from '../models/SeniorLocation';
import { formatClockTime } from '../models/Safety';
import { apiSession } from '../services/CareApi';
import { seniorStatusApi } from '../services/SeniorStatusApi';

/** Light polling while the tab is visible; the senior phone reports on location changes. */
const POLL_INTERVAL_MS: number = 30000;
const EMPTY_SNAPSHOT: SeniorSnapshot = new SeniorSnapshot();

/**
 * Guardian Location tab: the senior's last reported position from
 * `GET /seniors/:id/status`, drawn with the safe area, plus how old it is.
 * It shows a past report, never live tracking, and never says "safe".
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

  private sceneFor(snapshot: SeniorSnapshot): MapScene {
    const scene = new MapScene();
    scene.hasMarker = snapshot.hasLocation;
    scene.markerLat = snapshot.lat;
    scene.markerLng = snapshot.lng;
    scene.accuracyM = snapshot.accuracyM;
    scene.hasArea = snapshot.hasSafeArea;
    scene.areaLat = snapshot.areaLat;
    scene.areaLng = snapshot.areaLng;
    scene.areaRadiusM = snapshot.areaRadiusM;
    scene.stale = freshnessOf(snapshot, this.now) === Freshness.Stale;
    return scene;
  }

  private async openInPetalMaps(snapshot: SeniorSnapshot): Promise<void> {
    const position: mapCommon.LatLng = { latitude: snapshot.lat, longitude: snapshot.lng };
    const params: petalMaps.PoiDetailParams = {
      destinationPosition: position,
      destinationName: `${snapshot.seniorName}, last known location`
    };
    try {
      await petalMaps.openMapPoiDetail(this.getUIContext().getHostContext() as common.Context, params);
    } catch (error) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: 'Petal Maps is not available on this device' });
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

  private accuracyText(snapshot: SeniorSnapshot): string {
    if (!snapshot.hasLocation) {
      return 'No position in last update';
    }
    return snapshot.accuracyM >= 0 ? `Within about ${formatDistance(snapshot.accuracyM)}` : 'Not reported';
  }

  private distanceText(snapshot: SeniorSnapshot): string {
    if (!snapshot.hasSafeArea || !snapshot.hasLocation) {
      return 'Unknown';
    }
    return `About ${formatDistance(distanceMeters(snapshot.areaLat, snapshot.areaLng, snapshot.lat, snapshot.lng))}`;
  }

  private safeAreaText(snapshot: SeniorSnapshot): string {
    if (snapshot.hasSafeArea) {
      return `${formatDistance(snapshot.areaRadiusM)} around home`;
    }
    return snapshot.safeAreaKnown ? 'Not set up' : 'Could not load';
  }

  private batteryText(snapshot: SeniorSnapshot): string {
    return snapshot.battery >= 0 ? `${snapshot.battery}%` : 'Not reported';
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
  details() {
    Column() {
      LocationInfoRow({ label: 'Last update', value: reportClockTime(this.current(), this.now), showDivider: true })
      LocationInfoRow({ label: 'Accuracy', value: this.accuracyText(this.current()), showDivider: true })
      LocationInfoRow({ label: 'From home centre', value: this.distanceText(this.current()), showDivider: true })
      LocationInfoRow({ label: 'Safe area', value: this.safeAreaText(this.current()), showDivider: true })
      LocationInfoRow({ label: 'Phone battery', value: this.batteryText(this.current()), showDivider: false })
    }
    .width('100%')
    .borderRadius(20)
    .backgroundColor($r('app.color.surface'))
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
      Text(`${this.current().seniorName}'s phone has not shared an update. It appears after location sharing is turned on in Safe Area on the senior's phone.`)
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
      .backgroundColor($r('app.color.guardian_accent'))
      .enabled(!this.loading)
      .onClick(() => this.reload())

      if (this.snapshot !== undefined && this.snapshot.hasLocation) {
        Button() {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.map'))
              .fontSize(20)
              .fontColor([$r('app.color.guardian_accent')])
            Text('Open in Petal Maps')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.guardian_accent'))
          }
        }
        .width('100%')
        .height(56)
        .backgroundColor($r('app.color.surface'))
        .onClick(() => this.openInPetalMaps(this.current()))
      }
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
          if (!this.snapshot.hasLocation) {
            NoticeBanner({
              icon: $r('sys.symbol.questionmark_circle_fill'),
              text: 'The last update did not include a position.'
            })
          }
          if (this.snapshot.hasLocation || this.snapshot.hasSafeArea) {
            SeniorMap({ scene: this.scene })
          }
          this.details()
        }

        if (this.pairedAsGuardian()) {
          this.actions()
        }

        Text(this.footerText())
          .fontSize(13)
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
    const base = 'Shared by the senior\'s phone while location sharing is on in Carely. This is the last report, not live tracking.';
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
