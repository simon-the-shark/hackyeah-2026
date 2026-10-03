ALTER TABLE "alerts" ADD COLUMN "resolved_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "alerts" ADD COLUMN "resolved_by_event_id" uuid;