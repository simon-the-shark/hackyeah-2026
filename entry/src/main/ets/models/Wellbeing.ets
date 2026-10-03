export enum QuestionKind {
  // Pick one of the options (tap, or say it).
  Choice,
  // Optional free text (type, or say it).
  FreeText
}

export class AnswerOption {
  readonly value: string;
  readonly label: string;
  // Words or phrases that select this option when spoken or typed; the longest match wins.
  readonly keywords: string[];
  // Scripted acknowledgement shown when no model reply is available.
  readonly reply: string;

  constructor(value: string, label: string, keywords: string[], reply: string) {
    this.value = value;
    this.label = label;
    this.keywords = keywords;
    this.reply = reply;
  }
}

export class CheckInQuestion {
  readonly id: string;
  readonly prompt: string;
  readonly kind: QuestionKind;
  readonly options: AnswerOption[];
  // Asked only when this returns true for the answers so far.
  readonly askIf: (answers: Map<string, CheckInAnswer>) => boolean;

  constructor(id: string, prompt: string, kind: QuestionKind, options: AnswerOption[],
    askIf: (answers: Map<string, CheckInAnswer>) => boolean = () => true) {
    this.id = id;
    this.prompt = prompt;
    this.kind = kind;
    this.options = options;
    this.askIf = askIf;
  }
}

export class CheckInAnswer {
  readonly questionId: string;
  // Option value for choice questions; the entered text for free-text questions ('' when skipped).
  readonly value: string;
  // What is shown back to the senior and guardian.
  readonly label: string;

  constructor(questionId: string, value: string, label: string) {
    this.questionId = questionId;
    this.value = value;
    this.label = label;
  }
}

// Result of the on-device model reading the senior's free text. Present only when the model ran.
export class AiConcernCheck {
  model: string;
  // The model answered "yes" to whether the text mentions a health worry.
  flagged: boolean;
  // logit("yes") - logit("no").
  score: number;

  constructor(model: string, flagged: boolean, score: number) {
    this.model = model;
    this.flagged = flagged;
    this.score = score;
  }
}

// The facts sent to the backend as `structured`. Absent fields were not answered (or, for notes,
// not approved for sharing); JSON.stringify leaves them out.
export class StructuredCheckIn {
  schemaVersion: number = 1;
  mood?: number;
  moodLabel?: string;
  sleep?: string;
  pain?: string;
  painWhere?: string;
  medicines?: string;
  eating?: string;
  social?: string;
  notes?: string;
  concerns: string[] = [];
  aiCheck?: AiConcernCheck;
  completedAt: string = '';
}

export enum DeliveryState {
  Sent,
  // Saved on this phone; sent automatically when the server can be reached.
  Waiting
}

// A check-in the senior chose to share, kept on this phone so it can be withdrawn later.
export class SharedCheckIn {
  readonly localId: string;
  // Backend report id; empty while the report is waiting to be delivered.
  readonly reportId: string;
  readonly period: string;
  readonly sharedAt: number;
  readonly summary: string;
  readonly source: string;
  readonly structured: StructuredCheckIn;

  constructor(localId: string, reportId: string, period: string, sharedAt: number, summary: string, source: string,
    structured: StructuredCheckIn) {
    this.localId = localId;
    this.reportId = reportId;
    this.period = period;
    this.sharedAt = sharedAt;
    this.summary = summary;
    this.source = source;
    this.structured = structured;
  }

  get delivery(): DeliveryState {
    return this.reportId.length > 0 ? DeliveryState.Sent : DeliveryState.Waiting;
  }

  withReportId(reportId: string): SharedCheckIn {
    return new SharedCheckIn(this.localId, reportId, this.period, this.sharedAt, this.summary, this.source,
      this.structured);
  }
}

// A report as the guardian receives it from the backend.
export class GuardianReport {
  readonly id: string;
  readonly createdAt: number;
  readonly period: string;
  readonly summary: string;
  readonly source: string;
  readonly facts: StructuredCheckIn;

  constructor(id: string, createdAt: number, period: string, summary: string, source: string,
    facts: StructuredCheckIn) {
    this.id = id;
    this.createdAt = createdAt;
    this.period = period;
    this.summary = summary;
    this.source = source;
    this.facts = facts;
  }
}
