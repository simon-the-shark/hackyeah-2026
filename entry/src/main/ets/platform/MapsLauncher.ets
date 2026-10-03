import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { mapCommon, petalMaps } from '@kit.MapKit';
import { mapLinkUrl } from '../models/AlertLocation';

/** Where a position was opened; `None` when neither Petal Maps nor a browser could open it. */
export enum MapsHandOff {
  PetalMaps,
  Browser,
  None
}

/**
 * Opens a position in Petal Maps, or as an OpenStreetMap web link in the
 * browser when Petal Maps cannot start (for example, it is not installed).
 */
export async function openInMaps(context: common.UIAbilityContext, lat: number, lng: number,
  label: string): Promise<MapsHandOff> {
  const position: mapCommon.LatLng = { latitude: lat, longitude: lng };
  const params: petalMaps.PoiDetailParams = { destinationPosition: position, destinationName: label };
  try {
    await petalMaps.openMapPoiDetail(context, params);
    return MapsHandOff.PetalMaps;
  } catch (error) {
    console.warn(`[MapsLauncher] Petal Maps unavailable: ${(error as BusinessError).code}`);
  }
  try {
    await context.openLink(mapLinkUrl(lat, lng), { appLinkingOnly: false });
    return MapsHandOff.Browser;
  } catch (error) {
    console.error(`[MapsLauncher] map link failed: ${(error as BusinessError).code}`);
    return MapsHandOff.None;
  }
}
