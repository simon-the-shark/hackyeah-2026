CREATE TYPE "public"."suggestion_status" AS ENUM('pending', 'accepted', 'rejected');--> statement-breakpoint
CREATE TABLE "routine_suggestions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"label" text NOT NULL,
	"dest_lat" double precision NOT NULL,
	"dest_lng" double precision NOT NULL,
	"radius_m" integer NOT NULL,
	"route" jsonb,
	"weekdays" jsonb NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL,
	"timezone" text NOT NULL,
	"source" "event_source" DEFAULT 'device' NOT NULL,
	"status" "suggestion_status" DEFAULT 'pending' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"decided_at" timestamp with time zone,
	"decided_by" uuid
);
--> statement-breakpoint
CREATE TABLE "routines" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"label" text NOT NULL,
	"dest_lat" double precision NOT NULL,
	"dest_lng" double precision NOT NULL,
	"radius_m" integer NOT NULL,
	"route" jsonb,
	"weekdays" jsonb NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL,
	"timezone" text NOT NULL,
	"corridor_m" integer,
	"active" boolean DEFAULT true NOT NULL,
	"suggestion_id" uuid,
	"version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "trips" ADD COLUMN "routine_id" uuid;--> statement-breakpoint
ALTER TABLE "trips" ADD COLUMN "local_date" text;--> statement-breakpoint
ALTER TABLE "routine_suggestions" ADD CONSTRAINT "routine_suggestions_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "routine_suggestions" ADD CONSTRAINT "routine_suggestions_decided_by_users_id_fk" FOREIGN KEY ("decided_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "routines" ADD CONSTRAINT "routines_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "routines" ADD CONSTRAINT "routines_suggestion_id_routine_suggestions_id_fk" FOREIGN KEY ("suggestion_id") REFERENCES "public"."routine_suggestions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "routine_suggestions_senior_idx" ON "routine_suggestions" USING btree ("senior_id","created_at");--> statement-breakpoint
CREATE INDEX "routines_senior_idx" ON "routines" USING btree ("senior_id");--> statement-breakpoint
ALTER TABLE "trips" ADD CONSTRAINT "trips_routine_id_routines_id_fk" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "trips_routine_date_idx" ON "trips" USING btree ("routine_id","local_date");