// Small helpers for the live voice check-in: 16-bit mono PCM at the rate the backend expects.

/** The Realtime voice stream uses 16-bit little-endian mono PCM at 24 kHz both ways. */
export const LIVE_SAMPLE_RATE = 24000;
/** One frame sent to the backend: 100 ms of 24 kHz 16-bit mono. */
export const LIVE_FRAME_BYTES = LIVE_SAMPLE_RATE / 10 * 2;

/** FIFO of PCM bytes received from the backend, read in whatever block size the speaker asks for. */
export class PcmQueue {
  private chunks: Uint8Array[] = [];
  private offset: number = 0;
  private total: number = 0;

  push(bytes: Uint8Array): void {
    if (bytes.length > 0) {
      this.chunks.push(bytes);
      this.total += bytes.length;
    }
  }

  size(): number {
    return this.total;
  }

  clear(): void {
    this.chunks = [];
    this.offset = 0;
    this.total = 0;
  }

  /** Copies up to `target.length` bytes into `target` and returns how many were copied. */
  readInto(target: Uint8Array): number {
    let written = 0;
    while (written < target.length && this.chunks.length > 0) {
      const head = this.chunks[0];
      const count = Math.min(head.length - this.offset, target.length - written);
      target.set(head.subarray(this.offset, this.offset + count), written);
      written += count;
      this.offset += count;
      if (this.offset >= head.length) {
        this.chunks.shift();
        this.offset = 0;
      }
    }
    this.total -= written;
    return written;
  }
}

/** Collects microphone buffers of any size into fixed-size frames. */
export class FrameAccumulator {
  private readonly frameBytes: number;
  private pending: Uint8Array = new Uint8Array(0);

  constructor(frameBytes: number) {
    this.frameBytes = frameBytes;
  }

  /** Every complete frame the new bytes finish; the remainder waits for the next call. */
  push(bytes: Uint8Array): Uint8Array[] {
    const joined = new Uint8Array(this.pending.length + bytes.length);
    joined.set(this.pending, 0);
    joined.set(bytes, this.pending.length);
    const frames: Uint8Array[] = [];
    let start = 0;
    while (joined.length - start >= this.frameBytes) {
      frames.push(joined.slice(start, start + this.frameBytes));
      start += this.frameBytes;
    }
    this.pending = joined.slice(start);
    return frames;
  }

  reset(): void {
    this.pending = new Uint8Array(0);
  }
}

/** Linear resampling of mono 16-bit samples, e.g. a 48 kHz microphone to the 24 kHz stream. */
export function resamplePcm16(samples: Int16Array, fromRate: number, toRate: number): Int16Array {
  if (fromRate === toRate || samples.length === 0) {
    return samples;
  }
  const length = Math.max(1, Math.floor(samples.length * toRate / fromRate));
  const out = new Int16Array(length);
  const step = fromRate / toRate;
  for (let i = 0; i < length; i++) {
    const position = i * step;
    const index = Math.floor(position);
    const next = Math.min(index + 1, samples.length - 1);
    const fraction = position - index;
    out[i] = Math.round(samples[index] * (1 - fraction) + samples[next] * fraction);
  }
  return out;
}

/** Bytes of whole 16-bit samples; a trailing odd byte is dropped. */
export function pcm16Samples(bytes: Uint8Array): Int16Array {
  const even = bytes.length - bytes.length % 2;
  const copy = bytes.slice(0, even);
  return new Int16Array(copy.buffer, 0, even / 2);
}

export function pcm16Bytes(samples: Int16Array): Uint8Array {
  return new Uint8Array(samples.buffer, samples.byteOffset, samples.byteLength);
}
