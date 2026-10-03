CREATE TYPE "public"."pairing_purpose" AS ENUM('guardian', 'watch');--> statement-breakpoint
CREATE TYPE "public"."vital_kind" AS ENUM('heart_rate');--> statement-breakpoint
ALTER TYPE "public"."alert_kind" ADD VALUE 'heart_rate';--> statement-breakpoint
ALTER TYPE "public"."event_type" ADD VALUE 'heart_rate_out_of_range';--> statement-breakpoint
ALTER TYPE "public"."event_type" ADD VALUE 'heart_rate_in_range';--> statement-breakpoint
CREATE TABLE "vital_samples" (
	"senior_id" uuid NOT NULL,
	"device_id" uuid NOT NULL,
	"kind" "vital_kind" NOT NULL,
	"value" integer NOT NULL,
	"measured_at" timestamp with time zone NOT NULL,
	"received_at" timestamp with time zone DEFAULT now() NOT NULL,
	"source" "event_source" NOT NULL,
	CONSTRAINT "vital_samples_device_id_kind_measured_at_pk" PRIMARY KEY("device_id","kind","measured_at")
);
--> statement-breakpoint
ALTER TABLE "pairing_codes" ADD COLUMN "purpose" "pairing_purpose" DEFAULT 'guardian' NOT NULL;--> statement-breakpoint
ALTER TABLE "vital_samples" ADD CONSTRAINT "vital_samples_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vital_samples" ADD CONSTRAINT "vital_samples_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "vital_samples_senior_idx" ON "vital_samples" USING btree ("senior_id","kind","measured_at");