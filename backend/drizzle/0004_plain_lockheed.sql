ALTER TABLE "status_heartbeats" DROP CONSTRAINT "status_heartbeats_device_id_devices_id_fk";--> statement-breakpoint
-- Heartbeats are now keyed per device; rows without a device cannot be kept.
DELETE FROM "status_heartbeats" WHERE "device_id" IS NULL;--> statement-breakpoint
ALTER TABLE "status_heartbeats" DROP CONSTRAINT "status_heartbeats_pkey";--> statement-breakpoint
ALTER TABLE "status_heartbeats" ALTER COLUMN "device_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD PRIMARY KEY ("device_id");--> statement-breakpoint
ALTER TABLE "status_heartbeats" ADD CONSTRAINT "status_heartbeats_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "status_heartbeats_senior_idx" ON "status_heartbeats" USING btree ("senior_id");
