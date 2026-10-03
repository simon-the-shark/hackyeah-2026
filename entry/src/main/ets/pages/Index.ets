import { common } from '@kit.AbilityKit';
import { Feature, GUARDIAN_PROFILE, ROLE_PROFILES, RoleProfile, SENIOR_PROFILE } from '../models/Features';
import { CareAlert } from '../models/Safety';
import { ConnectionPage } from './ConnectionPage';
import { AlertDetailPage, AlertsPage } from './AlertsPage';
import { DeveloperToolsPage } from './DeveloperToolsPage';
import { loadTakenDoses } from '../platform/DoseLogStore';
import { dateKey } from '../services/MedicationSchedule';
import { FeaturePage } from './FeaturePage';
import { MedicationDetail, MedicationDetailParams } from './MedicationDetail';
import { RoleHome } from './RoleHome';
import { SafeAreaSetupPage } from './SafeAreaSetupPage';
import { SafetyPage } from './SafetyPage';
import { SettingsPage } from './SettingsPage';
import { SosPage } from './SosPage';
import { WatchSafetyPage } from './WatchSafetyPage';

@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack();
  @StorageLink('paired') private paired: boolean = false;
  // Today's taken doses (occurrence ID to time taken), shared by the schedule and detail screens.
  @Provide('takenDoses') takenDoses: Map<string, number> = new Map<string, number>();

  aboutToAppear(): void {
    this.takenDoses = loadTakenDoses(this.getUIContext().getHostContext() as common.Context, dateKey(new Date()));
  }

  @Builder
  routes(name: string, param: Object) {
    if (name === SENIOR_PROFILE.route) {
      RoleHome({ profile: SENIOR_PROFILE })
    } else if (name === GUARDIAN_PROFILE.route) {
      RoleHome({ profile: GUARDIAN_PROFILE })
    } else if (name === 'feature') {
      FeaturePage({ feature: param as Feature })
    } else if (name === 'sos') {
      SosPage()
    } else if (name === 'safety') {
      SafetyPage()
    } else if (name === 'alerts') {
      AlertsPage()
    } else if (name === 'alert-detail') {
      AlertDetailPage({ alert: param as CareAlert })
    } else if (name === 'watch-safety') {
      WatchSafetyPage()
    } else if (name === 'safe-area-setup') {
      SafeAreaSetupPage()
    } else if (name === 'settings') {
      SettingsPage()
    } else if (name === 'developer-tools') {
      DeveloperToolsPage()
    } else if (name === 'connection') {
      ConnectionPage({ onConnected: (role: string) => {
        this.paired = true;
        this.navStack.pop();
        this.navStack.pushPathByName(role === 'guardian' ? GUARDIAN_PROFILE.route : SENIOR_PROFILE.route, null);
      } })
    } else if (name === 'medication-detail') {
      MedicationDetail({ params: param as MedicationDetailParams })
    }
  }

  @Builder
  roleCard(profile: RoleProfile) {
    Row({ space: 16 }) {
      Row() {
        SymbolGlyph(profile.icon)
          .fontSize(30)
          .fontColor([profile.accent])
      }
      .width(60)
      .height(60)
      .borderRadius(18)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(profile.tint)

      Column({ space: 4 }) {
        Text(profile.label)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(profile.description)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor($r('app.color.surface'))
    .shadow({ radius: 16, color: $r('app.color.card_shadow'), offsetY: 4 })
    .accessibilityGroup(true)
    .onClick(() => {
      this.navStack.pushPathByName(profile.route, null);
    })
  }

  build() {
    Navigation(this.navStack) {
      Column({ space: 32 }) {
        Column({ space: 8 }) {
          Row() {
            SymbolGlyph($r('sys.symbol.heart_fill'))
              .fontSize(36)
              .fontColor([$r('app.color.senior_accent')])
          }
          .width(72)
          .height(72)
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.senior_tint'))
          .margin({ bottom: 8 })

          Text('Carely')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('Who will use this device?')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (!this.paired) {
          Column({ space: 12 }) {
            Text('Set up this phone before using safety features.')
              .fontSize(17)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
            Button('Set up Care Companion')
              .width('100%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .onClick(() => this.navStack.pushPathByName('connection', null))
          }
          .width('100%')
        }

        Blank()

        Text(this.paired ? 'This phone is paired.' : 'Pair once to enable SOS, location sharing, and guardian alerts.')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 48, bottom: 24 })
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.routes)
    .backgroundColor($r('app.color.page_background'))
  }
}
