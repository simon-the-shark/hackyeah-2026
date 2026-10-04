import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { webSocket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FrameAccumulator, LIVE_FRAME_BYTES } from '../models/PcmAudio';
import {
  ChatMessage,
  chatMessageFrom,
  RemoteChatMessage,
  RemoteReport,
  WellbeingReport,
  wellbeingReportFrom
} from '../models/Wellbeing';
import { MicStream, SpeakerStream } from '../platform/LiveAudio';
import { apiSession } from './CareApi';

const DOMAIN = 0x0000;
const TAG = 'LiveVoice';
/** After Carely stops speaking the microphone stays muted this long, so the end of her voice is not heard back. */
const ECHO_TAIL_MS = 400;

export enum LiveState {
  Connecting,
  /** Waiting for the senior to speak. */
  Listening,
  SeniorSpeaking,
  Thinking,
  CarelySpeaking,
  /** The check-in ended; the summary is being sent. */
  Finishing
}

/** What the voice conversation reports to the screen. */
export interface LiveVoiceListener {
  onState: (state: LiveState) => void;
  onMessage: (message: ChatMessage) => void;
  onSafetyConcern: () => void;
  /** The backend finished the check-in; undefined when there was nothing to report. */
  onFinished: (report: WellbeingReport | undefined) => void;
  /** The conversation stopped unexpectedly; `code` is the backend error code or a local one. */
  onEnded: (code: string, message: string) => void;
}

interface LiveEvent {
  type?: string;
  audio?: string;
  message?: RemoteChatMessage;
  report?: RemoteReport | null;
  code?: string;
}

class AudioFrame {
  type: string = 'audio';
  audio: string;

  constructor(audio: string) {
    this.audio = audio;
  }
}

class Interrupt {
  type: string = 'interrupt';
}

/** ws(s) address of the backend for a WebSocket upgrade. */
function socketUrl(path: string): string {
  return `${apiSession.baseUrl.replace(new RegExp('^http'), 'ws')}${path}`;
}

/**
 * Hands-free check-in: the microphone streams to the backend, which relays it to the OpenAI Realtime
 * model and sends its spoken replies back. The backend detects when the senior has finished speaking,
 * stores the transcripts and writes the summary when the model ends the check-in, so this class only
 * moves audio and reports state. Half-duplex: while Carely speaks, the microphone is not sent, so a
 * loudspeaker without echo cancellation cannot make her interrupt herself.
 */
export class LiveVoiceSession {
  private readonly listener: LiveVoiceListener;
  private readonly mic: MicStream = new MicStream();
  private readonly speaker: SpeakerStream = new SpeakerStream();
  private readonly frames: FrameAccumulator = new FrameAccumulator(LIVE_FRAME_BYTES);
  private readonly base64: util.Base64Helper = new util.Base64Helper();
  private socket: webSocket.WebSocket | undefined = undefined;
  private state: LiveState = LiveState.Connecting;
  private replyDone: boolean = true;
  private mutedUntil: number = 0;
  private closed: boolean = false;
  /** Set once the backend sent the finished check-in; reported when the goodbye has been played. */
  private finished: boolean = false;
  private finishedReport: WellbeingReport | undefined = undefined;

  constructor(listener: LiveVoiceListener) {
    this.listener = listener;
  }

  /** Throws when the microphone or the speaker cannot start; connection problems arrive via `onEnded`. */
  async start(seniorId: string, sessionId: string): Promise<void> {
    this.setState(LiveState.Connecting);
    await this.speaker.start(() => this.onSpeakerDrained());
    if (this.closed) {
      // `stop()` ran while the speaker was starting and found nothing to release yet.
      await this.speaker.stop();
      return;
    }
    try {
      await this.mic.start((pcm: Uint8Array) => this.onMicPcm(pcm));
    } catch (error) {
      await this.speaker.stop();
      throw error as Error;
    }
    if (this.closed) {
      // Never leave the microphone open for a conversation the screen has already left.
      await this.mic.stop();
      await this.speaker.stop();
      return;
    }
    const socket = webSocket.createWebSocket();
    this.socket = socket;
    socket.on('message', (error: BusinessError, data: string | ArrayBuffer) => {
      if (!error && typeof data === 'string') {
        this.onEvent(data);
      }
    });
    socket.on('close', () => {
      if (!this.closed && !this.finished) {
        this.end('closed', 'The voice connection was closed.');
      }
    });
    socket.on('error', (error: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'Socket error: %{public}d', error.code);
      if (!this.closed && !this.finished) {
        this.end('connection_failed', 'The voice connection failed.');
      }
    });
    const path = `/v1/seniors/${encodeURIComponent(seniorId)}/wellbeing/sessions/` +
      `${encodeURIComponent(sessionId)}/live`;
    try {
      const connected = await socket.connect(socketUrl(path),
        { header: { 'Authorization': `Bearer ${apiSession.token}` } });
      if (this.closed) {
        // Stopped while connecting; the close `stop()` sent may have raced the handshake.
        await socket.close().catch(() => {});
      } else if (!connected) {
        this.end('connection_failed', 'Could not start the voice conversation.');
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Connect failed: %{public}d', (error as BusinessError).code);
      this.end('connection_failed', 'Could not start the voice conversation.');
    }
  }

