import { describe, it, expect } from '@ohos/hypium';
import { Contact } from '../main/ets/models/Contact';
import {
  contactInitials,
  decodeContacts,
  dialableNumber,
  encodeContacts,
  sortContacts
} from '../main/ets/services/ContactList';

export default function contactListTest() {
  describe('contactList', () => {
    it('sortsByGuardianOrderThenName', 0, () => {
      const sorted = sortContacts([
        new Contact('c', 'Zofia', '+48 600 000 003', 1),
        new Contact('b', 'Anna', '+48 600 000 002', 1),
        new Contact('a', 'Marek', '+48 600 000 001', 0)
      ]);
      expect(sorted.map((contact: Contact) => contact.id).join(',')).assertEqual('a,b,c');
    });

    it('buildsInitialsWithoutBracketedNotes', 0, () => {
      expect(contactInitials('Marek (son)')).assertEqual('M');
      expect(contactInitials('dr. Anna Nowak')).assertEqual('DA');
      expect(contactInitials('Anna Nowak')).assertEqual('AN');
      expect(contactInitials('  ')).assertEqual('?');
    });

    it('keepsOnlyDialableCharacters', 0, () => {
      expect(dialableNumber('+48 600 000 001')).assertEqual('+48600000001');
      expect(dialableNumber('(12) 345-67-89')).assertEqual('123456789');
    });

    it('roundTripsCachedContacts', 0, () => {
      const entries = encodeContacts([new Contact('a', 'Marek (son)', '+48 600 000 001', 2)]);
      entries.push('malformed', '{"id":"x","name":"No phone"}');
      const decoded = decodeContacts(entries);
      expect(decoded.length).assertEqual(1);
      expect(decoded[0].name).assertEqual('Marek (son)');
      expect(decoded[0].phone).assertEqual('+48 600 000 001');
      expect(decoded[0].sortOrder).assertEqual(2);
    });
  });
}
