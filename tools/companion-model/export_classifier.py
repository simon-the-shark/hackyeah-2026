"""Export the on-device concern check: Qwen2.5-0.5B-Instruct reduced to a one-pass yes/no scorer.

The app asks the model whether a check-in message mentions a health worry and compares the next-token
logits of "yes" and "no". Nothing is generated, so the model cannot invent text. The graph runs the whole
prompt in one call with static shapes:

  inputs   tokens  int32   [N]     prompt token ids, padded at the end to N
           length  int32   [1]     number of real tokens (the answer is read at position length - 1)
  outputs  scores  float32 [1, 2]  logits of "yes" and "no"

Every tensor has at most 3 dimensions: MindSpore Lite reinterprets 4-D tensors as NCHW images and
scrambled them (see bisect_ops.py). The graph is also written to survive float16 kernels, which the device
needs to fit the model in memory: Qwen2.5's residual stream reaches ~1,700, so RMSNorm's sum of squares
(~3e6) and the unscaled attention dot products overflow float16's 65,504. RMSNorm therefore divides by a
constant before squaring, and q and k are each pre-multiplied by the square root of the attention scale.
Both are exact rewrites in float32. The script checks the graph against Hugging Face and onnxruntime and
writes the tokenizer files the app loads (services/companion/BpeTokenizer.ets).
"""
import argparse
import gc
import json
import math
import os

import numpy as np
import onnxruntime as ort
import torch
from torch import nn
from transformers import AutoModelForCausalLM, AutoTokenizer

NEG = -10000.0
# Divides activations inside RMSNorm before squaring: large enough that the largest sum of squares (~3e6 / 16^2)
# stays below float16's 65,504, small enough that the tiny first-layer values do not underflow to zero.
RMS_SCALE = 16.0

# JavaScript has no inline (?i:...) group, so the case-insensitive contractions of Qwen2's split pattern
# are spelled out.
QWEN2_SPLIT = ("'[sS]|'[tT]|'[rR][eE]|'[vV][eE]|'[mM]|'[lL][lL]|'[dD]|[^\\r\\n\\p{L}\\p{N}]?\\p{L}+|\\p{N}"
               "| ?[^\\s\\p{L}\\p{N}]+[\\r\\n]*|\\s*[\\r\\n]+|\\s+(?!\\S)|\\s+")

# Keep in sync with CONCERN_SYSTEM_PROMPT / concernUserPrompt in entry/src/main/ets/services/CheckInScript.ets.
SYSTEM = "You check messages from an older person for health worries. Answer only yes or no."
QUESTION = "Does this message mention pain, a fall, feeling unwell, not eating, or loneliness?"

EXAMPLES = [
    ("I slipped in the bathroom this morning and hit my hip.", True),
    ("My chest feels tight when I climb the stairs.", True),
    ("I have been very dizzy since breakfast.", True),
    ("I don't feel like eating anything these days.", True),
    ("Nobody has called me for a week and I feel so alone.", True),
    ("My left knee, when I walk up the stairs.", True),
    ("My granddaughter visited and we baked a cake.", False),
    ("I watched a nice film about birds.", False),
    ("The weather was lovely, I sat in the garden.", False),
    ("I went shopping with my neighbour.", False),
    ("I finished my crossword puzzle.", False),
    ("Thank you, everything is fine today.", False),
]


