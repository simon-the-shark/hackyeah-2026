export class Feature {
  readonly id: string;
  readonly title: string;
  readonly summary: string;
  readonly icon: Resource;
  readonly accent: Resource;
  readonly tint: Resource;

  constructor(id: string, title: string, summary: string, icon: Resource, accent: Resource, tint: Resource) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.icon = icon;
    this.accent = accent;
    this.tint = tint;
  }
}

export class FeatureSection {
  readonly title: string;
  readonly features: Feature[];

  constructor(title: string, features: Feature[]) {
    this.title = title;
    this.features = features;
  }
}

export class RoleProfile {
  readonly route: string;
  readonly label: string;
  readonly description: string;
  readonly headline: string;
  readonly icon: Resource;
  readonly accent: Resource;
  readonly tint: Resource;
  readonly hero: Feature;
  readonly heroColor: Resource;
  readonly sections: FeatureSection[];
  readonly tabs: Feature[];

  constructor(route: string, label: string, description: string, headline: string, icon: Resource,
    accent: Resource, tint: Resource, hero: Feature, heroColor: Resource, sections: FeatureSection[],
    tabs: Feature[] = []) {
    this.route = route;
    this.label = label;
    this.description = description;
    this.headline = headline;
    this.icon = icon;
    this.accent = accent;
    this.tint = tint;
    this.hero = hero;
    this.heroColor = heroColor;
    this.sections = sections;
    this.tabs = tabs;
  }
}

function seniorFeature(id: string, title: string, summary: string, icon: Resource): Feature {
  return new Feature(id, title, summary, icon, $r('app.color.senior_accent'), $r('app.color.senior_tint'));
}

function guardianFeature(id: string, title: string, summary: string, icon: Resource): Feature {
  return new Feature(id, title, summary, icon, $r('app.color.guardian_accent'), $r('app.color.guardian_tint'));
}

export const SENIOR_PROFILE: RoleProfile = new RoleProfile(
  'senior',
  'Senior',
  'SOS, medication, contacts and daily check-ins',
  'How can we help today?',
  $r('sys.symbol.person_crop_circle_fill_1'),
  $r('app.color.senior_accent'),
  $r('app.color.senior_tint'),
  new Feature('sos', 'SOS', 'Ask your guardian for help with one tap',
    $r('sys.symbol.exclamationmark_shield_fill'), $r('app.color.sos'), $r('app.color.sos_tint')),
  $r('app.color.sos'),
  [
    new FeatureSection('Safety and setup', [
      seniorFeature('safe-area', 'Safe Area', 'Home area monitoring status', $r('sys.symbol.house_shield_fill')),
      seniorFeature('settings', 'Settings', 'Pairing, permissions and preferences', $r('sys.symbol.gearshape_fill'))
    ])
  ],
  [
    seniorFeature('medication', 'Medication', 'Doses, reminders and medicine scanning',
      $r('sys.symbol.cross_case')),
    seniorFeature('contacts', 'Contacts', 'Call trusted people quickly', $r('sys.symbol.phone_fill')),
    seniorFeature('wellbeing', 'Wellbeing', 'Daily check-in and private assistant', $r('sys.symbol.heart_fill'))
  ]
);

export const GUARDIAN_PROFILE: RoleProfile = new RoleProfile(
  'guardian',
  'Guardian',
  'Alerts, care setup and wellbeing reports',
  'Care at a glance',
  $r('sys.symbol.person_shield_1'),
  $r('app.color.guardian_accent'),
  $r('app.color.guardian_tint'),
  guardianFeature('overview', 'Overview', 'Latest known status of your senior', $r('sys.symbol.person_2_fill')),
  $r('app.color.guardian_accent'),
  [
    new FeatureSection('Safety', [
      guardianFeature('watch-vitals', 'Watch & vitals', 'Watch location and heart rate', $r('sys.symbol.watch_fill')),
      guardianFeature('planned-trips', 'Planned Trips', 'Destinations and expected arrival times',
        $r('sys.symbol.figure_walk')),
      guardianFeature('safe-area-setup', 'Safe Area', 'Set the home area and its radius', $r('sys.symbol.map'))
    ]),
    new FeatureSection('Insights', [
      guardianFeature('dose-history', 'Dose History', 'Taken, skipped and snoozed doses',
        $r('sys.symbol.checkmark_clipboard_fill')),
      guardianFeature('wellbeing-reports', 'Wellbeing Reports', 'Check-in summaries shared with you',
        $r('sys.symbol.doc_text_fill'))
    ]),
    new FeatureSection('Account', [
      new Feature('sign-out', 'Sign out', 'Return this device to setup', $r('sys.symbol.arrow_right'),
        $r('app.color.sos'), $r('app.color.sos_tint'))
    ])
  ],
  [
    guardianFeature('alerts', 'Alerts', 'SOS and safe-area notifications', $r('sys.symbol.bell_fill')),
    guardianFeature('location', 'Location', 'Where your senior was last seen', $r('sys.symbol.location_up_fill')),
    guardianFeature('medication-schedule', 'Medication', 'Medicines and dose times', $r('sys.symbol.cross_case')),
    guardianFeature('trusted-contacts', 'Contacts', 'People the senior can call', $r('sys.symbol.phone_fill'))
  ]
);

export const ROLE_PROFILES: RoleProfile[] = [SENIOR_PROFILE, GUARDIAN_PROFILE];
