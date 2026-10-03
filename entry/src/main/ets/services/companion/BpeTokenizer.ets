// Byte-level BPE encoder matching the Hugging Face tokenizer of the bundled concern-check model (Qwen2.5).
// The split pattern, NFC normalization and special tokens come from tokenizer_config.json, written by
// tools/companion-model/export_classifier.py; tokenizer_vectors.json holds reference encodings to check it.

export interface TokenizerConfig {
  splitPattern: string;
  normalizeNfc: boolean;
  special: Record<string, number>;
}

// The GPT-2 table mapping every byte to a printable character, so BPE runs on strings.
function byteToUnicode(): string[] {
  const bytes: number[] = [];
  for (let b = 33; b <= 126; b++) {
    bytes.push(b);
  }
  for (let b = 161; b <= 172; b++) {
    bytes.push(b);
  }
  for (let b = 174; b <= 255; b++) {
    bytes.push(b);
  }
  const chars: number[] = bytes.slice();
  let extra = 0;
  for (let b = 0; b < 256; b++) {
    if (bytes.indexOf(b) < 0) {
      bytes.push(b);
      chars.push(256 + extra);
      extra++;
    }
  }
  const table: string[] = new Array<string>(256);
  for (let i = 0; i < bytes.length; i++) {
    table[bytes[i]] = String.fromCharCode(chars[i]);
  }
  return table;
}

// UTF-8 bytes of a string, in plain ArkTS so the tokenizer behaves the same in unit tests and on the device.
export function utf8Bytes(text: string): number[] {
  const bytes: number[] = [];
  for (const ch of text) {
    const cp = ch.codePointAt(0) as number;
    if (cp < 0x80) {
      bytes.push(cp);
    } else if (cp < 0x800) {
      bytes.push(0xC0 | (cp >> 6), 0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
      bytes.push(0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
    } else {
      bytes.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
    }
  }
  return bytes;
}

export class BpeTokenizer {
  private readonly vocab: Map<string, number>;
  private readonly ranks: Map<string, number>;
  private readonly special: Map<string, number>;
  private readonly splitPattern: RegExp;
  private readonly normalizeNfc: boolean;
  private readonly byteEncoder: string[] = byteToUnicode();
  private readonly cache: Map<string, number[]> = new Map<string, number[]>();

  // `merges` lines are "left right" in priority order (a "#version" header line is skipped).
  constructor(vocab: Record<string, number>, merges: string[], config: TokenizerConfig) {
    this.vocab = new Map<string, number>();
    Object.keys(vocab).forEach((token: string) => this.vocab.set(token, vocab[token]));
    this.ranks = new Map<string, number>();
    let rank = 0;
    merges.forEach((line: string) => {
      if (line.length > 0 && !line.startsWith('#version')) {
        this.ranks.set(line, rank++);
      }
    });
    this.special = new Map<string, number>();
    Object.keys(config.special).forEach((token: string) => this.special.set(token, config.special[token]));
    this.splitPattern = new RegExp(config.splitPattern, 'gu');
    this.normalizeNfc = config.normalizeNfc;
  }

  encode(text: string): number[] {
    const ids: number[] = [];
    this.splitSpecial(text).forEach((part: string) => {
      const specialId = this.special.get(part);
      if (specialId !== undefined) {
        ids.push(specialId);
        return;
      }
      const normalized = this.normalizeNfc ? part.normalize('NFC') : part;
      const words = normalized.match(this.splitPattern);
      if (words !== null) {
        words.forEach((word: string) => this.bpe(word).forEach((id: number) => ids.push(id)));
      }
    });
    return ids;
  }

  // Splits out special tokens such as <|im_start|>, which are matched literally and never merged.
  private splitSpecial(text: string): string[] {
    let parts: string[] = [text];
    this.special.forEach((_id: number, token: string) => {
      const next: string[] = [];
      parts.forEach((part: string) => {
        if (this.special.has(part)) {
          next.push(part);
          return;
        }
        part.split(token).forEach((piece: string, index: number) => {
          if (index > 0) {
            next.push(token);
          }
          if (piece.length > 0) {
            next.push(piece);
          }
        });
      });
      parts = next;
    });
    return parts;
  }

  private bpe(word: string): number[] {
    const cached = this.cache.get(word);
    if (cached !== undefined) {
      return cached;
    }
    let symbols: string[] = [];
    utf8Bytes(word).forEach((b: number) => symbols.push(this.byteEncoder[b]));
    while (symbols.length > 1) {
      let bestRank = Number.MAX_SAFE_INTEGER;
      let bestIndex = -1;
      for (let i = 0; i < symbols.length - 1; i++) {
        const rank = this.ranks.get(`${symbols[i]} ${symbols[i + 1]}`);
        if (rank !== undefined && rank < bestRank) {
          bestRank = rank;
          bestIndex = i;
        }
      }
      if (bestIndex < 0) {
        break;
      }
      const left = symbols[bestIndex];
      const right = symbols[bestIndex + 1];
      const merged: string[] = [];
      let i = 0;
      while (i < symbols.length) {
        if (i < symbols.length - 1 && symbols[i] === left && symbols[i + 1] === right) {
          merged.push(left + right);
          i += 2;
        } else {
          merged.push(symbols[i]);
          i += 1;
        }
      }
      symbols = merged;
    }
    const ids: number[] = [];
    symbols.forEach((symbol: string) => {
      const id = this.vocab.get(symbol);
      if (id !== undefined) {
        ids.push(id);
      }
    });
    if (this.cache.size < 4096) {
      this.cache.set(word, ids);
    }
    return ids;
  }
}