class Classifier(nn.Module):
    def __init__(self, hf, n: int, yes_id: int, no_id: int):
        super().__init__()
        cfg = hf.config
        self.layers = hf.model.layers
        self.embed = hf.model.embed_tokens
        self.norm = hf.model.norm
        self.n_heads = cfg.num_attention_heads
        self.n_kv = cfg.num_key_value_heads
        self.head_dim = cfg.hidden_size // cfg.num_attention_heads
        self.eps = cfg.rms_norm_eps
        self.n = n
        inv_freq = 1.0 / (cfg.rope_theta ** (torch.arange(0, self.head_dim, 2, dtype=torch.float32) / self.head_dim))
        freqs = torch.outer(torch.arange(n, dtype=torch.float32), inv_freq)
        emb = torch.cat((freqs, freqs), dim=-1)                          # [N, D]
        self.register_buffer("cos", emb.cos().unsqueeze(0), persistent=False)   # [1, N, D]
        self.register_buffer("sin", emb.sin().unsqueeze(0), persistent=False)
        causal = torch.triu(torch.full((n, n), NEG), diagonal=1)
        self.register_buffer("causal", causal.unsqueeze(0), persistent=False)   # [1, N, N]
        # Each query head reads key/value head (head // groups).
        self.register_buffer("kv_index", torch.arange(self.n_heads) // (self.n_heads // self.n_kv), persistent=False)
        self.register_buffer("answer_rows", torch.tensor([yes_id, no_id]), persistent=False)

    @staticmethod
    def rms(x, weight, eps):
        # rms(x) == rms(x / s) for any s > 0 (with eps scaled by 1 / s^2); s keeps the squares in float16 range.
        y = x * (1.0 / RMS_SCALE)
        return weight * (y * torch.rsqrt(y.pow(2).mean(-1, keepdim=True) + eps / (RMS_SCALE * RMS_SCALE)))

    def rotate(self, x):
        half = self.head_dim // 2
        return x * self.cos + torch.cat((-x[..., half:], x[..., :half]), dim=-1) * self.sin

    def heads(self, x, count):
        return x.view(self.n, count, self.head_dim).transpose(0, 1)      # [count, N, D]

    def forward(self, tokens, length):
        # Applied to q and k separately so their dot product is never formed unscaled (float16 overflow).
        half_scale = 1.0 / math.sqrt(math.sqrt(self.head_dim))
        h = self.embed(tokens.to(torch.int64))                          # [N, hidden]
        for layer in self.layers:
            attn = layer.self_attn
            x = self.rms(h, layer.input_layernorm.weight, self.eps)
            q = self.rotate(self.heads(attn.q_proj(x), self.n_heads)) * half_scale
            k = self.rotate(self.heads(attn.k_proj(x), self.n_kv)) * half_scale
            v = self.heads(attn.v_proj(x), self.n_kv)
            k = torch.index_select(k, 0, self.kv_index)                 # [H, N, D]
            v = torch.index_select(v, 0, self.kv_index)
            probs = torch.softmax(torch.matmul(q, k.transpose(1, 2)) + self.causal, dim=-1)
            out = torch.matmul(probs, v).transpose(0, 1).reshape(self.n, self.n_heads * self.head_dim)
            h = h + attn.o_proj(out)
            x = self.rms(h, layer.post_attention_layernorm.weight, self.eps)
            mlp = layer.mlp
            h = h + mlp.down_proj(nn.functional.silu(mlp.gate_proj(x)) * mlp.up_proj(x))
        last = torch.index_select(h, 0, (length - 1).to(torch.int64))   # [1, hidden]
        last = self.rms(last, self.norm.weight, self.eps)
        rows = torch.index_select(self.embed.weight, 0, self.answer_rows)  # tied output embedding, 2 rows
        return torch.matmul(last, rows.transpose(0, 1))                  # [1, 2]


def chat(tok, message):
    messages = [{"role": "system", "content": SYSTEM},
                {"role": "user", "content": f'Message: "{message}"\n{QUESTION}'}]
    return tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)


