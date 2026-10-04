import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LIVE_SAMPLE_RATE, pcm16Bytes, pcm16Samples, PcmQueue, resamplePcm16 } from '../models/PcmAudio';

const DOMAIN = 0x0000;
const TAG = 'LiveAudio';
/** Tried in order; anything other than 24 kHz is resampled before it is sent. */
const CAPTURE_RATES: audio.AudioSamplingRate[] = [
  audio.AudioSamplingRate.SAMPLE_RATE_24000,
  audio.AudioSamplingRate.SAMPLE_RATE_48000,
  audio.AudioSamplingRate.SAMPLE_RATE_16000
];

/**
 * Microphone as a stream of 24 kHz 16-bit mono PCM, through Audio Kit `AudioCapturer` (`readData`
 * callback). Needs `ohos.permission.MICROPHONE`, which the caller requests first.
 */
export class MicStream {
  private capturer: audio.AudioCapturer | undefined = undefined;
  private rate: number = LIVE_SAMPLE_RATE;

  /** Throws when no capture configuration works on this device. */
  async start(onPcm: (pcm: Uint8Array) => void): Promise<void> {
    await this.stop();
    let lastError: Object | undefined = undefined;
    for (const rate of CAPTURE_RATES) {
      let created: audio.AudioCapturer | undefined = undefined;
      try {
        const capturer = await audio.createAudioCapturer({
          streamInfo: {
            samplingRate: rate,
            channels: audio.AudioChannel.CHANNEL_1,
            sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
            encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
          },
          capturerInfo: {
            source: audio.SourceType.SOURCE_TYPE_MIC,
            capturerFlags: 0
          }
        });
        created = capturer;
        this.rate = rate;
        capturer.on('readData', (buffer: ArrayBuffer) => {
          const samples = pcm16Samples(new Uint8Array(buffer));
          onPcm(pcm16Bytes(resamplePcm16(samples, this.rate, LIVE_SAMPLE_RATE)));
        });
        await capturer.start();
        this.capturer = capturer;
        hilog.info(DOMAIN, TAG, 'Microphone streaming at %{public}d Hz', rate);
        return;
      } catch (error) {
        lastError = error as Object;
        hilog.warn(DOMAIN, TAG, 'Capture at %{public}d Hz failed: %{public}d', rate, (error as BusinessError).code);
        // A capturer that was created but did not start still holds the microphone until it is released.
        if (created !== undefined) {
          try {
            created.off('readData');
            await created.release();
          } catch (releaseError) {
            hilog.warn(DOMAIN, TAG, 'Capturer release failed: %{public}d', (releaseError as BusinessError).code);
          }
        }
      }
    }
    throw lastError as Error;
  }

  async stop(): Promise<void> {
    const capturer = this.capturer;
    this.capturer = undefined;
    if (capturer === undefined) {
      return;
    }
    try {
      capturer.off('readData');
      await capturer.stop();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Capturer stop failed: %{public}d', (error as BusinessError).code);
    }
    try {
      await capturer.release();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Capturer release failed: %{public}d', (error as BusinessError).code);
    }
  }
}

/**
 * Plays the assistant's 24 kHz 16-bit mono PCM as it arrives, through Audio Kit `AudioRenderer`
 * (`writeData` callback). Silence fills the gaps; `onDrained` runs when queued audio has been played.
 */
export class SpeakerStream {
  private renderer: audio.AudioRenderer | undefined = undefined;
  private readonly queue: PcmQueue = new PcmQueue();
  private wasPlaying: boolean = false;
  private onDrained: () => void = () => {
  };

  async start(onDrained: () => void): Promise<void> {
    await this.stop();
    this.onDrained = onDrained;
    const renderer = await audio.createAudioRenderer({
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_24000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      // A voice assistant plays through the loudspeaker, not the earpiece like a call would.
      rendererInfo: {
        usage: audio.StreamUsage.STREAM_USAGE_VOICE_ASSISTANT,
        rendererFlags: 0
      }
    });
    try {
      renderer.on('writeData', (buffer: ArrayBuffer): audio.AudioDataCallbackResult => this.fill(buffer));
      await renderer.start();
    } catch (error) {
      await renderer.release();
      throw error as Error;
    }
    this.renderer = renderer;
  }

  /** Copies queued audio into the renderer's buffer; silence when nothing is queued. */
  private fill(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
    const target = new Uint8Array(buffer);
    const written = this.queue.readInto(target);
    target.fill(0, written);
    if (written > 0) {
      this.wasPlaying = true;
    } else if (this.wasPlaying) {
      this.wasPlaying = false;
      this.onDrained();
    }
    return audio.AudioDataCallbackResult.VALID;
  }

  enqueue(pcm: Uint8Array): void {
    this.queue.push(pcm);
  }

  /** Drops audio that has not been played yet, e.g. when the senior interrupts. */
  clear(): void {
    this.queue.clear();
  }

  playing(): boolean {
    return this.queue.size() > 0 || this.wasPlaying;
  }

  async stop(): Promise<void> {
    this.queue.clear();
    this.wasPlaying = false;
    const renderer = this.renderer;
    this.renderer = undefined;
    if (renderer === undefined) {
      return;
    }
    try {
      renderer.off('writeData');
      await renderer.stop();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Renderer stop failed: %{public}d', (error as BusinessError).code);
    }
    try {
      await renderer.release();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Renderer release failed: %{public}d', (error as BusinessError).code);
    }
  }
}
