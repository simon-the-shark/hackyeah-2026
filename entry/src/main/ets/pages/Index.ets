import { Feature, GUARDIAN_PROFILE, SENIOR_PROFILE } from '../models/Features';
import { DoseRecord, Medication } from '../models/Medication';
import { CareAlert } from '../models/Safety';
import { apiSession } from '../services/CareApi';
import { ConnectionPage } from './ConnectionPage';
import { AlertDetailPage, AlertsPage } from './AlertsPage';
import { DeveloperToolsPage } from './DeveloperToolsPage';
import { FeaturePage } from './FeaturePage';
import {
  GUARDIAN_MEDICATION_DETAIL_ROUTE,
  GuardianMedicationDetail,
  MEDICATION_FORM_ROUTE
} from './GuardianMedication';
import { MedicationDetail, MedicationDetailParams } from './MedicationDetail';
import { MedicationFormPage, MedicationFormParams } from './MedicationFormPage';
import { ContactEditorPage, ContactEditorTarget } from './GuardianContacts';
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
  // Today's dose answers by occurrence ID, shared by the medicine list and detail screens.
  @Provide('doseRecords') doseRecords: Map<string, DoseRecord> = new Map<string, DoseRecord>();
  @StorageLink('paired') @Watch('onPairedChanged') private paired: boolean = false;

  /** On launch the home opens without a transition, so the setup screen does not flash first. */
  aboutToAppear(): void {
    this.ensureRoleHome(false);
  }

  private onPairedChanged(): void {
    if (this.paired) {
      this.ensureRoleHome();
    }
  }

  private roleHomeRoute(): string {
    return apiSession.role === 'guardian' ? GUARDIAN_PROFILE.route : SENIOR_PROFILE.route;
  }

  /** Paired phones skip role picking and open the saved senior or guardian home. */
  private ensureRoleHome(animated: boolean = true): void {
    if (!this.paired || !apiSession.configured()) {
      return;
    }
    if (this.navStack.size() === 0) {
      this.navStack.pushPathByName(this.roleHomeRoute(), null, animated);
    }
  }

  @Builder
  routes(name: string, param: Object) {
    if (name === SENIOR_PROFILE.route) {
      RoleHome({ profile: SENIOR_PROFILE })
    } else if (name === GUARDIAN_PROFILE.route) {
      RoleHome({ profile: GUARDIAN_PROFILE })
    } else if (name === 'feature') {
      FeaturePage({ feature: param as Feature })
    } else if (name === 'medication-detail') {
      MedicationDetail({ params: param as MedicationDetailParams })
    } else if (name === GUARDIAN_MEDICATION_DETAIL_ROUTE) {
      GuardianMedicationDetail({ medication: param as Medication })
    } else if (name === MEDICATION_FORM_ROUTE) {
      MedicationFormPage({ params: param as MedicationFormParams })
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
    } else if (name === 'contact-editor') {
      ContactEditorPage({ target: param as ContactEditorTarget })
    } else if (name === 'developer-tools') {
      DeveloperToolsPage()
    } else if (name === 'connection') {
      ConnectionPage({ onConnected: (_role: string) => {
        this.paired = true;
        this.navStack.pop();
        this.ensureRoleHome();
      } })
    }
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
          Text('Set up this phone to connect with your care companion.')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .onAppear(() => this.ensureRoleHome())

        if (!this.paired) {
          Column({ space: 12 }) {
            Text('Pair once to enable SOS, location sharing, and guardian alerts.')
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
