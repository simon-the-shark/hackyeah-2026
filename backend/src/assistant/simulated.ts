import { guardianPhrase } from "./prompts.js";
import {
  AssistantError,
  type Assistant,
  type ChatContext,
  type ChatReply,
  type ChatTurn,
  type WellbeingSummary,
} from "./provider.js";

/** Matched in lower case; English and Polish, since the demo is run in both. */
const DANGER = /\b(fell|fallen|can'?t get up|chest|breath|stroke|help me|emergency|kill myself|lost)\b|upad|ból w klatce|duszno|nie mogę wstać|pomocy|zgubił/;
const GOODBYE = /\b(bye|goodbye|stop|that'?s all|nothing else)\b|do widzenia|pa pa|koniec|to wszystko/;
const NEGATIVE = /\b(bad|sad|low|lonely|tired|poor|terrible|awful|not (good|well|great))\b|źle|smutn|samotn|zmęczon|słabo|kiepsko/;
const MILD = /\b(okay|ok|so-so|a bit|a little|fine)\b|trochę|tak sobie|w porządku/;
const POSITIVE = /\b(good|great|well|happy|wonderful)\b|dobrze|świetnie|super/;
const NO = /^(no|nope|nothing|none|nie|nic)\b/;
const HURTS = /\b(hurts?|pain|aches?|sore)\b|boli|ból/;

const QUESTIONS = [
  "How did you sleep last night?",
  "Do you have any pain or discomfort today?",
  "Is there anything that worries you, or anything you would like your family to know?",
];

type Rating = "positive" | "mild" | "negative" | "unclear";

function rate(text: string | undefined): Rating {
  if (text === undefined) return "unclear";
  const t = text.toLowerCase();
  if (NEGATIVE.test(t)) return "negative";
  if (MILD.test(t)) return "mild";
  if (POSITIVE.test(t) || NO.test(t.trim())) return "positive";
  return "unclear";
}

/** Answer to "Do you have any pain or discomfort today?". */
function painRating(text: string | undefined): WellbeingSummary["pain"] {
  if (text === undefined) return "unclear";
  if (NO.test(text)) return "none";
  if (HURTS.test(text) || NEGATIVE.test(text)) return MILD.test(text) ? "mild" : "strong";
  return "unclear";
}

/**
 * Scripted check-in for development and demos without an OpenAI key (ASSISTANT_PROVIDER=simulated).
 * It asks fixed questions and summarises with keyword rules; it is not AI, and every report it makes
 * says so. It has no voice.
 */
export class SimulatedAssistant implements Assistant {
  readonly name = "simulated";
  readonly simulated = true;
  readonly voice = false;

  async reply(ctx: ChatContext, history: ChatTurn[]): Promise<ChatReply> {
    const answers = history.filter((t) => t.role === "senior");
    if (answers.length === 0) {
      return {
        reply: `Hello ${ctx.seniorName}! This is your short daily check-in. How are you feeling today?`,
        suggestFinish: false,
        safetyConcern: false,
      };
    }
    const last = answers[answers.length - 1]!.text.toLowerCase();
    if (DANGER.test(last)) {
      return {
        reply: "That sounds serious. Please press the red SOS button in Carely now, or call 112.",
        suggestFinish: false,
        safetyConcern: true,
      };
    }
    const question = QUESTIONS[answers.length - 1];
    if (question === undefined || GOODBYE.test(last)) {
      return {
        reply: `Thank you for talking with me, ${ctx.seniorName}. I will send a short summary to ${guardianPhrase(ctx.guardianNames)}. Take care!`,
        suggestFinish: true,
        safetyConcern: false,
      };
    }
    return { reply: `Thank you for telling me. ${question}`, suggestFinish: false, safetyConcern: false };
  }

  async summarize(ctx: ChatContext, history: ChatTurn[]): Promise<WellbeingSummary> {
    const answers = history.filter((t) => t.role === "senior").map((t) => t.text);
    const [moodAnswer, sleepAnswer, painAnswer, worryAnswer] = answers;
    const mood = rate(moodAnswer);
    const sleep = rate(sleepAnswer);
    const painText = painAnswer?.toLowerCase().trim();
    const danger = answers.some((a) => DANGER.test(a.toLowerCase()));
    const worry = worryAnswer?.trim();
    const concerns = worry && !NO.test(worry.toLowerCase()) ? [worry.slice(0, 200)] : [];
    const result: WellbeingSummary = {
      mood: mood === "positive" ? "good" : mood === "mild" ? "okay" : mood === "negative" ? "low" : "unclear",
      energy: "unclear",
      sleep: sleep === "positive" ? "good" : sleep === "mild" ? "okay" : sleep === "negative" ? "poor" : "unclear",
      pain: painRating(painText),
      concerns,
      attention: "none",
      attentionReason: null,
      summary: "",
      language: null,
    };
    if (danger) {
      result.attention = "urgent";
      result.attentionReason = "The senior used words that may describe an emergency.";
    } else if (result.pain === "strong" || result.mood === "low") {
      result.attention = "soon";
      result.attentionReason = "The senior reported pain or a low mood.";
    }
    result.summary =
      `Demo summary (scripted, not AI): ${ctx.seniorName} answered ${answers.length} ` +
      `question${answers.length === 1 ? "" : "s"}. Mood: ${result.mood}; sleep: ${result.sleep}; pain: ${result.pain}.`;
    return result;
  }

  async transcribe(): Promise<string> {
    throw new AssistantError("The simulated assistant cannot transcribe speech");
  }

  async speak(): Promise<Uint8Array> {
    throw new AssistantError("The simulated assistant has no voice");
  }
}