def padded(ids, n, pad):
    return np.array(ids + [pad] * (n - len(ids)), np.int32), np.array([len(ids)], np.int32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B-Instruct")
    ap.add_argument("--out", default="/work/out")
    ap.add_argument("--n", type=int, default=128)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    tok = AutoTokenizer.from_pretrained(args.model)
    hf = AutoModelForCausalLM.from_pretrained(args.model, torch_dtype=torch.float32).eval()
    yes_id = tok.encode("yes", add_special_tokens=False)[0]
    no_id = tok.encode("no", add_special_tokens=False)[0]
    pad_id = tok.convert_tokens_to_ids("<|endoftext|>")
    model = Classifier(hf, args.n, yes_id, no_id).eval()

    # Reference scores first, then export, then free the torch model before onnxruntime loads its own copy:
    # holding all three at once does not fit in an 8 GB Docker VM.
    checks = []
    with torch.no_grad():
        for message, concern in EXAMPLES:
            ids = tok(chat(tok, message), add_special_tokens=False)["input_ids"]
            assert len(ids) <= args.n, f"prompt too long ({len(ids)} tokens)"
            ref = hf(torch.tensor([ids])).logits[0, -1]
            tokens, length = padded(ids, args.n, pad_id)
            mine = model(torch.from_numpy(tokens), torch.from_numpy(length))[0]
            checks.append({"message": message, "concern": concern, "promptIds": ids,
                           "score": float(ref[yes_id] - ref[no_id]), "graphScore": float(mine[0] - mine[1])})

    onnx_path = os.path.join(args.out, "concern_classifier.onnx")
    dummy = padded([1, 2, 3], args.n, pad_id)
    with torch.no_grad():
        torch.onnx.export(model, (torch.from_numpy(dummy[0]), torch.from_numpy(dummy[1])), onnx_path,
                          opset_version=14, input_names=["tokens", "length"], output_names=["scores"])
    del model, hf
    gc.collect()
    sess = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])

    correct = 0
    for check in checks:
        tokens, length = padded(check["promptIds"], args.n, pad_id)
        onnx = sess.run(None, {"tokens": tokens, "length": length})[0][0]
        onnx_score = float(onnx[0] - onnx[1])
        assert abs(check["score"] - check["graphScore"]) < 1e-2 and abs(check["score"] - onnx_score) < 1e-2, check
        correct += (check["score"] > 0) == check["concern"]
        print(f"{'CONCERN' if check['concern'] else 'fine   '} HF {check['score']:+.3f} onnx {onnx_score:+.3f} "
              f"({len(check['promptIds'])} tokens) {check['message']}")
    print(f"{correct}/{len(EXAMPLES)} correct at threshold 0")

    tok_dir = os.path.join(args.out, "tokenizer")
    os.makedirs(tok_dir, exist_ok=True)
    tok.save_pretrained(tok_dir)
    special = {t.content: i for i, t in tok.added_tokens_decoder.items()}
    with open(os.path.join(args.out, "tokenizer_config.json"), "w") as f:
        json.dump({"splitPattern": QWEN2_SPLIT, "normalizeNfc": True, "special": special}, f)
    samples = ["Hello!", "I slept badly, my knee hurts a bit. Don't worry  — I'm fine :)",
               "Mood: 4/5. Ate soup at 12:30, talked to Anna.\n\nThanks", "Zażółć gęślą jaźń 😀 café",
               "I'VE been OK, it's 2026", chat(tok, "My chest feels tight.")]
    with open(os.path.join(args.out, "tokenizer_vectors.json"), "w") as f:
        json.dump([{"text": s, "ids": tok(s, add_special_tokens=False)["input_ids"]} for s in samples], f,
                  ensure_ascii=False)
    with open(os.path.join(args.out, "model_meta.json"), "w") as f:
        json.dump({"model": args.model, "maxTokens": args.n, "padId": pad_id, "checks": checks}, f)
    # Input for check_classifier (MindSpore Lite runtime check): "<expected score> <ids...>" per line.
    with open(os.path.join(args.out, "check_prompts.txt"), "w") as f:
        f.writelines(f"{c['score']} {' '.join(map(str, c['promptIds']))}\n" for c in checks)
    print("exported", onnx_path)


if __name__ == "__main__":
    main()
