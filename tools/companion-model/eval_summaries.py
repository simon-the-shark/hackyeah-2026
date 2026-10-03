"""Compare candidate models on synthetic check-ins with the app's real prompts (services/CheckInScript.ets).

Prints each generated note next to the facts so faithfulness can be reviewed by a person, plus a crude
automatic check for contradictions (mentions of pain, low mood or missed medicines that the facts do not
support). Synthetic data only.
"""
import argparse
import re

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

SYSTEM = ("You write a short, warm note for a family member about how their older relative is doing today. "
          "Use only the facts given. Do not add anything new. Do not give medical advice or diagnoses. "
          "Write two short sentences in the third person.")

CASES = [
    {"lines": ["Mood: good (4 of 5)", "Sleep: slept well", "Pain: no pain", "Medicines today: taken",
               "Eating and drinking: yes", "Talked with someone: yes"], "bad": ["pain", "down", "sad", "not taken"]},
    {"lines": ["Mood: low (2 of 5)", "Sleep: slept badly", "Pain: a little pain (knee)", "Medicines today: taken",
               "Eating and drinking: yes", "Talked with someone: not yet"], "bad": ["great", "happy", "no pain"]},
    {"lines": ["Mood: okay (3 of 5)", "Sleep: slept okay", "Pain: no pain", "Medicines today: not yet",
               "Eating and drinking: not really", "Talked with someone: yes"], "bad": ["pain", "has taken"]},
    {"lines": ["Mood: very good (5 of 5)", "Sleep: slept well", "Pain: no pain", "Medicines today: taken",
               "Eating and drinking: yes", "Talked with someone: yes", 'They said: "My granddaughter visited."'],
     "bad": ["pain", "sad", "tired"]},
    {"lines": ["Mood: very bad (1 of 5)", "Sleep: slept badly", "Pain: strong pain (back)",
               "Medicines today: not sure", "Eating and drinking: not really", "Talked with someone: not yet"],
     "bad": ["great", "happy", "well", "no pain"]},
]


def user_prompt(lines):
    return "Facts:\n" + "\n".join(f"- {line}" for line in lines) + "\nWrite the note."


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("models", nargs="+")
    ap.add_argument("--tokens", type=int, default=90)
    args = ap.parse_args()
    for model_id in args.models:
        tok = AutoTokenizer.from_pretrained(model_id)
        model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float32).eval()
        flagged = 0
        print(f"\n===== {model_id} =====")
        for case in CASES:
            messages = [{"role": "system", "content": SYSTEM}, {"role": "user", "content": user_prompt(case["lines"])}]
            ids = tok.apply_chat_template(messages, add_generation_prompt=True, return_tensors="pt")
            with torch.no_grad():
                out = model.generate(ids, max_new_tokens=args.tokens, do_sample=False, repetition_penalty=1.15,
                                     attention_mask=torch.ones_like(ids))
            text = tok.decode(out[0][ids.shape[1]:], skip_special_tokens=True).strip()
            hits = [w for w in case["bad"] if re.search(rf"\b{re.escape(w)}\b", text.lower())]
            flagged += bool(hits)
            print(f"\nFACTS: {'; '.join(case['lines'])}\nNOTE : {text}\nFLAGS: {hits or '-'}")
        print(f"\n{model_id}: {flagged}/{len(CASES)} notes flagged")


if __name__ == "__main__":
    main()
