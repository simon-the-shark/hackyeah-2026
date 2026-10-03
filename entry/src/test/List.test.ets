import checkInScriptTest from './CheckInScript.test';
import contactFormTest from './ContactForm.test';
import contactListTest from './ContactList.test';
import localUnitTest from './LocalUnit.test';
import medicationDraftTest from './MedicationDraft.test';
import medicationScheduleTest from './MedicationSchedule.test';

export default function testsuite() {
  checkInScriptTest();
  contactFormTest();
  contactListTest();
  localUnitTest();
  medicationScheduleTest();
  medicationDraftTest();
}
