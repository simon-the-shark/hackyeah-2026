import { formatClockTime } from './Safety';
import { RemoteStatusResponse, SeniorSnapshot, snapshotFromStatus } from './SeniorLocation';

/** Server-computed state of one scheduled dose (`GET /seniors/:id/dose-schedule`). */
export enum ScheduledDoseStatus {
  Pending = 'pending',
  Taken = 'taken',
  Skipped = 'skipped',
  Snoozed = 'snoozed',
  Missed = 'missed'
}

/** One occurrence from `/dose-schedule` or `/overview.nextDoses`. Fields are checked before use. */
export interface RemoteScheduledDose {
  occurrenceId?: string;
  medicationId?: string;
  medicationName?: string;
  doseText?: string | null;
  localTime?: string;
  timezone?: string;
  scheduledFor?: string;
  status?: string;
  recordedAt?: string | null;
}

export interface RemoteDoseSchedule {
  items?: RemoteScheduledDose[];
  serverTime?: string;
}

interface RemoteOverviewSenior {
  id?: string;
  displayName?: string;
}

/** `overview.latestReport`: the newest wellbeing summary, without its content. */
interface RemoteLatestReport {
  id?: string;
  createdAt?: string;
  attention?: string | null;
}

interface RemoteAlertCounts {
  unacknowledged?: number;
  unresolved?: number;
}

/** `GET /seniors/:id/overview`: `status`, `devices` and `serverTime` have the `/status` shape. */
export interface RemoteOverview extends RemoteStatusResponse {
  senior?: RemoteOverviewSenior | null;
  alerts?: RemoteAlertCounts | null;
  nextDoses?: RemoteScheduledDose[];
  missedDosesLast24h?: number;
  latestReportAt?: string | null;
  latestReport?: RemoteLatestReport | null;
  safeAreaVersion?: number | null;
}

export class ScheduledDose {
  occurrenceId: string = '';
  medicationName: string = '';
  doseText: string = '';
  /** "HH:MM" in the medication's time zone. */
  localTime: string = '';
  /** "YYYY-MM-DD" in the medication's time zone, taken from the occurrence id. */
  localDate: string = '';
  scheduledFor: number = 0;
  status: ScheduledDoseStatus = ScheduledDoseStatus.Pending;
  /** 0 when the senior has not answered. */
  recordedAt: number = 0;
}

export class DoseDay {
  date: string = '';
  doses: ScheduledDose[] = [];
}

export class DoseTally {
  taken: number = 0;
  skipped: number = 0;
  snoozed: number = 0;
  missed: number = 0;
}

/** What the guardian overview shows, measured on the server clock like the Location tab. */
export class CareOverview {
  snapshot: SeniorSnapshot = new SeniorSnapshot();
  unacknowledgedAlerts: number = 0;
  nextDoses: ScheduledDose[] = [];
  missedLast24h: number = 0;
  /** Negative when no wellbeing report was shared yet. */
  latestReportAgeMs: number = -1;
  /** The newest report was marked "soon" or "urgent" by the assistant. */
  latestReportNeedsAttention: boolean = false;
  hasSafeArea: boolean = false;
}

const OCCURRENCE_DATE = new RegExp('@(\\d{4}-\\d{2}-\\d{2})T');
const STATUSES: ScheduledDoseStatus[] = [ScheduledDoseStatus.Pending, ScheduledDoseStatus.Taken,
  ScheduledDoseStatus.Skipped, ScheduledDoseStatus.Snoozed, ScheduledDoseStatus.Missed];

function count(value: number | undefined): number {
  return typeof value === 'number' && isFinite(value) && value > 0 ? value : 0;
}

