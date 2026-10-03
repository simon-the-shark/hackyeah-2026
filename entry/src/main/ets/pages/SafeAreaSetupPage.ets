import { LengthMetrics } from '@kit.ArkUI';
import { AreaPickerMap } from '../components/AreaPickerMap';
import { IconBadge, NoticeBanner, sectionTitle } from '../components/Common';
import { safetyStore } from '../models/Safety';
import { apiSession, careApi } from '../services/CareApi';
import { http } from '@kit.NetworkKit';

const RADIUS_OPTIONS: number[] = [100, 200, 300, 500, 1000];
/** Six decimals is about 10 cm, finer than any phone fix. */
const COORDINATE_DECIMALS: number = 6;

@Component
export struct SafeAreaSetupPage {
  @Consume('navStack') navStack: NavPathStack;
  @State private latitude: string = `${safetyStore.homeLatitude}`;
  @State private longitude: string = `${safetyStore.homeLongitude}`;
  /** Last valid centre, shown on the map while a typed coordinate is incomplete. */
  @State private mapLatitude: number = safetyStore.homeLatitude;
  @State private mapLongitude: number = safetyStore.homeLongitude;
  @State private radius: number = safetyStore.homeRadiusMeters;
  @State private showErrors: boolean = false;
  @State private safeAreaVersion: number = 0;

  aboutToAppear(): void {
    if (apiSession.configured() && apiSession.role === 'guardian') {
      this.loadExistingSafeArea();
    }
  }

  private async loadExistingSafeArea(): Promise<void> {
    try {
      const result = await careApi.request(`/seniors/${apiSession.seniorId}/safe-area`, http.RequestMethod.GET) as Record<string, Object>;
      this.latitude = `${result['lat'] as number}`;
      this.longitude = `${result['lng'] as number}`;
      this.mapLatitude = result['lat'] as number;
      this.mapLongitude = result['lng'] as number;
      this.radius = result['radiusM'] as number;
      this.safeAreaVersion = result['version'] as number;
    } catch (error) {
      // A 404 means the guardian is configuring the safe area for the first time.
      this.safeAreaVersion = 0;
    }
  }

  private latitudeValid(): boolean {
    const value = Number(this.latitude);
    return this.latitude.trim() !== '' && isFinite(value) && value >= -90 && value <= 90;
  }

  private longitudeValid(): boolean {
    const value = Number(this.longitude);
    return this.longitude.trim() !== '' && isFinite(value) && value >= -180 && value <= 180;
  }

  private pickOnMap(lat: number, lng: number): void {
    this.mapLatitude = lat;
    this.mapLongitude = lng;
    this.latitude = lat.toFixed(COORDINATE_DECIMALS);
    this.longitude = lng.toFixed(COORDINATE_DECIMALS);
  }

  private async save(): Promise<void> {
    if (!this.latitudeValid() || !this.longitudeValid()) {
      this.showErrors = true;
      return;
    }
    if (apiSession.configured() && apiSession.role === 'guardian') {
      try {
        const result = await careApi.request(`/seniors/${apiSession.seniorId}/safe-area`, http.RequestMethod.PUT,
          new SafeAreaRequest(Number(this.latitude), Number(this.longitude), this.radius, this.safeAreaVersion)) as Record<string, Object>;
        this.safeAreaVersion = result['version'] as number;
      } catch (error) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: 'Could not save safe area' });
        } catch (toastError) {
          console.error(`Safe area toast failed: ${JSON.stringify(toastError)}`);
        }
        return;
      }
      safetyStore.configureHomeCircle(Number(this.latitude), Number(this.longitude), this.radius);
      try {
        this.getUIContext().getPromptAction().showToast({ message: 'Safe area saved' });
      } catch (error) {
        console.error(`Safe area toast failed: ${JSON.stringify(error)}`);
      }
      this.navStack.pop();
    }
  }

  private radiusLabel(meters: number): string {
    return meters >= 1000 ? `${meters / 1000} km` : `${meters} m`;
  }

  @Builder
  coordinateField(isLatitude: boolean) {
    Column({ space: 6 }) {
      Text(isLatitude ? 'Latitude' : 'Longitude')
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
      TextInput({
        text: isLatitude ? this.latitude : this.longitude,
        placeholder: isLatitude ? 'e.g. 52.2297' : 'e.g. 21.0122'
      })
        .width('100%')
        .height(52)
        .fontSize(18)
        .backgroundColor($r('app.color.page_background'))
        .border({
          width: this.showErrors && !(isLatitude ? this.latitudeValid() : this.longitudeValid()) ? 2 : 0,
          color: $r('app.color.sos')
        })
        .onChange((value: string) => {
          if (isLatitude) {
            this.latitude = value;
            if (this.latitudeValid()) {
              this.mapLatitude = Number(value);
            }
          } else {
            this.longitude = value;
            if (this.longitudeValid()) {
              this.mapLongitude = Number(value);
            }
          }
        })
      if (this.showErrors && !(isLatitude ? this.latitudeValid() : this.longitudeValid())) {
        Text(isLatitude ? 'Enter a number between -90 and 90.' : 'Enter a number between -180 and 180.')
          .fontSize(14)
          .fontColor($r('app.color.sos'))
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  radiusChip(meters: number) {
    Text(this.radiusLabel(meters))
      .fontSize(17)
      .fontWeight(this.radius === meters ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.radius === meters ? Color.White : $r('app.color.text_primary'))
      .height(48)
      .padding({ left: 18, right: 18 })
      .borderRadius(24)
      .backgroundColor(this.radius === meters ? $r('app.color.guardian_accent') : $r('app.color.page_background'))
      .accessibilityText(`Radius ${this.radiusLabel(meters)}`)
      .accessibilitySelected(this.radius === meters)
      .onClick(() => {
        this.radius = meters;
      })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Row({ space: 16 }) {
            IconBadge({
              icon: $r('sys.symbol.house_shield_fill'),
              accent: $r('app.color.guardian_accent'),
              tint: $r('app.color.guardian_tint'),
              badgeSize: 56
            })
            Text('You will be alerted when your senior leaves this area.')
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')

          Column({ space: 8 }) {
            sectionTitle('Home location')
            Column({ space: 12 }) {
              AreaPickerMap({
                lat: this.mapLatitude,
                lng: this.mapLongitude,
                radiusM: this.radius,
                onPick: (lat: number, lng: number) => this.pickOnMap(lat, lng)
              })
              Text('Drag the map or tap a spot to put home under the pin.')
                .fontSize(15)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
              Row({ space: 12 }) {
                this.coordinateField(true)
                this.coordinateField(false)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }
            .width('100%')
            .padding(16)
            .borderRadius(20)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            sectionTitle('Radius around home')
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
              ForEach(RADIUS_OPTIONS, (meters: number) => {
                this.radiusChip(meters)
              }, (meters: number) => `${meters}`)
            }
            .width('100%')
            .padding(16)
            .borderRadius(20)
            .backgroundColor($r('app.color.surface'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          NoticeBanner({ text: 'Saved on the care service. The senior phone still needs location sharing while the app is open.' })

          Button('Save safe area')
            .width('100%')
            .height(56)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.guardian_accent'))
            .onClick(() => this.save())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .title('Safe Area')
    .backgroundColor($r('app.color.page_background'))
  }
}

class SafeAreaRequest {
  lat: number;
  lng: number;
  radiusM: number;
  version?: number;

  constructor(lat: number, lng: number, radiusM: number, version: number) {
    this.lat = lat;
    this.lng = lng;
    this.radiusM = radiusM;
    if (version > 0) this.version = version;
  }
}
