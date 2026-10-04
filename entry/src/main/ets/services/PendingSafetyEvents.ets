import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { isPermanentRejection } from '../providers/backend/BackendClient';
import { apiSession, careApi, SafetyEventRequest } from './CareApi';
import { SafePreferences } from './SafePreferences';

const STORE_NAME = 'carely_pending_events';
const QUEUE_KEY = 'queue';
const DOMAIN = 0x0000;
const TAG = 'PendingSafetyEvents';

class QueuedSafetyEvent {
  seniorId: string;
  id: string;
  type: string;
  occurredAt: string;
  locationJson: string;

  constructor(id: string, type: string, occurredAt: string, locationJson: string, seniorId: string) {
    this.seniorId = seniorId;
    this.id = id;
    this.type = type;
    this.occurredAt = occurredAt;
    this.locationJson = locationJson;
  }
}

/**
 * Holds SOS and safe-area events that could not reach the care service and replays
 * them later. Event ids are reused, so a replay that the backend already accepted
 * is deduplicated instead of alerting the guardian twice.
 */
export class PendingSafetyEvents {
  private readonly store = new SafePreferences(STORE_NAME);
  private operations: Promise<void> = Promise.resolve();

  private serialize(operation: () => Promise<void>): Promise<void> {
    const result = this.operations.then(operation);
    this.operations = result.catch(() => {});
    return result;
  }

  private async readQueue(context: common.Context): Promise<QueuedSafetyEvent[]> {
    const prefs = await this.store.open(context);
    if (prefs === undefined) throw new Error('Safety event storage is unavailable');
    try {
      const raw = await prefs.get(QUEUE_KEY, '[]');
      if (typeof raw !== 'string') throw new Error('Invalid queue');
      const parsed = JSON.parse(raw) as QueuedSafetyEvent[];
      if (!Array.isArray(parsed)) throw new Error('Invalid queue');
      return parsed;
    } catch (_) {
      // Never overwrite an unreadable outbox with an apparently empty queue.
      throw new Error('Could not read saved safety events');
    }
  }

  private async writeQueue(context: common.Context, queue: QueuedSafetyEvent[]): Promise<void> {
    // Outbox writes must report failure, rather than silently claiming an event is durable.
    const prefs = await this.store.open(context);
    if (prefs === undefined) throw new Error('Safety event storage is unavailable');
    try {
      await prefs.put(QUEUE_KEY, JSON.stringify(queue));
      await prefs.flush();
    } catch (_) {
      throw new Error('Could not persist safety events');
    }
  }

  async enqueue(context: common.Context, event: SafetyEventRequest): Promise<void> {
    const seniorId = apiSession.seniorId;
    const token = apiSession.token;
    await this.serialize(async () => {
      if (token !== apiSession.token || !apiSession.configured()) return;
      const queue = await this.readQueue(context);
      const locationJson = event.location === undefined ? '' : JSON.stringify(event.location);
      if (!queue.some((item: QueuedSafetyEvent) => item.id === event.id && item.seniorId === seniorId)) {
        queue.push(new QueuedSafetyEvent(event.id, event.type, event.occurredAt, locationJson, seniorId));
      }
      await this.writeQueue(context, queue);
    });
  }

  async flush(context: common.Context): Promise<void> {
    const token = apiSession.token;
    await this.serialize(async () => {
      if (!apiSession.configured() || apiSession.role !== 'senior' || token !== apiSession.token) return;
      const stored = await this.readQueue(context);
      // Legacy unscoped entries cannot safely be attributed after a new pairing.
      const queue = stored.filter((item: QueuedSafetyEvent) => item.seniorId === apiSession.seniorId);
      if (queue.length !== stored.length) await this.writeQueue(context, queue);
      while (queue.length > 0) {
        if (token !== apiSession.token) return;
        const item = queue[0];
        const event = new SafetyEventRequest(item.id, item.type, item.occurredAt);
        if (item.locationJson !== '') event.location = JSON.parse(item.locationJson) as Object;
        try {
          await careApi.request(`/seniors/${encodeURIComponent(apiSession.seniorId)}/events`,
            http.RequestMethod.POST, event);
        } catch (error) {
          // Stop on a retryable failure: never deliver a re-entry ahead of its exit. An event the backend
          // rejects for good is dropped, or it would block every later alert.
          if (!isPermanentRejection(error as Object)) {
            throw error as Error;
          }
          hilog.warn(DOMAIN, TAG, 'Dropping rejected %{public}s event', item.type);
        }
        queue.shift();
        await this.writeQueue(context, queue);
      }
    });
  }

  async clear(context: common.Context): Promise<void> {
    await this.serialize(async () => { await this.writeQueue(context, []); });
  }
}

export const pendingSafetyEvents: PendingSafetyEvents = new PendingSafetyEvents();
