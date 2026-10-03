import contactListTest from './ContactList.test';
import localUnitTest from './LocalUnit.test';
import medicationDraftTest from './MedicationDraft.test';
import medicationScheduleTest from './MedicationSchedule.test';

export default function testsuite() {
  contactListTest();
  localUnitTest();
  medicationScheduleTest();
  medicationDraftTest();
}
