import { constants, createSign } from "node:crypto";
import { readFileSync } from "node:fs";
import type { PushMessage, PushProvider } from "./provider.js";

const TOKEN_AUDIENCE = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
const SUCCESS_CODE = "80000000";

type KeyFile = { project_id: string; key_id: string; sub_account: string; private_key: string };

const b64url = (v: string | Buffer) => Buffer.from(v).toString("base64url");

/**
 * HarmonyOS Push Kit REST v3 sender (service-account JWT, PS256).
 * Contract taken from public Huawei docs/community write-ups; not yet verified
 * against a live project. Credentials come only from the key file at keyFilePath.
 */
export class HarmonyPushKitProvider implements PushProvider {
  readonly name = "pushkit";
  private readonly key: KeyFile;
  private jwt?: { value: string; expiresAt: number };

  constructor(
    keyFilePath: string,
    private readonly fetchFn: typeof fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {
    this.key = JSON.parse(readFileSync(keyFilePath, "utf8")) as KeyFile;
    for (const f of ["project_id", "key_id", "sub_account", "private_key"] as const) {
      if (!this.key[f]) throw new Error(`Push Kit key file is missing "${f}"`);
    }
  }

  private authToken(): string {
    const nowSec = Math.floor(this.now() / 1000);
    if (this.jwt && this.jwt.expiresAt - 60 > nowSec) return this.jwt.value;
    const header = b64url(JSON.stringify({ alg: "PS256", typ: "JWT", kid: this.key.key_id }));
    const payload = b64url(
      JSON.stringify({ iss: this.key.sub_account, aud: TOKEN_AUDIENCE, iat: nowSec, exp: nowSec + 3600 }),
    );
    const signature = createSign("sha256")
      .update(`${header}.${payload}`)
      .sign({
        key: this.key.private_key,
        padding: constants.RSA_PKCS1_PSS_PADDING,
        saltLength: constants.RSA_PSS_SALTLEN_DIGEST,
      });
    const value = `${header}.${payload}.${b64url(signature)}`;
    this.jwt = { value, expiresAt: nowSec + 3600 };
    return value;
  }

  async send(tokens: string[], message: PushMessage) {
    if (tokens.length === 0) return "failed" as const;
    try {
      const res = await this.fetchFn(`https://push-api.cloud.huawei.com/v3/${this.key.project_id}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.authToken()}`,
          "Content-Type": "application/json; charset=UTF-8",
          "push-type": "0",
        },
        body: JSON.stringify({
          payload: {
            notification: {
              category: "IM",
              title: message.title,
              body: message.body,
              clickAction: { actionType: 0 },
            },
          },
          target: { token: tokens },
        }),
      });
      const json = (await res.json().catch(() => ({}))) as { code?: string; msg?: string };
      if (res.ok && json.code === SUCCESS_CODE) return "sent" as const;
      console.error(`[push:pushkit] send failed status=${res.status} code=${json.code} msg=${json.msg}`);
      return "failed" as const;
    } catch (err) {
      console.error("[push:pushkit] send error", err instanceof Error ? err.message : err);
      return "failed" as const;
    }
  }
}
