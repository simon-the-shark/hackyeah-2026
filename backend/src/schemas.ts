import { z } from "zod";

export const uuid = z.uuid();
export const lat = z.number().min(-90).max(90);
export const lng = z.number().min(-180).max(180);
export const radiusM = z.number().int().min(20).max(50_000);
export const isoDate = z.iso.datetime({ offset: true }).transform((s) => new Date(s));
export const deviceKind = z.enum(["phone", "watch"]);
export const idParam = z.object({ id: uuid });
export const seniorParam = z.object({ seniorId: uuid });

export const geoPoint = z.object({
  lat,
  lng,
  accuracyM: z.number().nonnegative().optional(),
  sampledAt: z.iso.datetime({ offset: true }).optional(),
  measuredBy: z.enum(["phone", "watch"]).optional(),
});

/** `trace_replay` and `simulated` are shown to guardians as simulations. */
export const eventSource = z.enum(["device", "trace_replay", "simulated"]).default("device");

export const phone = z.string().regex(/^\+?[0-9 ()-]{3,20}$/, "Invalid phone number");
export const timeOfDay = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Expected HH:MM");
export const timezone = z.string().refine((tz) => {
  try {
    new Intl.DateTimeFormat("en", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}, "Unknown IANA time zone");
