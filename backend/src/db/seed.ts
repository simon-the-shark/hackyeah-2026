import { eq } from "drizzle-orm";
import { generateToken, hashToken } from "../auth/tokens.js";
import { createDb } from "./client.js";
import { careLinks, contacts, devices, medicationCatalog, medications, safeAreas, users } from "./schema.js";

/** Synthetic demo data only. Prints fresh device tokens; they are never stored in plain text. */
const url = process.env.DATABASE_URL;
if (!url) throw new Error("DATABASE_URL is required");
const { db, close } = createDb(url);

await db
  .insert(medicationCatalog)
  .values([
    { barcode: "5900000000011", name: "Demo Pain Relief 500 mg (synthetic)", form: "tablet", modelAssetKey: "pill-round" },
    { barcode: "5900000000028", name: "Demo Blood Pressure 5 mg (synthetic)", form: "tablet", modelAssetKey: "pill-oval" },
    { barcode: "5900000000035", name: "Demo Vitamin D 2000 IU (synthetic)", form: "capsule", modelAssetKey: "capsule" },
  ])
  .onConflictDoNothing();

const [existing] = await db.select().from(users).where(eq(users.displayName, "Demo Senior (Halina)"));
if (existing) {
  console.log("Demo data already seeded; delete the demo users to re-seed.");
} else {
  const [senior] = await db.insert(users).values({ role: "senior", displayName: "Demo Senior (Halina)" }).returning();
  const [guardian] = await db.insert(users).values({ role: "guardian", displayName: "Demo Guardian (Marek)" }).returning();
  await db.insert(careLinks).values({ seniorId: senior!.id, guardianId: guardian!.id });
  const seniorToken = generateToken();
  const guardianToken = generateToken();
  await db.insert(devices).values([
    { userId: senior!.id, kind: "phone", tokenHash: hashToken(seniorToken) },
    { userId: guardian!.id, kind: "phone", tokenHash: hashToken(guardianToken) },
  ]);
  // Synthetic coordinates (central Krakow); not a real person's home.
  await db.insert(safeAreas).values({ seniorId: senior!.id, lat: 50.0614, lng: 19.9372, radiusM: 150 });
  await db.insert(contacts).values([
    { seniorId: senior!.id, name: "Marek (son)", phone: "+48 600 000 001", sortOrder: 0 },
    { seniorId: senior!.id, name: "Dr. Demo", phone: "+48 600 000 002", sortOrder: 1 },
  ]);
  await db.insert(medications).values({
    seniorId: senior!.id,
    name: "Demo Blood Pressure 5 mg (synthetic)",
    doseText: "1 tablet",
    barcode: "5900000000028",
    modelAssetKey: "pill-oval",
    times: ["08:00", "20:00"],
    timezone: "Europe/Warsaw",
  });
  console.log(JSON.stringify({ seniorId: senior!.id, guardianId: guardian!.id, seniorToken, guardianToken }, null, 2));
}
await close();
