import {
  AiConcernCheck,
  AnswerOption,
  CheckInAnswer,
  CheckInQuestion,
  QuestionKind,
  StructuredCheckIn
} from '../models/Wellbeing';

// The wellbeing check-in is a fixed script so every report has the same comparable facts. The on-device model
// only reads the senior's free text for possible health worries; it never writes what the guardian sees and
// never decides what is asked or shared.

export const MOOD = 'mood';
export const SLEEP = 'sleep';
export const PAIN = 'pain';
export const PAIN_WHERE = 'painWhere';
export const MEDICINES = 'medicines';
export const EATING = 'eating';
export const SOCIAL = 'social';
export const NOTES = 'notes';

const YES = ['yes', 'yeah', 'yep', 'sure', 'i did', 'i have', 'of course', 'already'];
const NO = ['no', 'nope', 'not yet', 'i did not', "i didn't", 'i have not', "i haven't", 'nobody', 'no one'];

function answered(id: string, isValue: (value: string) => boolean): (answers: Map<string, CheckInAnswer>) => boolean {
  return (answers: Map<string, CheckInAnswer>) => {
    const answer = answers.get(id);
    return answer !== undefined && isValue(answer.value);
  };
}

export const CHECK_IN_QUESTIONS: CheckInQuestion[] = [
  new CheckInQuestion(MOOD, 'How are you feeling today?', QuestionKind.Choice, [
    new AnswerOption('5', 'Very good', ['very good', 'great', 'excellent', 'wonderful', 'fantastic', 'five', '5'],
      'That is lovely to hear!'),
    new AnswerOption('4', 'Good', ['good', 'fine', 'well', 'pretty good', 'four', '4'], 'I am glad you are doing well.'),
    new AnswerOption('3', 'Okay', ['okay', 'ok', 'so so', 'so-so', 'alright', 'not bad', 'average', 'three', '3'],
      'Thank you for telling me.'),
    new AnswerOption('2', 'Low', ['low', 'not good', 'not great', 'not well', 'sad', 'tired', 'lonely', 'two', '2'],
      'I am sorry you are feeling low. Thank you for sharing that with me.'),
    new AnswerOption('1', 'Very bad', ['very bad', 'bad', 'terrible', 'awful', 'horrible', 'one', '1'],
      'I am sorry today is hard. Your family will see this, and you can call them any time.')
  ]),
  new CheckInQuestion(SLEEP, 'How did you sleep last night?', QuestionKind.Choice, [
    new AnswerOption('good', 'Slept well', ['well', 'good', 'great', 'fine', 'like a baby', 'deeply'],
      'A good night makes a difference.'),
    new AnswerOption('ok', 'Slept okay', ['okay', 'ok', 'so so', 'alright', 'not bad', 'average'], 'Thank you.'),
    new AnswerOption('poor', 'Slept badly', ['badly', 'bad', 'poorly', 'poor', 'not well', 'not good', 'awake',
      'could not sleep', "couldn't sleep", 'terrible'], 'I am sorry you had a rough night.')
  ]),
  new CheckInQuestion(PAIN, 'Do you have any pain or discomfort today?', QuestionKind.Choice, [
    new AnswerOption('none', 'No pain', ['no', 'none', 'no pain', 'nothing', 'not at all', 'i am fine', "i'm fine"],
      'Good to hear.'),
    new AnswerOption('mild', 'A little', ['a little', 'a bit', 'little', 'mild', 'slight', 'some'],
      'Thank you for letting me know.'),
    new AnswerOption('strong', 'Strong pain', ['strong', 'a lot', 'severe', 'very', 'bad', 'really hurts'],
      'I am sorry you are in pain. Please consider calling your family or your doctor.')
  ]),
  new CheckInQuestion(PAIN_WHERE, 'Where do you feel it?', QuestionKind.FreeText, [],
    answered(PAIN, (value: string) => value !== 'none')),
  new CheckInQuestion(MEDICINES, 'Have you taken your medicines today?', QuestionKind.Choice, [
    new AnswerOption('yes', 'Yes', YES, 'Well done.'),
    new AnswerOption('no', 'Not yet', NO, 'Your Medication tab shows what is due.'),
    new AnswerOption('unsure', 'Not sure', ['not sure', 'i do not know', "i don't know", 'maybe', 'forgot',
      'cannot remember', "can't remember"], 'Your Medication tab shows what you have marked as taken.')
  ]),
  new CheckInQuestion(EATING, 'Have you eaten and had enough to drink today?', QuestionKind.Choice, [
    new AnswerOption('yes', 'Yes', YES, 'Good.'),
    new AnswerOption('no', 'Not really', NO.concat(['not really', 'not much', 'no appetite']),
      'Try to have something small and a glass of water when you can.')
  ]),
  new CheckInQuestion(SOCIAL, 'Have you talked with anyone today?', QuestionKind.Choice, [
    new AnswerOption('yes', 'Yes', YES, 'That is nice.'),
    new AnswerOption('no', 'Not yet', NO, 'Your Contacts tab can call someone with one tap.')
  ]),
  new CheckInQuestion(NOTES, 'Is there anything else you would like to tell your family?', QuestionKind.FreeText, [])
];

