CREATE TYPE "public"."wellbeing_finish_reason" AS ENUM('senior', 'assistant', 'idle');--> statement-breakpoint
CREATE TYPE "public"."wellbeing_input_mode" AS ENUM('text', 'voice');--> statement-breakpoint
CREATE TYPE "public"."wellbeing_role" AS ENUM('assistant', 'senior');--> statement-breakpoint
CREATE TYPE "public"."wellbeing_session_status" AS ENUM('open', 'finished');--> statement-breakpoint
ALTER TYPE "public"."alert_kind" ADD VALUE 'wellbeing';--> statement-breakpoint
CREATE TABLE "wellbeing_messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"seq" serial NOT NULL,
	"role" "wellbeing_role" NOT NULL,
	"text" text NOT NULL,
	"input_mode" "wellbeing_input_mode",
	"safety_concern" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "wellbeing_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"senior_id" uuid NOT NULL,
	"device_id" uuid,
	"status" "wellbeing_session_status" DEFAULT 'open' NOT NULL,
	"language" text,
	"timezone" text,
	"started_at" timestamp with time zone NOT NULL,
	"last_activity_at" timestamp with time zone NOT NULL,
	"finished_at" timestamp with time zone,
	"finish_reason" "wellbeing_finish_reason",
	"report_id" uuid,
	"assistant" text NOT NULL,
	"simulated" boolean DEFAULT false NOT NULL,
	"senior_messages" integer DEFAULT 0 NOT NULL,
	"voice_messages" integer DEFAULT 0 NOT NULL,
	"safety_alerted" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
ALTER TABLE "wellbeing_messages" ADD CONSTRAINT "wellbeing_messages_session_id_wellbeing_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."wellbeing_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wellbeing_sessions" ADD CONSTRAINT "wellbeing_sessions_senior_id_users_id_fk" FOREIGN KEY ("senior_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wellbeing_sessions" ADD CONSTRAINT "wellbeing_sessions_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wellbeing_sessions" ADD CONSTRAINT "wellbeing_sessions_report_id_reports_id_fk" FOREIGN KEY ("report_id") REFERENCES "public"."reports"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "wellbeing_messages_session_idx" ON "wellbeing_messages" USING btree ("session_id","seq");--> statement-breakpoint
CREATE INDEX "wellbeing_sessions_senior_idx" ON "wellbeing_sessions" USING btree ("senior_id","started_at");--> statement-breakpoint
CREATE INDEX "wellbeing_sessions_status_idx" ON "wellbeing_sessions" USING btree ("status","last_activity_at");--> statement-breakpoint
CREATE UNIQUE INDEX "wellbeing_sessions_open_idx" ON "wellbeing_sessions" USING btree ("senior_id") WHERE "wellbeing_sessions"."status" = 'open';