  /** The senior wants to talk now: Carely stops and listens. */
  interrupt(): void {
    if (this.state !== LiveState.CarelySpeaking) {
      return;
    }
    this.speaker.clear();
    this.replyDone = true;
    this.mutedUntil = Date.now() + ECHO_TAIL_MS;
    this.send(JSON.stringify(new Interrupt()));
    this.setState(LiveState.Listening);
  }

  /** Ends voice mode; the check-in itself stays open for typing. */
  async stop(): Promise<void> {
    this.closed = true;
    const socket = this.socket;
    this.socket = undefined;
    if (socket !== undefined) {
      socket.off('message');
      socket.off('close');
      socket.off('error');
      try {
        await socket.close();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Socket close failed');
      }
    }
    await this.mic.stop();
    await this.speaker.stop();
    this.frames.reset();
  }

  private onMicPcm(pcm: Uint8Array): void {
    const frames = this.frames.push(pcm);
    if (this.socket === undefined || this.closed || this.state === LiveState.Connecting ||
      this.state === LiveState.CarelySpeaking || this.state === LiveState.Finishing || Date.now() < this.mutedUntil) {
      return;
    }
    frames.forEach((frame: Uint8Array) => {
      this.send(JSON.stringify(new AudioFrame(this.base64.encodeToStringSync(frame))));
    });
  }

  private onEvent(data: string): void {
    let event: LiveEvent;
    try {
      event = JSON.parse(data) as LiveEvent;
    } catch (error) {
      return;
    }
    if (event.type === 'ready') {
      this.setState(LiveState.Listening);
    } else if (event.type === 'speech_started') {
      if (this.state !== LiveState.CarelySpeaking) {
        this.setState(LiveState.SeniorSpeaking);
      }
    } else if (event.type === 'speech_stopped') {
      this.setState(LiveState.Thinking);
    } else if (event.type === 'audio' && typeof event.audio === 'string') {
      this.replyDone = false;
      this.speaker.enqueue(this.base64.decodeSync(event.audio));
      if (this.state !== LiveState.Finishing) {
        this.setState(LiveState.CarelySpeaking);
      }
    } else if (event.type === 'audio_done') {
      this.replyDone = true;
      if (!this.speaker.playing()) {
        this.onSpeakerDrained();
      }
    } else if (event.type === 'message') {
      const message = chatMessageFrom(event.message);
      if (message !== undefined) {
        this.listener.onMessage(message);
      }
    } else if (event.type === 'safety_concern') {
      this.listener.onSafetyConcern();
    } else if (event.type === 'finished') {
      this.finished = true;
      this.finishedReport = wellbeingReportFrom(event.report);
      this.setState(LiveState.Finishing);
      if (!this.speaker.playing()) {
        this.reportFinished();
      }
    } else if (event.type === 'error') {
      this.end(typeof event.code === 'string' ? event.code : 'error', 'The voice conversation stopped.');
    }
  }

  private onSpeakerDrained(): void {
    if (this.finished) {
      this.reportFinished();
      return;
    }
    if (this.replyDone && this.state === LiveState.CarelySpeaking) {
      this.mutedUntil = Date.now() + ECHO_TAIL_MS;
      this.setState(LiveState.Listening);
    }
  }

  private reportFinished(): void {
    if (this.closed) {
      return;
    }
    const report = this.finishedReport;
    this.stop();
    this.listener.onFinished(report);
  }

  private end(code: string, message: string): void {
    if (this.closed) {
      return;
    }
    this.stop();
    this.listener.onEnded(code, message);
  }

  private send(data: string): void {
    const socket = this.socket;
    if (socket === undefined) {
      return;
    }
    socket.send(data).catch((error: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'Send failed: %{public}d', error.code);
    });
  }

  private setState(state: LiveState): void {
    if (this.state !== state) {
      this.state = state;
      this.listener.onState(state);
    } else if (state === LiveState.Connecting) {
      this.listener.onState(state);
    }
  }
}
