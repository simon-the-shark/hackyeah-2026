/** Great-circle (haversine) distance in meters between two WGS84 points. */
export function distanceMeters(latA: number, lngA: number, latB: number, lngB: number): number {
  const earthRadiusMeters = 6371000;
  const toRadians = Math.PI / 180;
  const dLat = (latB - latA) * toRadians;
  const dLng = (lngB - lngA) * toRadians;
  const value = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(latA * toRadians) * Math.cos(latB * toRadians) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}
