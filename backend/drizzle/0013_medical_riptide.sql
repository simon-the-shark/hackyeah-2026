ALTER TYPE "public"."alert_kind" ADD VALUE 'low_battery';--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD COLUMN "low_battery_alerted_at" timestamp with time zone;