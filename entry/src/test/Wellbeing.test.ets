import { describe, it, expect } from '@ohos/hypium';
import {
  answersLabel,
  Attention,
  chatMessagesFrom,
  ChatRole,
  checkInStateFrom,
  durationLabel,
  guardianNamesText,
  RatingTone,
  ratingLabel,
  ratingTone,
  ReportTopic,
  reportSourceLabel,
  WellbeingReport,
  wellbeingReportFrom,
  wellbeingReportsFrom
} from '../main/ets/models/Wellbeing';

export default function wellbeingTest() {
  describe('wellbeing', () => {
    it('keepsOnlyMessagesItCanShow', 0, () => {
      const messages = chatMessagesFrom([
        { id: 'a', role: 'assistant', text: 'How did you sleep?', inputMode: null, createdAt: '2026-10-03T09:00:00Z' },
        { id: 'b', role: 'senior', text: 'Not well', inputMode: 'voice', safetyConcern: false },
        { id: 'c', role: 'system', text: 'hidden' },
        { role: 'senior', text: 'no id' }
      ]);
      expect(messages.length).assertEqual(2);
      expect(messages[1].role).assertEqual(ChatRole.Senior);
      expect(messages[1].voice).assertTrue();
      expect(messages[0].createdAt).assertEqual(Date.parse('2026-10-03T09:00:00Z'));
    });

    it('ignoresMessagesWithoutAnOpenSession', 0, () => {
      const state = checkInStateFrom({
        session: { id: 's1', status: 'finished' },
        messages: [{ id: 'a', role: 'assistant', text: 'Hello' }],
        assistant: { available: true, simulated: true, voice: false },
        guardians: [{ id: 'g', displayName: ' Marek ' }, { id: 'h', displayName: '' }]
      });
      expect(state.session === undefined).assertTrue();
      expect(state.messages.length).assertEqual(0);
      expect(state.assistant.simulated).assertTrue();
      expect(state.guardianNames.length).assertEqual(1);
      expect(state.guardianNames[0]).assertEqual('Marek');
    });

    it('readsAChatReportAndDefaultsMissingRatings', 0, () => {
      const report = wellbeingReportFrom({
        id: 'r1',
        createdAt: '2026-10-03T10:00:00Z',
        summary: ' Halina slept badly. ',
        source: 'ai',
        structured: {
          kind: 'wellbeing_chat',
          mood: 'okay',
          sleep: 'poor',
          concerns: ['Knee pain when walking', ' ', 'Slept badly'],
          attention: 'soon',
          attentionReason: 'New knee pain',
          startedAt: '2026-10-03T09:52:00Z',
          finishedAt: '2026-10-03T09:58:00Z',
          seniorMessages: 5,
          voiceMessages: 3,
          assistant: 'openai:gpt-6-luna'
        }
      }) as WellbeingReport;
      expect(report.summary).assertEqual('Halina slept badly.');
      expect(report.energy).assertEqual('unclear');
      expect(report.pain).assertEqual('unclear');
      expect(report.concerns.length).assertEqual(2);
      expect(report.attention).assertEqual(Attention.Soon);
      expect(durationLabel(report)).assertEqual('6 min');
      expect(answersLabel(report)).assertEqual('Spoke 3 times, typed twice');
      expect(reportSourceLabel(report)).assertEqual('Written by an AI assistant (gpt-6-luna)');
    });

    it('dropsReportsWithoutIdOrTimeAndSortsNewestFirst', 0, () => {
      const reports = wellbeingReportsFrom([
        { id: 'old', createdAt: '2026-10-01T10:00:00Z', source: 'structured' },
        { id: 'bad', createdAt: 'never' },
        { id: 'new', createdAt: '2026-10-03T10:00:00Z', source: 'simulated', structured: { attention: 'loud' } }
      ]);
      expect(reports.length).assertEqual(2);
      expect(reports[0].id).assertEqual('new');
      expect(reports[0].attention).assertEqual(Attention.None);
      expect(reportSourceLabel(reports[0])).assertEqual('Demo summary (scripted, not AI)');
    });

    it('saysRatingsInWords', 0, () => {
      expect(ratingLabel(ReportTopic.Pain, 'none')).assertEqual('No pain');
      expect(ratingLabel(ReportTopic.Pain, 'strong')).assertEqual('Strong pain');
      expect(ratingLabel(ReportTopic.Sleep, 'poor')).assertEqual('Poor');
      expect(ratingLabel(ReportTopic.Mood, 'unclear')).assertEqual('Not discussed');
      expect(ratingTone(ReportTopic.Pain, 'none')).assertEqual(RatingTone.Good);
      expect(ratingTone(ReportTopic.Mood, 'low')).assertEqual(RatingTone.Concern);
      expect(ratingTone(ReportTopic.Energy, 'whatever')).assertEqual(RatingTone.Unknown);
    });

    it('namesTheGuardians', 0, () => {
      expect(guardianNamesText([])).assertEqual('your guardian');
      expect(guardianNamesText(['Marek'])).assertEqual('Marek');
      expect(guardianNamesText(['Marek', 'Anna', 'Ewa'])).assertEqual('Marek, Anna and Ewa');
    });
  });
}
