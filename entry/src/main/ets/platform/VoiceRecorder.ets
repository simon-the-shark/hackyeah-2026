import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'VoiceRecorder';
const MICROPHONE: Permissions = 'ohos.permission.MICROPHONE';
/** Container the backend is told about; matches `CFT_MPEG_4A` below. */
export const VOICE_FORMAT = 'm4a';

export enum MicrophoneAccess {
  Granted,
  Denied,
  Failed
}

/** Asks for the microphone (user_grant). After an earlier refusal the system answers without a dialog. */
export async function requestMicrophone(context: common.UIAbilityContext): Promise<MicrophoneAccess> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [MICROPHONE]);
    return result.authResults[0] === 0 ? MicrophoneAccess.Granted : MicrophoneAccess.Denied;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'Microphone request failed: %{public}d', (error as BusinessError).code);
    return MicrophoneAccess.Failed;
  }
}

/** Opens the system dialog that lets the user turn the microphone back on for Carely. */
export async function openMicrophoneSettings(context: common.UIAbilityContext): Promise<boolean> {
  try {
    const result = await abilityAccessCtrl.createAtManager().requestPermissionOnSetting(context, [MICROPHONE]);
    return result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'Microphone settings failed: %{public}d', (error as BusinessError).code);
    return false;
  }
}

/**
 * Records one spoken answer to an AAC/M4A file in the cache with Media Kit `AVRecorder`
 * (needs `ohos.permission.MICROPHONE`), then hands back the bytes. Only one recording at a time;
 * the file is deleted as soon as its bytes are read or the recording is cancelled.
 */
export class VoiceRecorder {
  private recorder: media.AVRecorder | undefined = undefined;
  private fd: number = -1;
  private path: string = '';

  recording(): boolean {
    return this.recorder !== undefined;
  }

  /** Throws when the device cannot record (no microphone, permission missing, or emulator limits). */
  async start(context: common.Context): Promise<void> {
    await this.cancel();
    this.path = `${context.cacheDir}/wellbeing-voice.m4a`;
    try {
      this.fd = fileIo.openSync(this.path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE |
      fileIo.OpenMode.TRUNC).fd;
      const recorder = await media.createAVRecorder();
      this.recorder = recorder;
      recorder.on('error', (error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Recorder error: %{public}d', error.code);
      });
      // Speech only: mono AAC at the documented 48 kHz rate keeps a minute of audio well under 1 MB.
      const profile: media.AVRecorderProfile = {
        audioBitrate: 64000,
        audioChannels: 1,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        audioSampleRate: 48000,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A
      };
      await recorder.prepare({
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: profile,
        url: `fd://${this.fd}`
      });
      await recorder.start();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Recording did not start: %{public}d', (error as BusinessError).code);
      await this.cancel();
      throw error as Error;
    }
  }

  /** Stops and returns the recorded audio; undefined when nothing usable was recorded. */
  async stop(): Promise<ArrayBuffer | undefined> {
    const recorder = this.recorder;
    if (recorder === undefined) {
      return undefined;
    }
    let stopped = true;
    try {
      await recorder.stop();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Recorder stop failed: %{public}d', (error as BusinessError).code);
      stopped = false;
    }
    await this.release();
    const audio = stopped ? this.readFile() : undefined;
    this.deleteFile();
    return audio;
  }

  async cancel(): Promise<void> {
    const recorder = this.recorder;
    if (recorder !== undefined && recorder.state === 'started') {
      try {
        await recorder.stop();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Recorder cancel failed: %{public}d', (error as BusinessError).code);
      }
    }
    await this.release();
    this.deleteFile();
  }

  private async release(): Promise<void> {
    const recorder = this.recorder;
    this.recorder = undefined;
    if (recorder !== undefined) {
      recorder.off('error');
      try {
        await recorder.release();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Recorder release failed: %{public}d', (error as BusinessError).code);
      }
    }
    if (this.fd >= 0) {
      try {
        fileIo.closeSync(this.fd);
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Closing the recording failed');
      }
      this.fd = -1;
    }
  }

  private readFile(): ArrayBuffer | undefined {
    try {
      const size = fileIo.statSync(this.path).size;
      if (size <= 0) {
        return undefined;
      }
      const file = fileIo.openSync(this.path, fileIo.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(size);
      const read = fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return read > 0 ? buffer.slice(0, read) : undefined;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Reading the recording failed');
      return undefined;
    }
  }

  private deleteFile(): void {
    if (this.path === '') {
      return;
    }
    try {
      if (fileIo.accessSync(this.path)) {
        fileIo.unlinkSync(this.path);
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Deleting the recording failed');
    }
  }
}
