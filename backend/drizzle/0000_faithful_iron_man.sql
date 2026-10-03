CREATE TYPE "public"."alert_kind" AS ENUM('sos', 'area_exit', 'dose_missed', 'trip_deviation', 'trip_not_completed', 'monitoring_lost');--> statement-breakpoint
CREATE TYPE "public"."device_kind" AS ENUM('phone', 'watch');--> statement-breakpoint
CREATE TYPE "public"."dose_status" AS ENUM('taken', 'skipped', 'snoozed');--> statement-breakpoint
CREATE TYPE "public"."event_type" AS ENUM('sos', 'sos_cancel', 'area_exit', 'area_enter', 'dose_missed', 'trip_arrived', 'trip_deviation');--> statement-breakpoint
CREATE TYPE "public"."monitoring_state" AS ENUM('inside', 'outside', 'unknown', 'unavailable');--> statement-breakpoint
CREATE TYPE "public"."push_status" AS ENUM('none', 'sent', 'failed', 'simulated');--> statement-breakpoint
CREATE TYPE "public"."report_source" AS ENUM('ai', 'structured', 'simulated');--> statement-breakpoint
CREATE TYPE "public"."role" AS ENUM('senior', 'guardian');--> statement-breakpoint
CREATE TYPE "public"."trip_status" AS ENUM('planned', 'active', 'completed', 'missed');--> statement-breakpoint
CREATE TABLE "alerts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"event_id" uuid,
	"senior_id" uuid NOT NULL,
	"kind" "alert_kind" NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"cancelled_at" timestamp with time zone,
	"push_status" "push_status" DEFAULT 'none' NOT NULL,
	"acknowledged_at" timestamp with time zone,
	"acknowledged_by" uuid,
	"dedup_key" text
);
--> statement-breakpoint
CREATE TABLE "care_links" (
	"senior_id" uuid NOT NULL,
	"guardian_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "care_links_senior_id_guardian_id_pk" PRIMARY KEY("senior_id","guardian_id")
);
--> statement-breakpoint
CREATE TABLE "contacts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"name" text NOT NULL,
	"phone" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"version" integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "devices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"kind" "device_kind" NOT NULL,
	"push_token" text,
	"token_hash" text NOT NULL,
	"last_seen_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dose_records" (
	"occurrence_id" text PRIMARY KEY NOT NULL,
	"medication_id" uuid NOT NULL,
	"senior_id" uuid NOT NULL,
	"status" "dose_status" NOT NULL,
	"scheduled_for" timestamp with time zone,
	"recorded_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "events" (
	"id" uuid PRIMARY KEY NOT NULL,
	"senior_id" uuid NOT NULL,
	"device_id" uuid NOT NULL,
	"type" "event_type" NOT NULL,
	"cancels_event_id" uuid,
	"trip_id" uuid,
	"occurred_at" timestamp with time zone NOT NULL,
	"received_at" timestamp with time zone DEFAULT now() NOT NULL,
	"location" jsonb
);
--> statement-breakpoint
CREATE TABLE "medication_catalog" (
	"barcode" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"form" text,
	"model_asset_key" text,
	"is_synthetic" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE "medications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"name" text NOT NULL,
	"dose_text" text,
	"instructions" text,
	"barcode" text,
	"model_asset_key" text,
	"times" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"timezone" text NOT NULL,
	"version" integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "pairing_codes" (
	"code" text PRIMARY KEY NOT NULL,
	"senior_id" uuid NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"used_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "reports" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"period" text,
	"structured" jsonb NOT NULL,
	"summary" text,
	"source" "report_source" NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "safe_areas" (
	"senior_id" uuid PRIMARY KEY NOT NULL,
	"lat" double precision NOT NULL,
	"lng" double precision NOT NULL,
	"radius_m" integer NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "status_heartbeats" (
	"senior_id" uuid PRIMARY KEY NOT NULL,
	"device_id" uuid,
	"monitoring_state" "monitoring_state" NOT NULL,
	"location" jsonb,
	"battery" integer,
	"reported_at" timestamp with time zone NOT NULL,
	"stale_alerted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "trips" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"label" text NOT NULL,
	"dest_lat" double precision NOT NULL,
	"dest_lng" double precision NOT NULL,
	"radius_m" integer NOT NULL,
	"window_start" timestamp with time zone NOT NULL,
	"window_end" timestamp with time zone NOT NULL,
	"status" "trip_status" DEFAULT 'planned' NOT NULL,
	"version" integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"role" "role" NOT NULL,
	"display_name" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_event_id_events_id_fk" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_acknowledged_by_users_id_fk" FOREIGN KEY ("acknowledged_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "care_links" ADD CONSTRAINT "care_links_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "care_links" ADD CONSTRAINT "care_links_guardian_id_users_id_fk" FOREIGN KEY ("guardian_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dose_records" ADD CONSTRAINT "dose_records_medication_id_medications_id_fk" FOREIGN KEY ("medication_id") REFERENCES "public"."medications"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dose_records" ADD CONSTRAINT "dose_records_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "events" ADD CONSTRAINT "events_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "events" ADD CONSTRAINT "events_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "medications" ADD CONSTRAINT "medications_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "pairing_codes" ADD CONSTRAINT "pairing_codes_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reports" ADD CONSTRAINT "reports_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "safe_areas" ADD CONSTRAINT "safe_areas_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD CONSTRAINT "status_heartbeats_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD CONSTRAINT "status_heartbeats_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trips" ADD CONSTRAINT "trips_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "alerts_senior_idx" ON "alerts" USING btree ("senior_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "alerts_dedup_idx" ON "alerts" USING btree ("dedup_key");--> statement-breakpoint
CREATE UNIQUE INDEX "alerts_event_idx" ON "alerts" USING btree ("event_id");--> statement-breakpoint
CREATE INDEX "contacts_senior_idx" ON "contacts" USING btree ("senior_id");--> statement-breakpoint
CREATE UNIQUE INDEX "devices_token_hash_idx" ON "devices" USING btree ("token_hash");--> statement-breakpoint
CREATE INDEX "devices_user_idx" ON "devices" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "events_senior_idx" ON "events" USING btree ("senior_id","received_at");--> statement-breakpoint
CREATE INDEX "medications_senior_idx" ON "medications" USING btree ("senior_id");--> statement-breakpoint
CREATE INDEX "reports_senior_idx" ON "reports" USING btree ("senior_id","created_at");--> statement-breakpoint
CREATE INDEX "trips_senior_idx" ON "trips" USING btree ("senior_id");