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

/**
 * What the guardian knows about the senior's last report. Ages are measured on
 * the server clock (`serverTime - reportedAt`) so a wrong clock on either phone
 * cannot make an old position look fresh.
 */
export class SeniorSnapshot {
  seniorName: string = 'Your senior';
  hasStatus: boolean = false;
  monitoringState: string = 'unknown';
  hasLocation: boolean = false;
  lat: number = 0;
  lng: number = 0;
  /** Negative when the senior's phone did not report accuracy. */
  accuracyM: number = -1;
  /** Negative when the senior's phone did not report a battery level. */
  battery: number = -1;
  /** Age of the last heartbeat when it was fetched, on the server clock. */
  reportedAgeMs: number = 0;
  /** Local clock time of the fetch, used to keep the age ticking between refreshes. */
  fetchedAt: number = 0;
  /** The server already raised a `monitoring_lost` alert for the current gap. */
  monitoringLostRaised: boolean = false;
  hasSafeArea: boolean = false;
  /** False when the safe area could not be loaded for a reason other than "not set up". */
  safeAreaKnown: boolean = true;
  areaLat: number = 0;
  areaLng: number = 0;
  areaRadiusM: number = 0;
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

/** "Updated 3 min ago" style headline; never claims the senior is safe. */
export function ageHeadline(snapshot: SeniorSnapshot, now: number): string {
  const age = currentAgeMs(snapshot, now);
  if (freshnessOf(snapshot, now) === Freshness.Stale) {
    return `No update for ${formatDuration(age)}`;
  }
  return age < 60000 ? 'Updated just now' : `Updated ${formatDuration(age)} ago`;
}

export function reportClockTime(snapshot: SeniorSnapshot, now: number): string {
  return formatClockTime(now - currentAgeMs(snapshot, now));
}

/** Describes the monitoring state as a past observation, qualified by its age. */
export function stateSentence(snapshot: SeniorSnapshot, now: number): string {
  const stale = freshnessOf(snapshot, now) === Freshness.Stale;
  let sentence: string;
  if (snapshot.monitoringState === 'inside') {
    sentence = 'Was inside the safe area at the last update.';
  } else if (snapshot.monitoringState === 'outside') {
    sentence = 'Was outside the safe area at the last update.';
  } else if (snapshot.monitoringState === 'unavailable') {
    sentence = 'Location was unavailable on the senior\'s phone at the last update.';
  } else {
    sentence = 'Safe-area status was unknown at the last update.';
  }
  if (stale) {
    sentence += ' This may be out of date. Consider calling to check in.';
  }
  return sentence;
}

export function distanceMeters(latA: number, lngA: number, latB: number, lngB: number): number {
  const earthRadiusMeters = 6371000;
  const toRadians = Math.PI / 180;
  const dLat = (latB - latA) * toRadians;
  const dLng = (lngB - lngA) * toRadians;
  const value = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(latA * toRadians) * Math.cos(latB * toRadians) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}

export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.round(meters / 10) * 10} m`;
  }
  return `${(meters / 1000).toFixed(meters < 10000 ? 1 : 0)} km`;
}
