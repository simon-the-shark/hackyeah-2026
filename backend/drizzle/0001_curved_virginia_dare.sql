ALTER TYPE "public"."event_type" ADD VALUE 'trip_started' BEFORE 'trip_arrived';--> statement-breakpoint
ALTER TABLE "dose_records" DROP CONSTRAINT "dose_records_medication_id_medications_id_fk";
--> statement-breakpoint
ALTER TABLE "dose_records" ALTER COLUMN "medication_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "dose_records" ADD COLUMN "medication_name" text;--> statement-breakpoint
ALTER TABLE "dose_records" ADD CONSTRAINT "dose_records_medication_id_medications_id_fk" FOREIGN KEY ("medication_id") REFERENCES "public"."medications"("id") ON DELETE set null ON UPDATE no action;