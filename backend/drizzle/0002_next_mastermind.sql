ALTER TABLE "alerts" ADD COLUMN "details" jsonb;--> statement-breakpoint
ALTER TABLE "medications" ADD COLUMN "schedule_updated_at" timestamp with time zone DEFAULT now() NOT NULL;