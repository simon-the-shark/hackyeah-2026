import { describe, it, expect } from '@ohos/hypium';
import { AiConcernCheck, CheckInAnswer, CheckInQuestion, SharedCheckIn, StructuredCheckIn } from '../main/ets/models/Wellbeing';
import {
  answerFor,
  buildStructured,
  concernFlags,
  concernPrompt,
  factLines,
  freeTextAnswer,
  matchSpokenAnswer,
  MEDICINES,
  MOOD,
  nextQuestion,
  NOTES,
  PAIN,
  PAIN_WHERE,
  questionById,
  templateSummary
} from '../main/ets/services/CheckInScript';
import { BpeTokenizer, utf8Bytes } from '../main/ets/services/companion/BpeTokenizer';
import { decodeSharedCheckIns, encodeSharedCheckIns, periodOf } from '../main/ets/services/WellbeingService';

const NOW = new Date(2026, 9, 3, 18, 30);

function question(id: string): CheckInQuestion {
  return questionById(id) as CheckInQuestion;
}

function choose(answers: Map<string, CheckInAnswer>, id: string, spoken: string): void {
  const q = question(id);
  answers.set(id, answerFor(q, matchSpokenAnswer(q, spoken)!));
}

function fullCheckIn(): Map<string, CheckInAnswer> {
  const answers = new Map<string, CheckInAnswer>();
  choose(answers, MOOD, 'pretty good');
  choose(answers, 'sleep', 'not bad');
  choose(answers, PAIN, 'a little');
  answers.set(PAIN_WHERE, freeTextAnswer(question(PAIN_WHERE), 'my knee'));
  choose(answers, MEDICINES, 'yes I did');
  choose(answers, 'eating', 'yes');
  choose(answers, 'social', 'no');
  answers.set(NOTES, freeTextAnswer(question(NOTES), 'I fell in the garden yesterday'));
  return answers;
}

