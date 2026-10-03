CREATE TYPE "public"."event_source" AS ENUM('device', 'trace_replay', 'simulated');--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "source" "event_source" DEFAULT 'device' NOT NULL;--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD COLUMN "source" "event_source" DEFAULT 'device' NOT NULL;