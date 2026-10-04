import alertLocationTest from './AlertLocation.test';
import careOverviewTest from './CareOverview.test';
import contactFormTest from './ContactForm.test';
import contactListTest from './ContactList.test';
import deliveryTest from './Delivery.test';
import greetingTest from './Greeting.test';
import geofenceTrackerTest from './GeofenceTracker.test';
import localUnitTest from './LocalUnit.test';
import medicationDraftTest from './MedicationDraft.test';
import medicationScheduleTest from './MedicationSchedule.test';
import pcmAudioTest from './PcmAudio.test';
import seniorLocationTest from './SeniorLocation.test';
import watchVitalsTest from './WatchVitals.test';
import wellbeingTest from './Wellbeing.test';

export default function testsuite() {
  alertLocationTest();
  careOverviewTest();
  contactFormTest();
  contactListTest();
  deliveryTest();
  greetingTest();
  geofenceTrackerTest();
  localUnitTest();
  medicationScheduleTest();
  medicationDraftTest();
  pcmAudioTest();
  seniorLocationTest();
  watchVitalsTest();
  wellbeingTest();
}
