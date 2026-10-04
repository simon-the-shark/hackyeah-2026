import { Contact } from '../../models/Contact';
import { BackendClient, invalidResponse } from './BackendClient';

// Wire shapes from backend/README.md. Fields are optional because the payload is checked before use.
interface ContactDto {
  id?: string;
  name?: string;
  phone?: string;
  sortOrder?: number;
  version?: number;
  isEmergency?: boolean;
}

interface ContactListDto {
  items?: ContactDto[];
}

// Request body for POST, and for PUT together with `version`.
class ContactBody {
  name: string;
  phone: string;
  sortOrder: number;
  isEmergency: boolean;
  version?: number;

  constructor(name: string, phone: string, sortOrder: number, isEmergency: boolean, version?: number) {
    this.name = name;
    this.phone = phone;
    this.sortOrder = sortOrder;
    this.isEmergency = isEmergency;
    if (version !== undefined) {
      this.version = version;
    }
  }
}

function toContact(dto: ContactDto): Contact {
  if (typeof dto.id !== 'string' || typeof dto.name !== 'string' || typeof dto.phone !== 'string') {
    throw invalidResponse('contact');
  }
  return new Contact(dto.id, dto.name, dto.phone, typeof dto.sortOrder === 'number' ? dto.sortOrder : 0,
    typeof dto.version === 'number' ? dto.version : 1, dto.isEmergency === true);
}

// The stored contact a 409 version_conflict carries in `details.current`; undefined when it is unreadable.
export function conflictingContact(details: Object | undefined): Contact | undefined {
  if (details === undefined) {
    return undefined;
  }
  const current = (details as Record<string, Object>)['current'];
  if (current === undefined || current === null || typeof current !== 'object') {
    return undefined;
  }
  try {
    return toContact(current as ContactDto);
  } catch (err) {
    return undefined;
  }
}

// Trusted-contact endpoints. Any linked device can read; only a guardian device can write.
export class ContactsApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  // Trusted contacts in the guardian's order.
  async contacts(seniorId: string): Promise<Contact[]> {
    const list = await this.client.get<ContactListDto>(ContactsApi.collection(seniorId));
    if (!Array.isArray(list.items)) {
      throw invalidResponse('contact list');
    }
    return (list.items as ContactDto[]).map((dto: ContactDto) => toContact(dto));
  }

  async create(seniorId: string, name: string, phone: string, sortOrder: number): Promise<Contact> {
    return toContact(await this.client.post<ContactDto>(ContactsApi.collection(seniorId),
      new ContactBody(name, phone, sortOrder, false)));
  }

  // Sends the version the edit started from; a newer stored version fails with 409 version_conflict.
  async update(seniorId: string, original: Contact, name: string, phone: string): Promise<Contact> {
    return toContact(await this.client.put<ContactDto>(ContactsApi.item(seniorId, original.id),
      new ContactBody(name, phone, original.sortOrder, original.isEmergency, original.version)));
  }

  async remove(seniorId: string, contactId: string): Promise<void> {
    await this.client.delete(ContactsApi.item(seniorId, contactId));
  }

  private static collection(seniorId: string): string {
    return `/v1/seniors/${encodeURIComponent(seniorId)}/contacts`;
  }

  private static item(seniorId: string, contactId: string): string {
    return `${ContactsApi.collection(seniorId)}/${encodeURIComponent(contactId)}`;
  }
}
