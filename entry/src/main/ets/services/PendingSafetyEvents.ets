import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { apiSession, careApi, SafetyEventRequest } from './CareApi';
import { SafePreferences } from './SafePreferences';

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

/**
 * Holds safe-area exit events that could not reach the care service and replays
 * them later. Event ids are reused, so a replay that the backend already accepted
 * is deduplicated instead of alerting the guardian twice.
 */
export class PendingSafetyEvents {
  private readonly store = new SafePreferences(STORE_NAME);

  private async readQueue(context: common.Context): Promise<QueuedSafetyEvent[]> {
    const raw = await this.store.getString(context, QUEUE_KEY, '[]');
    try {
      const parsed = JSON.parse(raw) as QueuedSafetyEvent[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      console.error(`[PendingSafetyEvents] queue unreadable: ${JSON.stringify(error)}`);
      return [];
    }
  }

  private async writeQueue(context: common.Context, queue: QueuedSafetyEvent[]): Promise<void> {
    await this.store.putStrings(context, { 'queue': JSON.stringify(queue) });
  }

  async enqueue(context: common.Context, event: SafetyEventRequest): Promise<void> {
    const queue = await this.readQueue(context);
    const locationJson = event.location === undefined ? '' : JSON.stringify(event.location);
    queue.push(new QueuedSafetyEvent(event.id, event.type, event.occurredAt, locationJson));
    await this.writeQueue(context, queue);
  }

  async flush(context: common.Context): Promise<void> {
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      return;
    }
    const queue = await this.readQueue(context);
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
    await this.writeQueue(context, remaining);
  }
}

export const pendingSafetyEvents: PendingSafetyEvents = new PendingSafetyEvents();