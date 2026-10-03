import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'VoicePlayer';

/**
 * Plays one MP3 reply with Media Kit `AVPlayer` from a cache file. Starting a new reply or calling
 * `stop` ends the current one; `onDone` runs exactly once per `play`, however playback ends.
 */
export class VoicePlayer {
  private player: media.AVPlayer | undefined = undefined;
  private fd: number = -1;
  private onDone: () => void = () => {
  };

  playing(): boolean {
    return this.player !== undefined;
  }

  async play(context: common.Context, audio: ArrayBuffer, onDone: () => void): Promise<void> {
    await this.stop();
    const path = `${context.cacheDir}/wellbeing-reply.mp3`;
    try {
      const out = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(out.fd, audio);
      fileIo.closeSync(out);
      this.fd = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY).fd;
      const player = await media.createAVPlayer();
      this.player = player;
      this.onDone = onDone;
      player.on('stateChange', (state: media.AVPlayerState) => {
        this.onStateChange(player, state);
      });
      player.on('error', (error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Playback error: %{public}d', error.code);
        this.stop();
      });
      // Setting the source moves the player to `initialized`; the state handler does the rest.
      player.fdSrc = { fd: this.fd };
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Playback did not start: %{public}d', (error as BusinessError).code);
      this.onDone = onDone;
      await this.stop();
    }
  }

  async stop(): Promise<void> {
    const player = this.player;
    this.player = undefined;
    if (player !== undefined) {
      player.off('stateChange');
      player.off('error');
      try {
        await player.release();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Player release failed: %{public}d', (error as BusinessError).code);
      }
    }
    if (this.fd >= 0) {
      try {
        fileIo.closeSync(this.fd);
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Closing the reply audio failed');
      }
      this.fd = -1;
    }
    const done = this.onDone;
    this.onDone = () => {
    };
    done();
  }

  private async onStateChange(player: media.AVPlayer, state: media.AVPlayerState): Promise<void> {
    if (player !== this.player) {
      return;
    }
    try {
      if (state === 'initialized') {
        await player.prepare();
      } else if (state === 'prepared') {
        await player.play();
      } else if (state === 'completed') {
        await this.stop();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Playback step failed: %{public}d', (error as BusinessError).code);
      await this.stop();
    }
  }
}