/** "YYYY-MM-DD" of a timestamp on the device clock. */
export function localDateKey(timestamp: number): string {
  const date = new Date(timestamp);
  return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-` +
    `${date.getDate().toString().padStart(2, '0')}`;
}

/** Undefined for an item the app cannot show (missing id or time, or an unknown status). */
export function scheduledDoseFrom(dto: RemoteScheduledDose): ScheduledDose | undefined {
  const scheduledFor = typeof dto.scheduledFor === 'string' ? Date.parse(dto.scheduledFor) : NaN;
  const status = STATUSES.find((value: ScheduledDoseStatus) => value === dto.status);
  if (typeof dto.occurrenceId !== 'string' || isNaN(scheduledFor) || status === undefined) {
    return undefined;
  }
  const dose = new ScheduledDose();
  dose.occurrenceId = dto.occurrenceId;
  dose.medicationName = typeof dto.medicationName === 'string' && dto.medicationName !== '' ?
    dto.medicationName : 'Medicine';
  dose.doseText = typeof dto.doseText === 'string' ? dto.doseText : '';
  dose.localTime = typeof dto.localTime === 'string' ? dto.localTime : formatClockTime(scheduledFor);
  const match = OCCURRENCE_DATE.exec(dto.occurrenceId);
  dose.localDate = match !== null ? match[1] : localDateKey(scheduledFor);
  dose.scheduledFor = scheduledFor;
  dose.status = status;
  const recordedAt = typeof dto.recordedAt === 'string' ? Date.parse(dto.recordedAt) : NaN;
  dose.recordedAt = isNaN(recordedAt) ? 0 : recordedAt;
  return dose;
}

export function scheduledDosesFrom(items: RemoteScheduledDose[] | undefined): ScheduledDose[] {
  const doses: ScheduledDose[] = [];
  (items ?? []).forEach((item: RemoteScheduledDose) => {
    const dose = scheduledDoseFrom(item);
    if (dose !== undefined) {
      doses.push(dose);
    }
  });
  return doses;
}

/** Newest day first, and the latest dose first within a day. */
export function groupByDay(doses: ScheduledDose[]): DoseDay[] {
  const sorted = doses.slice().sort((a: ScheduledDose, b: ScheduledDose) =>
    a.localDate === b.localDate ? b.scheduledFor - a.scheduledFor : b.localDate.localeCompare(a.localDate));
  const days: DoseDay[] = [];
  sorted.forEach((dose: ScheduledDose) => {
    const last = days.length > 0 ? days[days.length - 1] : undefined;
    if (last !== undefined && last.date === dose.localDate) {
      last.doses.push(dose);
    } else {
      const day = new DoseDay();
      day.date = dose.localDate;
      day.doses = [dose];
      days.push(day);
    }
  });
  return days;
}

export function tallyOf(doses: ScheduledDose[]): DoseTally {
  const tally = new DoseTally();
  doses.forEach((dose: ScheduledDose) => {
    if (dose.status === ScheduledDoseStatus.Taken) {
      tally.taken++;
    } else if (dose.status === ScheduledDoseStatus.Skipped) {
      tally.skipped++;
    } else if (dose.status === ScheduledDoseStatus.Snoozed) {
      tally.snoozed++;
    } else if (dose.status === ScheduledDoseStatus.Missed) {
      tally.missed++;
    }
  });
  return tally;
}

/** "Today", "Yesterday" or "Wednesday 1 October" for a "YYYY-MM-DD" key. */
export function dayLabel(date: string, now: number): string {
  if (date === localDateKey(now)) {
    return 'Today';
  }
  if (date === localDateKey(now - 24 * 60 * 60 * 1000)) {
    return 'Yesterday';
  }
  const parsed = new Date(`${date}T12:00:00`);
  return isNaN(parsed.getTime()) ? date :
  parsed.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' });
}

/** What happened to the dose, in words; colour is never the only signal. */
export function doseStatusText(dose: ScheduledDose, now: number): string {
  if (dose.status === ScheduledDoseStatus.Taken) {
    return dose.recordedAt > 0 ? `Taken at ${formatClockTime(dose.recordedAt)}` : 'Taken';
  }
  if (dose.status === ScheduledDoseStatus.Skipped) {
    return 'Skipped';
  }
  if (dose.status === ScheduledDoseStatus.Snoozed) {
    return 'Snoozed, no answer yet';
  }
  if (dose.status === ScheduledDoseStatus.Missed) {
    return 'Missed, no answer';
  }
  return dose.scheduledFor <= now ? 'Due, no answer yet' : 'Upcoming';
}

export function overviewFrom(dto: RemoteOverview, fetchedAt: number): CareOverview {
  const overview = new CareOverview();
  overview.snapshot = snapshotFromStatus(dto, fetchedAt);
  const name = dto.senior?.displayName;
  if (typeof name === 'string' && name !== '') {
    overview.snapshot.seniorName = name;
  }
  overview.unacknowledgedAlerts = count(dto.alerts?.unacknowledged);
  overview.nextDoses = scheduledDosesFrom(dto.nextDoses);
  overview.missedLast24h = count(dto.missedDosesLast24h);
  const serverNow = Date.parse(dto.serverTime);
  const report = typeof dto.latestReportAt === 'string' ? Date.parse(dto.latestReportAt) : NaN;
  if (!isNaN(report) && !isNaN(serverNow)) {
    overview.latestReportAgeMs = Math.max(0, serverNow - report);
  }
  const attention = dto.latestReport?.attention;
  overview.latestReportNeedsAttention = attention === 'soon' || attention === 'urgent';
  overview.hasSafeArea = typeof dto.safeAreaVersion === 'number';
  return overview;
}
