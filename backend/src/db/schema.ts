import { sql } from "drizzle-orm";
import {
  boolean,
  doublePrecision,
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

export const roleEnum = pgEnum("role", ["senior", "guardian"]);
export const deviceKindEnum = pgEnum("device_kind", ["phone", "watch"]);
export const eventTypeEnum = pgEnum("event_type", [
  "sos",
  "sos_cancel",
  "area_exit",
  "area_enter",
  "dose_missed",
  "trip_started",
  "trip_arrived",
  "trip_deviation",
  "fall_detected",
  "cancel",
]);
export const alertKindEnum = pgEnum("alert_kind", [
  "sos",
  "area_exit",
  "dose_missed",
  "trip_deviation",
  "trip_not_completed",
  "monitoring_lost",
  "fall",
]);
export const pushStatusEnum = pgEnum("push_status", ["none", "sent", "failed", "simulated"]);
export const doseStatusEnum = pgEnum("dose_status", ["taken", "skipped", "snoozed"]);
export const monitoringStateEnum = pgEnum("monitoring_state", [
  "inside",
  "outside",
  "unknown",
  "unavailable",
]);
export const reportSourceEnum = pgEnum("report_source", ["ai", "structured", "simulated"]);
export const tripStatusEnum = pgEnum("trip_status", ["planned", "active", "completed", "missed"]);
/** Where an event or heartbeat came from; anything but `device` is a labelled simulation. */
export const eventSourceEnum = pgEnum("event_source", ["device", "trace_replay", "simulated"]);

const createdAt = () => timestamp("created_at", { withTimezone: true }).notNull().defaultNow();

export type GeoPoint = {
  lat: number;
  lng: number;
  accuracyM?: number;
  /** ISO timestamp of the location sample; lets guardians judge freshness. */
  sampledAt?: string;
  /** Which device measured the fix; a phone fix relayed by the watch stays `phone`. */
  measuredBy?: "phone" | "watch";
};

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  role: roleEnum("role").notNull(),
  displayName: text("display_name").notNull(),
  createdAt: createdAt(),
});