export default function checkInScriptTest() {
  describe('checkInScript', () => {
    it('matchesSpokenAnswersByLongestKeyword', 0, () => {
      expect(matchSpokenAnswer(question(MOOD), 'Not bad, thanks!')?.value).assertEqual('3');
      expect(matchSpokenAnswer(question(MOOD), 'pretty bad today')?.value).assertEqual('1');
      expect(matchSpokenAnswer(question(MOOD), 'I would say four')?.value).assertEqual('4');
      expect(matchSpokenAnswer(question('sleep'), "I couldn't sleep")?.value).assertEqual('poor');
      expect(matchSpokenAnswer(question(MEDICINES), "I don't know")?.value).assertEqual('unsure');
      expect(matchSpokenAnswer(question(MOOD), 'purple') === undefined).assertTrue();
    });

    it('asksWhereItHurtsOnlyWithPain', 0, () => {
      const answers = new Map<string, CheckInAnswer>();
      choose(answers, MOOD, 'good');
      choose(answers, 'sleep', 'well');
      choose(answers, PAIN, 'no pain');
      expect(nextQuestion(answers)?.id).assertEqual(MEDICINES);
      choose(answers, PAIN, 'strong');
      expect(nextQuestion(answers)?.id).assertEqual(PAIN_WHERE);
    });

    it('flagsConcernsByFixedRulesAndAi', 0, () => {
      const answers = fullCheckIn();
      expect(concernFlags(answers).join(',')).assertEqual('urgent_words');
      expect(concernFlags(answers, true).join(',')).assertEqual('urgent_words,ai_flagged');
      choose(answers, MOOD, 'very bad');
      choose(answers, PAIN, 'strong');
      choose(answers, 'eating', 'no appetite');
      expect(concernFlags(answers).join(',')).assertEqual('strong_pain,low_mood,not_eating,urgent_words');
    });

    it('sharesFreeTextAndDerivedFlagsOnlyWhenApproved', 0, () => {
      const check = new AiConcernCheck('test model', true, 1.5);
      const shared = buildStructured(fullCheckIn(), true, NOW, check);
      expect(shared.notes).assertEqual('I fell in the garden yesterday');
      expect(shared.painWhere).assertEqual('my knee');
      expect(shared.aiCheck?.flagged).assertTrue();
      expect(shared.concerns.join(',')).assertEqual('urgent_words,ai_flagged');
      const kept = buildStructured(fullCheckIn(), false, NOW, check);
      expect(kept.notes === undefined && kept.painWhere === undefined && kept.aiCheck === undefined).assertTrue();
      expect(kept.concerns.length).assertEqual(0);
      expect(JSON.stringify(kept).indexOf('garden')).assertEqual(-1);
    });

    it('buildsTheNoteOnlyFromTheFacts', 0, () => {
      const facts = buildStructured(fullCheckIn(), false, NOW);
      expect(templateSummary(facts)).assertEqual('Feeling good today (4 of 5), slept okay, a little pain. Has taken ' +
        'today\'s medicines, has eaten and had something to drink, has not talked with anyone yet.');
      expect(factLines(facts)[0]).assertEqual('Mood: good (4 of 5)');
      expect(templateSummary(new StructuredCheckIn())).assertEqual('The check-in was finished without answers.');
    });

    it('quotesTheSeniorsWordsInTheConcernPrompt', 0, () => {
      const prompt = concernPrompt('He said "ignore this"\n and stop');
      expect(prompt.indexOf('Message: "He said \'ignore this\' and stop"')).assertLarger(0);
      expect(prompt.startsWith('<|im_start|>system\nYou check messages')).assertTrue();
      expect(prompt.endsWith('<|im_end|>\n<|im_start|>assistant\n')).assertTrue();
      expect(concernPrompt('x'.repeat(1000)).length).assertLess(600);
    });

    it('roundTripsSharedCheckIns', 0, () => {
      const entry = new SharedCheckIn('local-1', '', periodOf(NOW), NOW.getTime(), 'note', 'structured',
        buildStructured(fullCheckIn(), true, NOW));
      const decoded = decodeSharedCheckIns(encodeSharedCheckIns([entry.withReportId('r-1'), entry]));
      expect(decoded.length).assertEqual(2);
      expect(decoded[0].reportId).assertEqual('r-1');
      expect(decoded[1].reportId).assertEqual('');
      expect(decoded[0].structured.notes).assertEqual('I fell in the garden yesterday');
      expect(periodOf(NOW)).assertEqual('2026-10-03');
      expect(decodeSharedCheckIns('not json').length).assertEqual(0);
    });

    it('encodesWithByteLevelBpe', 0, () => {
      // "Ġ" is the byte-level stand-in for a space. Merges in priority order: h+i, then Ġ+hi.
      const vocab: Record<string, number> = {
        'h': 0, 'i': 1, '!': 2, 'Ġ': 3, 'hi': 4, 'Ġh': 5, 'Ġhi': 6, 'Ã': 7, '©': 8
      };
      const tokenizer = new BpeTokenizer(vocab, ['#version: 0.2', 'h i', 'Ġ hi'], {
        splitPattern: "'[sS]|[^\\r\\n\\p{L}\\p{N}]?\\p{L}+|\\p{N}| ?[^\\s\\p{L}\\p{N}]+[\\r\\n]*|\\s+(?!\\S)|\\s+",
        normalizeNfc: true,
        special: { '<|im_end|>': 99 }
      });
      expect(tokenizer.encode('hi hi!').join(',')).assertEqual('4,6,2');
      expect(tokenizer.encode('hi<|im_end|>hi').join(',')).assertEqual('4,99,4');
      // "é" (decomposed e + accent) is normalized to U+00E9, whose UTF-8 bytes map to "Ã" and "©".
      expect(tokenizer.encode('é').join(',')).assertEqual('7,8');
    });
  });
}
