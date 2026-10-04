import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiError, ApiErrorKind } from '../providers/backend/BackendClient';
import { apiSession, careApi, SafetyEventRequest } from './CareApi';
import { locationSharing } from './LocationSharing';
import { pendingSafetyEvents } from './PendingSafetyEvents';

const DOMAIN = 0x0000;
const TAG = 'SosService';
const RETRY_INTERVAL_MS = 30000;

export enum SosOutcome {
  /** The care service accepted the SOS. */
  Sent,
  /** The care service could not be reached; the SOS is saved on the phone and resent automatically. */
  Queued,
  /** The SOS was neither sent nor saved; the senior has to try again. */
  Failed
}

export class SosResult {
  readonly outcome: SosOutcome;
  /** Fix time of the location attached to the SOS; 0 when none was available. */
  readonly locationAt: number;

  constructor(outcome: SosOutcome, locationAt: number) {
    this.outcome = outcome;
    this.locationAt = locationAt;
  }
}

/**
 * Sends the senior's SOS. An SOS that cannot reach the care service is kept in the safety-event outbox
 * and resent every 30 seconds while Carely runs, and again on the next launch. The event id is reused,
 * so a resend the backend already accepted does not alert the guardian twice.
 */
export class SosService {
  private retryTimer: number = -1;

  async send(context: common.Context, eventId: string): Promise<SosResult> {
    if (!apiSession.configured() || apiSession.role !== 'senior') {
      return new SosResult(SosOutcome.Failed, 0);
    }
    const event = new SafetyEventRequest(eventId, 'sos');
    const location = locationSharing.lastKnownLocation();
    if (location !== undefined) {
      event.location = location;
    }
    const locationAt = location !== undefined ? Date.parse(location.sampledAt) : 0;
    try {
      await careApi.request(`/seniors/${encodeURIComponent(apiSession.seniorId)}/events`, http.RequestMethod.POST,
        event);
      return new SosResult(SosOutcome.Sent, locationAt);
    } catch (error) {
      if (!(error instanceof ApiError) || (error.kind !== ApiErrorKind.Network && error.status < 500)) {
        return new SosResult(SosOutcome.Failed, locationAt);
      }
    }
    try {
      await pendingSafetyEvents.enqueue(context, event);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Could not save the SOS for a later retry');
      return new SosResult(SosOutcome.Failed, locationAt);
    }
    this.scheduleRetry(context);
    return new SosResult(SosOutcome.Queued, locationAt);
  }

  /** Resends saved safety events now; called when Carely comes to the foreground. */
  resend(context: common.Context): void {
    if (apiSession.configured() && apiSession.role === 'senior') {
      this.scheduleRetry(context);
    }
  }

  private scheduleRetry(context: common.Context): void {
    if (this.retryTimer !== -1) {
      return;
    }
    const attempt = async (): Promise<void> => {
      try {
        // Resolves once the outbox is empty, or immediately after sign-out.
        await pendingSafetyEvents.flush(context);
        this.stopRetry();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Saved SOS not delivered yet; retrying');
      }
    };
    this.retryTimer = setInterval(() => {
      attempt();
    }, RETRY_INTERVAL_MS);
    attempt();
  }

  private stopRetry(): void {
    if (this.retryTimer !== -1) {
      clearInterval(this.retryTimer);
      this.retryTimer = -1;
    }
  }
}

export const sosService: SosService = new SosService();
