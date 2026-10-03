import { describe, it, expect } from '@ohos/hypium';
import { FrameAccumulator, PcmQueue, pcm16Bytes, pcm16Samples, resamplePcm16 } from '../main/ets/models/PcmAudio';

function bytes(values: number[]): Uint8Array {
  return new Uint8Array(values);
}

export default function pcmAudioTest() {
  describe('pcmAudio', () => {
    it('readsQueuedAudioAcrossChunksInOrder', 0, () => {
      const queue = new PcmQueue();
      queue.push(bytes([1, 2, 3]));
      queue.push(bytes([4, 5]));
      const first = new Uint8Array(4);
      expect(queue.readInto(first)).assertEqual(4);
      expect(first[3]).assertEqual(4);
      expect(queue.size()).assertEqual(1);
      const second = new Uint8Array(4);
      expect(queue.readInto(second)).assertEqual(1);
      expect(second[0]).assertEqual(5);
      expect(queue.size()).assertEqual(0);
    });

    it('dropsUnplayedAudioOnClear', 0, () => {
      const queue = new PcmQueue();
      queue.push(bytes([1, 2]));
      queue.clear();
      expect(queue.readInto(new Uint8Array(2))).assertEqual(0);
    });

    it('cutsMicrophoneBuffersIntoFixedFrames', 0, () => {
      const frames = new FrameAccumulator(4);
      expect(frames.push(bytes([1, 2, 3])).length).assertEqual(0);
      const ready = frames.push(bytes([4, 5, 6, 7, 8, 9]));
      expect(ready.length).assertEqual(2);
      expect(ready[0][3]).assertEqual(4);
      expect(ready[1][0]).assertEqual(5);
      expect(frames.push(bytes([10, 11, 12])).length).assertEqual(1);
    });

    it('halvesA48kHzStreamTo24kHz', 0, () => {
      const out = resamplePcm16(new Int16Array([0, 100, 200, 300, 400, 500]), 48000, 24000);
      expect(out.length).assertEqual(3);
      expect(out[1]).assertEqual(200);
    });

    it('keepsWholeSamplesOnly', 0, () => {
      const samples = pcm16Samples(bytes([1, 0, 2, 0, 9]));
      expect(samples.length).assertEqual(2);
      expect(samples[1]).assertEqual(2);
      expect(pcm16Bytes(samples).length).assertEqual(4);
    });
  });
}
