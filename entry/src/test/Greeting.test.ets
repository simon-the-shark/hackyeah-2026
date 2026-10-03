import { describe, it, expect } from '@ohos/hypium';
import { greeting } from '../main/ets/models/Greeting';

function at(hour: number): Date {
  return new Date(2026, 9, 3, hour, 30);
}

export default function greetingTest() {
  describe('greeting', () => {
    it('follows the time of day', 0, () => {
      expect(greeting('Halina', at(8))).assertEqual('Good morning, Halina');
      expect(greeting('Halina', at(14))).assertEqual('Good afternoon, Halina');
      expect(greeting('Halina', at(21))).assertEqual('Good evening, Halina');
      expect(greeting('Halina', at(2))).assertEqual('Good evening, Halina');
    });

    it('uses only the first name', 0, () => {
      expect(greeting('  Halina Nowak ', at(8))).assertEqual('Good morning, Halina');
    });

    it('omits a missing name', 0, () => {
      expect(greeting('', at(8))).assertEqual('Good morning');
      expect(greeting('   ', at(14))).assertEqual('Good afternoon');
    });
  });
}
