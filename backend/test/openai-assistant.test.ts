import { describe, expect, it } from "vitest";
import { OpenAiAssistant } from "../src/assistant/openai.js";
import { AssistantError, type ChatContext } from "../src/assistant/provider.js";

const ctx: ChatContext = { seniorName: "Halina", guardianNames: ["Marek", "Anna"], language: "pl", localTime: "Saturday 14:00" };
const opts = { apiKey: "test-key", chatModel: "gpt-6-luna", transcribeModel: "gpt-transcribe", ttsModel: "gpt-4o-mini-tts", ttsVoice: "marin" };

type Captured = { url: string; init: RequestInit };

/** OpenAI stand-in: records requests and answers with the queued responses. */
function stub(...responses: (Response | Error)[]) {
  const requests: Captured[] = [];
  const fetchImpl = (async (url: string | URL | Request, init?: RequestInit) => {
    requests.push({ url: String(url), init: init ?? {} });
    const next = responses.shift();
    if (!next) throw new Error("no stubbed response");
    if (next instanceof Error) throw next;
    return next;
  }) as typeof fetch;
  return { assistant: new OpenAiAssistant(opts, fetchImpl), requests };
}

const completed = (payload: unknown) =>
  Response.json({
    status: "completed",
    output: [
      { type: "reasoning", summary: [] },
      { type: "message", content: [{ type: "output_text", text: JSON.stringify(payload) }] },
    ],
  });

describe("OpenAI assistant", () => {
  it("asks the Responses API for a strict JSON reply without storing it", async () => {
    const { assistant, requests } = stub(completed({ reply: "Jak spałaś?", suggestFinish: false, safetyConcern: false }));
    const reply = await assistant.reply(ctx, [
      { role: "assistant", text: "Dzień dobry Halino! Jak się czujesz?" },
      { role: "senior", text: "Dobrze" },
    ]);
    expect(reply).toEqual({ reply: "Jak spałaś?", suggestFinish: false, safetyConcern: false });
    expect(assistant.name).toBe("openai/gpt-6-luna");

    const [req] = requests;
    expect(req!.url).toBe("https://api.openai.com/v1/responses");
    expect(new Headers(req!.init.headers).get("authorization")).toBe("Bearer test-key");
    const body = JSON.parse(req!.init.body as string);
    expect(body).toMatchObject({
      model: "gpt-6-luna",
      store: false,
      reasoning: { effort: "low" },
      text: { format: { type: "json_schema", name: "checkin_reply", strict: true } },
      input: [
        { role: "assistant", content: "Dzień dobry Halino! Jak się czujesz?" },
        { role: "user", content: "Dobrze" },
      ],
    });
    expect(body.instructions).toContain("Halina");
    expect(body.instructions).toContain("Marek and Anna");
    expect(body.instructions).toContain("112");
    expect(body.instructions).toContain("Saturday 14:00");
  });

  it("opens the check-in with a developer note instead of senior words", async () => {
    const { assistant, requests } = stub(completed({ reply: "Dzień dobry!", suggestFinish: false, safetyConcern: false }));
    await assistant.reply(ctx, []);
    const body = JSON.parse(requests[0]!.init.body as string);
    expect(body.input).toEqual([{ role: "developer", content: expect.stringContaining("has just opened the daily check-in") }]);
  });

  it("summarises the transcript as data with medium effort and validates the result", async () => {
    const summary = {
      mood: "good",
      energy: "okay",
      sleep: "poor",
      pain: "mild",
      concerns: ["Kolano boli", "", "a", "b", "c", "d", "e"],
      attention: "none",
      attentionReason: null,
      summary: "Halina czuje się dobrze.",
      language: "pl",
    };
    const { assistant, requests } = stub(completed(summary));
    const result = await assistant.summarize(ctx, [{ role: "senior", text: "Dobrze, tylko kolano boli" }]);
    expect(result.concerns).toEqual(["Kolano boli", "a", "b", "c", "d"]);
    const body = JSON.parse(requests[0]!.init.body as string);
    expect(body).toMatchObject({ reasoning: { effort: "medium" }, text: { format: { name: "checkin_summary", strict: true } } });
    expect(body.input).toEqual([{ role: "user", content: expect.stringContaining("Halina: Dobrze, tylko kolano boli") }]);
  });

  it("turns every failure into AssistantError", async () => {
    const refusal = Response.json({ status: "completed", output: [{ type: "message", content: [{ type: "refusal", refusal: "No" }] }] });
    const incomplete = Response.json({ status: "incomplete", output: [] });
    const wrongShape = completed({ reply: "", suggestFinish: false, safetyConcern: false });
    const notJson = Response.json({ status: "completed", output: [{ type: "message", content: [{ type: "output_text", text: "hi" }] }] });
    const http = Response.json({ error: { code: "rate_limit_exceeded" } }, { status: 429 });
    for (const response of [refusal, incomplete, wrongShape, notJson, http, new TypeError("network down")]) {
      const { assistant } = stub(response);
      await expect(assistant.reply(ctx, [])).rejects.toBeInstanceOf(AssistantError);
    }
  });

  it("transcribes an m4a upload", async () => {
    const { assistant, requests } = stub(Response.json({ text: "  Spałam źle  " }));
    expect(await assistant.transcribe(new Uint8Array([1, 2, 3]), "m4a")).toBe("Spałam źle");
    const [req] = requests;
    expect(req!.url).toBe("https://api.openai.com/v1/audio/transcriptions");
    const form = req!.init.body as FormData;
    const file = form.get("file") as File;
    expect(file.name).toBe("speech.m4a");
    expect(file.type).toBe("audio/mp4");
    expect(file.size).toBe(3);
    expect(form.get("model")).toBe("gpt-transcribe");
  });

  it("speaks with the configured voice as MP3", async () => {
    const { assistant, requests } = stub(new Response(new Uint8Array([9, 8, 7]), { headers: { "Content-Type": "audio/mpeg" } }));
    expect(Array.from(await assistant.speak("Jak spałaś?"))).toEqual([9, 8, 7]);
    const body = JSON.parse(requests[0]!.init.body as string);
    expect(body).toMatchObject({ model: "gpt-4o-mini-tts", voice: "marin", input: "Jak spałaś?", response_format: "mp3" });
    expect(body.instructions).toContain("older listener");
  });
});
