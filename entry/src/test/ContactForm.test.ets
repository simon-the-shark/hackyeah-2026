import { describe, it, expect } from '@ohos/hypium';
import { Contact } from '../main/ets/models/Contact';
import {
  contactNameError,
  contactPhoneError,
  nextSortOrder,
  normalizePhone
} from '../main/ets/services/ContactForm';

export default function contactFormTest() {
  describe('contactForm', () => {
    it('requiresANameWithinTheBackendLimit', 0, () => {
      expect(contactNameError('   ')).assertEqual('Enter a name.');
      expect(contactNameError(' Anna Kowalska ')).assertEqual('');
      expect(contactNameError('a'.repeat(81)) !== '').assertTrue();
      expect(contactNameError('a'.repeat(80))).assertEqual('');
    });

    it('acceptsTheBackendPhoneFormatOnly', 0, () => {
      expect(contactPhoneError('')).assertEqual('Enter a phone number.');
      expect(contactPhoneError('+48 600 100 200')).assertEqual('');
      expect(contactPhoneError('(12) 345-67-89')).assertEqual('');
      expect(contactPhoneError('12') !== '').assertTrue();
      expect(contactPhoneError('600.100.200') !== '').assertTrue();
      expect(contactPhoneError('48+600') !== '').assertTrue();
      expect(contactPhoneError('1'.repeat(21)) !== '').assertTrue();
    });

    it('normalizesAddressBookNumbers', 0, () => {
      expect(normalizePhone(' +48 600.100.200 ')).assertEqual('+48 600100200');
      expect(normalizePhone('600  100\t200')).assertEqual('600 100 200');
      expect(contactPhoneError(normalizePhone('+48 (600) 100-200 ext'))).assertEqual('');
    });

    it('appendsNewContactsAfterTheHighestSortOrder', 0, () => {
      expect(nextSortOrder([])).assertEqual(0);
      expect(nextSortOrder([
        new Contact('a', 'Anna', '+48 600 000 001', 3),
        new Contact('b', 'Marek', '+48 600 000 002', 1)
      ])).assertEqual(4);
    });
  });
}
