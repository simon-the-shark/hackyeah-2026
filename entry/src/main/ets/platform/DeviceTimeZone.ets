import { i18n } from '@kit.LocalizationKit';

const FALLBACK_ZONE = 'UTC';

// IANA ID of this device's time zone, e.g. "Europe/Warsaw" (`i18n.getTimeZone().getID()`, public API since 7).
// Falls back to UTC if the platform returns nothing, so a form can still be saved.
export function deviceTimeZone(): string {
  try {
    const id = i18n.getTimeZone().getID();
    return id.length > 0 ? id : FALLBACK_ZONE;
  } catch (err) {
    return FALLBACK_ZONE;
  }
}
