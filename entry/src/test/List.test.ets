import localUnitTest from './LocalUnit.test';
import medicationScheduleTest from './MedicationSchedule.test';

export default function testsuite() {
  localUnitTest();
  medicationScheduleTest();
}