export function questionById(id: string): CheckInQuestion | undefined {
  return CHECK_IN_QUESTIONS.find((question: CheckInQuestion) => question.id === id);
}

// The next question to ask, or undefined when the check-in is complete.
export function nextQuestion(answers: Map<string, CheckInAnswer>): CheckInQuestion | undefined {
  return CHECK_IN_QUESTIONS.find((question: CheckInQuestion) => !answers.has(question.id) &&
  question.askIf(answers));
}

function normalize(text: string): string {
  return ` ${text.toLowerCase().replace(/[^\p{L}\p{N}' -]/gu, ' ').replace(/\s+/g, ' ').trim()} `;
}

// Maps a spoken or typed reply to an option. The longest matching keyword wins, so "not bad" beats "bad".
export function matchSpokenAnswer(question: CheckInQuestion, transcript: string): AnswerOption | undefined {
  const text = normalize(transcript);
  let best: AnswerOption | undefined = undefined;
  let bestLength = 0;
  question.options.forEach((option: AnswerOption) => {
    option.keywords.forEach((keyword: string) => {
      if (keyword.length > bestLength && text.indexOf(` ${keyword} `) >= 0) {
        best = option;
        bestLength = keyword.length;
      }
    });
  });
  return best;
}

export function answerFor(question: CheckInQuestion, option: AnswerOption): CheckInAnswer {
  return new CheckInAnswer(question.id, option.value, option.label);
}

export function freeTextAnswer(question: CheckInQuestion, text: string): CheckInAnswer {
  const trimmed = text.trim();
  return new CheckInAnswer(question.id, trimmed, trimmed.length > 0 ? trimmed : 'Skipped');
}

// Scripted acknowledgement for an answer; used when the model is unavailable or its reply is rejected.
export function scriptedReply(question: CheckInQuestion, answer: CheckInAnswer): string {
  const option = question.options.find((candidate: AnswerOption) => candidate.value === answer.value);
  if (option !== undefined) {
    return option.reply;
  }
  return answer.value.length > 0 ? 'Thank you for telling me.' : 'That is fine.';
}

const URGENT_WORDS = ['fell', 'fall', 'fallen', 'chest', 'breath', 'breathe', 'faint', 'fainted', 'dizzy',
  'bleeding', 'blood', 'cannot move', "can't move", 'emergency', 'help me'];

export const CONCERN_LABELS: Record<string, string> = {
  'strong_pain': 'Strong pain',
  'low_mood': 'Low mood',
  'not_eating': 'Not eating or drinking',
  'urgent_words': 'Mentioned a fall, chest pain, breathing or dizziness',
  'ai_flagged': 'On-device AI noticed a possible health worry in what was written'
};

// Fixed rules, plus the on-device model's reading of free text when it ran. A concern only suggests calling
// someone; nothing is sent automatically.
export function concernFlags(answers: Map<string, CheckInAnswer>, aiFlagged: boolean = false): string[] {
  const flags: string[] = [];
  const value = (id: string): string => answers.get(id)?.value ?? '';
  if (value(PAIN) === 'strong') {
    flags.push('strong_pain');
  }
  const mood = Number.parseInt(value(MOOD));
  if (!Number.isNaN(mood) && mood <= 2) {
    flags.push('low_mood');
  }
  if (value(EATING) === 'no') {
    flags.push('not_eating');
  }
  const text = normalize(`${value(PAIN_WHERE)} ${value(NOTES)}`);
  if (URGENT_WORDS.some((word: string) => text.indexOf(` ${word} `) >= 0)) {
    flags.push('urgent_words');
  }
  if (aiFlagged) {
    flags.push('ai_flagged');
  }
  return flags;
}

// The facts to share. Free text (where it hurts, notes) and anything derived from it (keyword and AI flags) is
// included only when the senior approves it.
export function buildStructured(answers: Map<string, CheckInAnswer>, includeNotes: boolean, completedAt: Date,
  aiCheck?: AiConcernCheck): StructuredCheckIn {
  const facts = new StructuredCheckIn();
  const get = (id: string): CheckInAnswer | undefined => answers.get(id);
  const mood = get(MOOD);
  if (mood !== undefined) {
    facts.mood = Number.parseInt(mood.value);
    facts.moodLabel = mood.label;
  }
  facts.sleep = get(SLEEP)?.value;
  facts.pain = get(PAIN)?.value;
  facts.medicines = get(MEDICINES)?.value;
  facts.eating = get(EATING)?.value;
  facts.social = get(SOCIAL)?.value;
  if (includeNotes) {
    const where = get(PAIN_WHERE)?.value ?? '';
    const notes = get(NOTES)?.value ?? '';
    facts.painWhere = where.length > 0 ? where : undefined;
    facts.notes = notes.length > 0 ? notes : undefined;
  }
  facts.concerns = concernFlags(answers, aiCheck?.flagged ?? false)
    .filter((flag: string) => includeNotes || (flag !== 'urgent_words' && flag !== 'ai_flagged'));
  if (includeNotes && aiCheck !== undefined) {
    facts.aiCheck = aiCheck;
  }
  facts.completedAt = completedAt.toISOString();
  return facts;
}