export const careLinks = pgTable(
  "care_links",
  {
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    guardianId: uuid("guardian_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    createdAt: createdAt(),
  },
  (t) => [primaryKey({ columns: [t.seniorId, t.guardianId] })],
);

export const pairingCodes = pgTable("pairing_codes", {
  code: text("code").primaryKey(),
  seniorId: uuid("senior_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  usedAt: timestamp("used_at", { withTimezone: true }),
});

export const devices = pgTable(
  "devices",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    kind: deviceKindEnum("kind").notNull(),
    pushToken: text("push_token"),
    /** sha256 of the opaque bearer token; the token itself is never stored. */
    tokenHash: text("token_hash").notNull(),
    lastSeenAt: timestamp("last_seen_at", { withTimezone: true }),
    /** Revoked devices cannot authenticate; the row is kept so its events stay attributable. */
    revokedAt: timestamp("revoked_at", { withTimezone: true }),
    createdAt: createdAt(),
  },
  (t) => [uniqueIndex("devices_token_hash_idx").on(t.tokenHash), index("devices_user_idx").on(t.userId)],
);

export const safeAreas = pgTable("safe_areas", {
  seniorId: uuid("senior_id")
    .primaryKey()
    .references(() => users.id, { onDelete: "cascade" }),
  lat: doublePrecision("lat").notNull(),
  lng: doublePrecision("lng").notNull(),
  radiusM: integer("radius_m").notNull(),
  version: integer("version").notNull().default(1),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export const contacts = pgTable(
  "contacts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    phone: text("phone").notNull(),
    sortOrder: integer("sort_order").notNull().default(0),
    /** Offered first when an SOS cannot be delivered (call this person). */
    isEmergency: boolean("is_emergency").notNull().default(false),
    version: integer("version").notNull().default(1),
  },
  (t) => [index("contacts_senior_idx").on(t.seniorId)],
);

export const medications = pgTable(
  "medications",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    /** User-confirmed dose text; never inferred from a barcode. */
    doseText: text("dose_text"),
    instructions: text("instructions"),
    barcode: text("barcode"),
    modelAssetKey: text("model_asset_key"),
    /** Local times of day, e.g. ["08:00", "20:00"]. */
    times: jsonb("times").$type<string[]>().notNull().default(sql`'[]'::jsonb`),
    timezone: text("timezone").notNull(),
    /** Per-medication missed-dose grace; null uses DOSE_MISSED_GRACE_MINUTES. */
    missedGraceMinutes: integer("missed_grace_minutes"),
    /** Snoozes that restart the grace period; later snoozes are recorded but no longer delay it. Null: no cap. */
    maxSnoozes: integer("max_snoozes"),
    version: integer("version").notNull().default(1),
    /**
     * Set on create and whenever `times` or `timezone` change (not on name or other edits);
     * only doses scheduled after it can be reported missed.
     */
    scheduleUpdatedAt: timestamp("schedule_updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index("medications_senior_idx").on(t.seniorId)],
);

export const doseRecords = pgTable("dose_records", {
  /** Client-generated stable occurrence id (medication + scheduled time). */
  occurrenceId: text("occurrence_id").primaryKey(),
  /** Null after the medication is deleted; the dose history is kept. */
  medicationId: uuid("medication_id").references(() => medications.id, { onDelete: "set null" }),
  /** Name at recording time, so history stays readable after a medication is deleted or renamed. */
  medicationName: text("medication_name"),
  seniorId: uuid("senior_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  status: doseStatusEnum("status").notNull(),
  /** Snoozes recorded for this occurrence (counted against the medication's maxSnoozes). */
  snoozeCount: integer("snooze_count").notNull().default(0),
  scheduledFor: timestamp("scheduled_for", { withTimezone: true }),
  recordedAt: timestamp("recorded_at", { withTimezone: true }).notNull(),
});

export const events = pgTable(
  "events",
  {
    /** Client-generated; makes retries idempotent. */
    id: uuid("id").primaryKey(),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    deviceId: uuid("device_id")
      .notNull()
      .references(() => devices.id, { onDelete: "cascade" }),
    type: eventTypeEnum("type").notNull(),
    cancelsEventId: uuid("cancels_event_id"),
    /** Set for trip_arrived / trip_deviation events. */
    tripId: uuid("trip_id"),
    occurredAt: timestamp("occurred_at", { withTimezone: true }).notNull(),
    receivedAt: timestamp("received_at", { withTimezone: true }).notNull().defaultNow(),
    location: jsonb("location").$type<GeoPoint>(),
    source: eventSourceEnum("source").notNull().default("device"),
  },
  (t) => [index("events_senior_idx").on(t.seniorId, t.receivedAt)],
);

export const alerts = pgTable(
  "alerts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    eventId: uuid("event_id").references(() => events.id, { onDelete: "set null" }),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    kind: alertKindEnum("kind").notNull(),
    createdAt: createdAt(),
    cancelledAt: timestamp("cancelled_at", { withTimezone: true }),
    /** Request accepted by the push provider. Not proof a guardian saw it. */
    pushStatus: pushStatusEnum("push_status").notNull().default("none"),
    /** Push sends to guardians so far (first send, SOS reminders, failed-push retry). */
    pushAttempts: integer("push_attempts").notNull().default(0),
    lastPushAt: timestamp("last_push_at", { withTimezone: true }),
    acknowledgedAt: timestamp("acknowledged_at", { withTimezone: true }),
    acknowledgedBy: uuid("acknowledged_by").references(() => users.id, { onDelete: "set null" }),
    /** The condition ended (e.g. back inside the safe area). Separate from acknowledgement; the alert is kept. */
    resolvedAt: timestamp("resolved_at", { withTimezone: true }),
    /** The event that resolved it, when there was one (area_enter, trip_arrived). */
    resolvedByEventId: uuid("resolved_by_event_id"),
    /** Dedup key for server-generated alerts (monitoring_lost, trip_not_completed, dose_missed). */
    dedupKey: text("dedup_key"),
    /** Context for server-generated alerts that have no source event, e.g. the missed dose. */
    details: jsonb("details").$type<Record<string, unknown>>(),
  },
  (t) => [
    index("alerts_senior_idx").on(t.seniorId, t.createdAt),
    uniqueIndex("alerts_dedup_idx").on(t.dedupKey),
    uniqueIndex("alerts_event_idx").on(t.eventId),
  ],
);

/** Latest heartbeat per device, so a phone and a watch never overwrite each other. */
export const statusHeartbeats = pgTable(
  "status_heartbeats",
  {
    deviceId: uuid("device_id")
      .primaryKey()
      .references(() => devices.id, { onDelete: "cascade" }),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    monitoringState: monitoringStateEnum("monitoring_state").notNull(),
    location: jsonb("location").$type<GeoPoint>(),
    battery: integer("battery"),
    source: eventSourceEnum("source").notNull().default("device"),
    reportedAt: timestamp("reported_at", { withTimezone: true }).notNull(),
    /**
     * Set on all of a senior's rows when a monitoring_lost alert was raised for the current gap
     * (every device stale); a fresh heartbeat from any device clears it on all rows.
     */
    staleAlertedAt: timestamp("stale_alerted_at", { withTimezone: true }),
  },
  (t) => [index("status_heartbeats_senior_idx").on(t.seniorId)],
);

export const reports = pgTable(
  "reports",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    period: text("period"),
    structured: jsonb("structured").$type<Record<string, unknown>>().notNull(),
    summary: text("summary"),
    source: reportSourceEnum("source").notNull(),
    createdAt: createdAt(),
  },
  (t) => [index("reports_senior_idx").on(t.seniorId, t.createdAt)],
);

export const trips = pgTable(
  "trips",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    seniorId: uuid("senior_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    label: text("label").notNull(),
    destLat: doublePrecision("dest_lat").notNull(),
    destLng: doublePrecision("dest_lng").notNull(),
    radiusM: integer("radius_m").notNull(),
    /** Optional intended route; the device checks deviation from it, the server only stores it. */
    route: jsonb("route").$type<{ lat: number; lng: number }[]>(),
    /** Allowed distance from the route before the device reports trip_deviation. */
    corridorM: integer("corridor_m"),
    windowStart: timestamp("window_start", { withTimezone: true }).notNull(),
    windowEnd: timestamp("window_end", { withTimezone: true }).notNull(),
    status: tripStatusEnum("status").notNull().default("planned"),
    version: integer("version").notNull().default(1),
  },
  (t) => [index("trips_senior_idx").on(t.seniorId)],
);

/** Synthetic demo data only; barcodes identify a candidate, never a prescription. */
export const medicationCatalog = pgTable("medication_catalog", {
  barcode: text("barcode").primaryKey(),
  name: text("name").notNull(),
  form: text("form"),
  modelAssetKey: text("model_asset_key"),
  isSynthetic: boolean("is_synthetic").notNull().default(true),
});

export type PushStatus = (typeof pushStatusEnum.enumValues)[number];
