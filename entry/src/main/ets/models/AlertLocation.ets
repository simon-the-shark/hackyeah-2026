import { formatClockTime } from './Safety';
import { formatDuration } from './SeniorLocation';

/** `event.location` as the care service returns it. Optional fields the device left out arrive as absent or null. */
export interface RemoteGeoPoint {
  lat: number;
  lng: number;
  accuracyM?: number | null;
  sampledAt?: string | null;
  measuredBy?: string | null;
}

/** The position the senior's device attached to an alert's event: a past fix, not live tracking. */
export class AlertLocation {
  lat: number = 0;
  lng: number = 0;
  /** Negative when the device did not report accuracy. */
  accuracyM: number = -1;
  /** 0 when the device did not say when the fix was taken. */
  sampledAt: number = 0;
  /** 'phone', 'watch', or '' when unknown. */
  measuredBy: string = '';
}

export function alertLocationFrom(point: RemoteGeoPoint | null | undefined): AlertLocation | undefined {
  if (point === undefined || point === null || !isFinite(point.lat) || !isFinite(point.lng)) {
    return undefined;
  }
  const location = new AlertLocation();
  location.lat = point.lat;
  location.lng = point.lng;
  const accuracy = point.accuracyM;
  location.accuracyM = accuracy !== undefined && accuracy !== null && isFinite(accuracy) ? accuracy : -1;
  const sampledAt = point.sampledAt !== undefined && point.sampledAt !== null ? Date.parse(point.sampledAt) : NaN;
  location.sampledAt = isFinite(sampledAt) ? sampledAt : 0;
  location.measuredBy = point.measuredBy === 'phone' || point.measuredBy === 'watch' ? point.measuredBy : '';
  return location;
}

/**
 * When the fix was taken, relative to the alert. Both times come from the
 * senior's device clock, so a wrong clock on the guardian phone or server
 * cannot make the position look fresher than it is.
 */
export function fixTimeLabel(location: AlertLocation, occurredAt: number): string {
  if (location.sampledAt <= 0) {
    return 'Time of the position unknown';
  }
  const clock = formatClockTime(location.sampledAt);
  if (!isFinite(occurredAt) || occurredAt <= 0) {
    return `Position from ${clock}`;
  }
  const before = occurredAt - location.sampledAt;
  if (before < 60000) {
    return `Position from ${clock}, at the time of the alert`;
  }
  return `Position from ${clock}, ${formatDuration(before)} before the alert`;
}

export function sourceLabel(location: AlertLocation): string {
  if (location.measuredBy === 'watch') {
    return 'From the senior\'s watch';
  }
  if (location.measuredBy === 'phone') {
    return 'From the senior\'s phone';
  }
  return 'From the senior\'s device';
}

export function formatCoordinates(lat: number, lng: number): string {
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
}

export function accuracyLabel(location: AlertLocation): string {
  return location.accuracyM < 0 ? 'Accuracy unknown' : `Within about ${Math.max(1, Math.round(location.accuracyM))} m`;
}

/** Public OpenStreetMap link with a marker; the browser fallback when Petal Maps cannot open. */
export function mapLinkUrl(lat: number, lng: number): string {
  const latText = lat.toFixed(6);
  const lngText = lng.toFixed(6);
  return `https://www.openstreetmap.org/?mlat=${latText}&mlon=${lngText}#map=17/${latText}/${lngText}`;
}
