import localUnitTest from './LocalUnit.test';
import medicationDraftTest from './MedicationDraft.test';
import medicationScheduleTest from './MedicationSchedule.test';

export default function testsuite() {
  localUnitTest();
  medicationScheduleTest();
  medicationDraftTest();
}
