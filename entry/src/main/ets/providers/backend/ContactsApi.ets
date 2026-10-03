import { Contact } from '../../models/Contact';
import { BackendClient, invalidResponse } from './BackendClient';

// Wire shapes from backend/README.md. Fields are optional because the payload is checked before use.
interface ContactDto {
  id?: string;
  name?: string;
  phone?: string;
  sortOrder?: number;
}

interface ContactListDto {
  items?: ContactDto[];
}

function toContact(dto: ContactDto): Contact {
  if (typeof dto.id !== 'string' || typeof dto.name !== 'string' || typeof dto.phone !== 'string') {
    throw invalidResponse('contact');
  }
  return new Contact(dto.id, dto.name, dto.phone, typeof dto.sortOrder === 'number' ? dto.sortOrder : 0);
}

// Senior-side contact endpoints. The senior can only read; the guardian manages the list.
export class ContactsApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  // Trusted contacts in the guardian's order.
  async contacts(seniorId: string): Promise<Contact[]> {
    const list = await this.client.get<ContactListDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/contacts`);
    if (!Array.isArray(list.items)) {
      throw invalidResponse('contact list');
    }
    return (list.items as ContactDto[]).map((dto: ContactDto) => toContact(dto));
  }
}
