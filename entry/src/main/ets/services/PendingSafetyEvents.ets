import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { http } from '@kit.NetworkKit';
import { apiSession, careApi, SafetyEventRequest } from './CareApi';

const STORE_NAME = 'carely_pending_events';
const QUEUE_KEY = 'queue';

class QueuedSafetyEvent {
  id: string;
  type: string;
  occurredAt: string;
  locationJson: string;

  constructor(id: string, type: string, occurredAt: string, locationJson: string) {
    this.id = id;
    this.type = type;
    this.occurredAt = occurredAt;
    this.locationJson = locationJson;
  }
}

export class PendingSafetyEvents {
  private readQueue(context: common.Context): QueuedSafetyEvent[] {
    const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    const raw = prefs.getSync(QUEUE_KEY, '[]') as string;
    try {
      const parsed = JSON.parse(raw) as QueuedSafetyEvent[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      return [];
    }
  }

  private writeQueue(context: common.Context, queue: QueuedSafetyEvent[]): void {
    const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    prefs.putSync(QUEUE_KEY, JSON.stringify(queue));
    prefs.flushSync();
  }

  enqueue(context: common.Context, event: SafetyEventRequest): void {
    const queue = this.readQueue(context);
    const locationJson = event.location === undefined ? '' : JSON.stringify(event.location);
    queue.push(new QueuedSafetyEvent(event.id, event.type, event.occurredAt, locationJson));
    this.writeQueue(context, queue);
  }

  async flush(context: common.Context): Promise<void> {
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      return;
    }
    const queue = this.readQueue(context);
    if (queue.length === 0) {
      return;
    }
    const remaining: QueuedSafetyEvent[] = [];
    for (const item of queue) {
      const event = new SafetyEventRequest(item.id, item.type, item.occurredAt);
      if (item.locationJson !== '') {
        event.location = JSON.parse(item.locationJson) as Object;
      }
      try {
        await careApi.request(`/seniors/${apiSession.seniorId}/events`, http.RequestMethod.POST, event);
      } catch (error) {
        remaining.push(item);
      }
    }
    this.writeQueue(context, remaining);
  }
}

export const pendingSafetyEvents: PendingSafetyEvents = new PendingSafetyEvents();
