import alertLocationTest from './AlertLocation.test';
import contactFormTest from './ContactForm.test';
import contactListTest from './ContactList.test';
import localUnitTest from './LocalUnit.test';
import medicationDraftTest from './MedicationDraft.test';
import medicationScheduleTest from './MedicationSchedule.test';
import seniorLocationTest from './SeniorLocation.test';
import watchVitalsTest from './WatchVitals.test';

export default function testsuite() {
  alertLocationTest();
  contactFormTest();
  contactListTest();
  localUnitTest();
  medicationScheduleTest();
  medicationDraftTest();
  seniorLocationTest();
  watchVitalsTest();
}
