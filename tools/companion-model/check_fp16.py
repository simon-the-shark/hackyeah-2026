"""Simulates the concern classifier in float16 with PyTorch, as the device runs it (MindSpore Lite with
precisionMode 'preferred_fp16'). The Docker check (check_classifier) only exercises float32, and on the emulator
an earlier graph overflowed in float16 and flagged every message. Fails if any yes/no decision changes.
Usage: python check_fp16.py  (needs the model in the Hugging Face cache)."""
import sys

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

import export_classifier as ec


def scores(model, tok, pad):
    out = []
    for message, _ in ec.EXAMPLES:
        ids = tok(ec.chat(tok, message), add_special_tokens=False)["input_ids"]
        tokens, length = ec.padded(ids, 128, pad)
        with torch.no_grad():
            r = model(torch.from_numpy(tokens), torch.from_numpy(length))[0].float()
        out.append(float(r[0] - r[1]))
    return out


def main():
    model_id = "Qwen/Qwen2.5-0.5B-Instruct"
    tok = AutoTokenizer.from_pretrained(model_id)
    hf = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float32).eval()
    yes, no = tok.encode("yes")[0], tok.encode("no")[0]
    pad = tok.convert_tokens_to_ids("<|endoftext|>")
    full = scores(ec.Classifier(hf, 128, yes, no).eval(), tok, pad)
    half = scores(ec.Classifier(hf, 128, yes, no).half().eval(), tok, pad)
    flipped = 0
    for (message, _), a, b in zip(ec.EXAMPLES, full, half):
        flipped += (a > 0) != (b > 0) or b != b
        print(f"fp32 {a:+.2f}  fp16 {b:+.2f}  {message}")
    print(f"flipped {flipped}, max diff {max(abs(a - b) for a, b in zip(full, half)):.3f}")
    sys.exit(1 if flipped else 0)


if __name__ == "__main__":
    main()
