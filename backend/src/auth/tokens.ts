import { createHash, randomBytes, randomInt } from "node:crypto";

export function generateToken(): string {
  return randomBytes(32).toString("base64url");
}

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export function generatePairingCode(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}
