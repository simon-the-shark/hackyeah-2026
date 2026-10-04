// Care schedules and wellbeing sessions use the configured local time zone, independent of device settings.
// Known limitation: dose times are computed in the device's local time (MedicationSchedule.todaysDoses), so the
// phone must be set to this zone; on a device in another zone the shown times and missed-dose checks disagree.
const CARE_TIME_ZONE = 'Europe/Warsaw';

export function deviceTimeZone(): string {
  return CARE_TIME_ZONE;
}
