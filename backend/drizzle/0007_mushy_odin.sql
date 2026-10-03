ALTER TABLE "dose_records" ADD COLUMN "snooze_count" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "medications" ADD COLUMN "missed_grace_minutes" integer;--> statement-breakpoint
ALTER TABLE "medications" ADD COLUMN "max_snoozes" integer;