// Care schedules and wellbeing sessions use the configured local time zone, independent of device settings.
const CARE_TIME_ZONE = 'Europe/Warsaw';

export function deviceTimeZone(): string {
  return CARE_TIME_ZONE;
}