function sleepText(value: string): string {
  return value === 'good' ? 'slept well' : value === 'ok' ? 'slept okay' : 'slept badly';
}

function painText(facts: StructuredCheckIn): string {
  const where = facts.painWhere !== undefined ? ` (${facts.painWhere})` : '';
  return facts.pain === 'none' ? 'no pain' : facts.pain === 'mild' ? `a little pain${where}` : `strong pain${where}`;
}

// One fact per line, in plain words. Used for the model prompt and for the guardian's fact list.
export function factLines(facts: StructuredCheckIn): string[] {
  const lines: string[] = [];
  if (facts.mood !== undefined && !Number.isNaN(facts.mood)) {
    lines.push(`Mood: ${(facts.moodLabel ?? '').toLowerCase()} (${facts.mood} of 5)`);
  }
  if (facts.sleep !== undefined) {
    lines.push(`Sleep: ${sleepText(facts.sleep)}`);
  }
  if (facts.pain !== undefined) {
    lines.push(`Pain: ${painText(facts)}`);
  }
  if (facts.medicines !== undefined) {
    lines.push(`Medicines today: ${facts.medicines === 'yes' ? 'taken' : facts.medicines === 'no' ? 'not yet' :
      'not sure'}`);
  }
  if (facts.eating !== undefined) {
    lines.push(`Eating and drinking: ${facts.eating === 'yes' ? 'yes' : 'not really'}`);
  }
  if (facts.social !== undefined) {
    lines.push(`Talked with someone: ${facts.social === 'yes' ? 'yes' : 'not yet'}`);
  }
  return lines;
}

function capitalize(text: string): string {
  return text.length > 0 ? text.charAt(0).toUpperCase() + text.slice(1) : text;
}

// Factual note for the guardian, built only from the answers by fixed templates (no model involved).
export function templateSummary(facts: StructuredCheckIn): string {
  const parts: string[] = [];
  if (facts.mood !== undefined && !Number.isNaN(facts.mood)) {
    parts.push(`Feeling ${(facts.moodLabel ?? '').toLowerCase()} today (${facts.mood} of 5)`);
  }
  if (facts.sleep !== undefined) {
    parts.push(sleepText(facts.sleep));
  }
  if (facts.pain !== undefined) {
    parts.push(painText(facts));
  }
  const sentences: string[] = [];
  if (parts.length > 0) {
    sentences.push(`${capitalize(parts.join(', '))}.`);
  }
  const daily: string[] = [];
  if (facts.medicines !== undefined) {
    daily.push(facts.medicines === 'yes' ? 'has taken today\'s medicines' : facts.medicines === 'no' ?
      'has not taken today\'s medicines yet' : 'is not sure about today\'s medicines');
  }
  if (facts.eating !== undefined) {
    daily.push(facts.eating === 'yes' ? 'has eaten and had something to drink' : 'has not eaten or drunk much');
  }
  if (facts.social !== undefined) {
    daily.push(facts.social === 'yes' ? 'has talked with someone' : 'has not talked with anyone yet');
  }
  if (daily.length > 0) {
    sentences.push(`${capitalize(daily.join(', '))}.`);
  }
  if (facts.notes !== undefined) {
    sentences.push(`Note: "${facts.notes}"`);
  }
  if (sentences.length === 0) {
    return 'The check-in was finished without answers.';
  }
  return sentences.join(' ');
}

// Keep in sync with SYSTEM / QUESTION in tools/companion-model/export_classifier.py: the model was checked
// with exactly this wording.
export const CONCERN_SYSTEM_PROMPT = 'You check messages from an older person for health worries. Answer only yes or no.';
export const CONCERN_QUESTION = 'Does this message mention pain, a fall, feeling unwell, not eating, or loneliness?';
// Longer messages are cut so the prompt fits the model's fixed 128-token window.
export const CONCERN_MESSAGE_MAX_CHARS = 240;

// The senior's words are quoted and labelled as a message to check, not instructions to follow.
export function concernPrompt(text: string): string {
  const message = text.replace(/\s+/g, ' ').trim().slice(0, CONCERN_MESSAGE_MAX_CHARS).replace(/"/g, '\'');
  return `<|im_start|>system\n${CONCERN_SYSTEM_PROMPT}<|im_end|>\n<|im_start|>user\nMessage: "${message}"\n` +
    `${CONCERN_QUESTION}<|im_end|>\n<|im_start|>assistant\n`;
}

// The free text the senior wrote in this check-in (where it hurts, notes), for the on-device check.
export function freeTextOf(answers: Map<string, CheckInAnswer>): string {
  return [answers.get(PAIN_WHERE)?.value ?? '', answers.get(NOTES)?.value ?? '']
    .filter((text: string) => text.length > 0).join('. ');
}
