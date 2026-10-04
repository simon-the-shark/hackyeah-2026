// A trusted person the senior can call, configured by the guardian on the backend.
export class Contact {
  readonly id: string;
  readonly name: string;
  // As entered by the guardian, e.g. "+48 600 000 001".
  readonly phone: string;
  readonly sortOrder: number;
  // Optimistic-locking version from the backend; edits must send the version they started from.
  readonly version: number;
  // The person to offer first when an SOS cannot be delivered. Edits must send it back, because the
  // backend resets an omitted value to false.
  readonly isEmergency: boolean;

  constructor(id: string, name: string, phone: string, sortOrder: number, version: number = 1,
    isEmergency: boolean = false) {
    this.id = id;
    this.name = name;
    this.phone = phone;
    this.sortOrder = sortOrder;
    this.version = version;
    this.isEmergency = isEmergency;
  }
}
