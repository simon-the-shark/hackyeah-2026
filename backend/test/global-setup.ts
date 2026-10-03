import { runMigrations } from "../src/db/migrate.js";

export default async function setup() {
  await runMigrations(process.env.TEST_DATABASE_URL ?? "postgres://elder:elder@localhost:5432/elder_care_test");
}
