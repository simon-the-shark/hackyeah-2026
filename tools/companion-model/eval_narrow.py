"""Evaluates the narrow tasks the companion gives its on-device model (synthetic data only):

1. reply: one warm sentence answering the senior's free text (shown to the senior only).
2. classify: does free text mention a health concern? Scored by comparing the model's probability of the
   answers " yes" and " no" after a fixed question; nothing is generated, so nothing can be invented.
"""
import argparse

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPLY_SYSTEM = ("You are a kind companion talking with an older person. Reply to what they said in one short, "
                "warm sentence. Do not ask questions. Do not give medical advice.")
CLASSIFY_SYSTEM = "You check messages from an older person for health worries. Answer only yes or no."

REPLIES = [
    ("Is there anything else you would like to tell your family?", "My granddaughter visited and we baked a cake."),
    ("Is there anything else you would like to tell your family?", "I feel a bit lonely since my husband died."),
    ("Where do you feel it?", "My left knee, when I walk up the stairs."),
    ("Is there anything else you would like to tell your family?", "The weather was lovely, I sat in the garden."),
    ("Is there anything else you would like to tell your family?", "I could not find my glasses all morning."),
]

CLASSIFY = [
    ("I slipped in the bathroom this morning and hit my hip.", True),
    ("My chest feels tight when I climb the stairs.", True),
    ("I have been very dizzy since breakfast.", True),
    ("I don't feel like eating anything these days.", True),
    ("Nobody has called me for a week and I feel so alone.", True),
    ("My granddaughter visited and we baked a cake.", False),
    ("I watched a nice film about birds.", False),
    ("The weather was lovely, I sat in the garden.", False),
    ("I went shopping with my neighbour.", False),
    ("I finished my crossword puzzle.", False),
]


def chat(tok, system, user):
    messages = [{"role": "system", "content": system}, {"role": "user", "content": user}]
    return tok.apply_chat_template(messages, add_generation_prompt=True, return_tensors="pt")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("models", nargs="+")
    args = ap.parse_args()
    for model_id in args.models:
        tok = AutoTokenizer.from_pretrained(model_id)
        model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float32).eval()
        print(f"\n===== {model_id} =====")
        for question, text in REPLIES:
            ids = chat(tok, REPLY_SYSTEM, f'Question: {question}\nThey said: "{text}"')
            with torch.no_grad():
                out = model.generate(ids, max_new_tokens=40, do_sample=False, repetition_penalty=1.15,
                                     attention_mask=torch.ones_like(ids))
            print(f"SAID : {text}\nREPLY: {tok.decode(out[0][ids.shape[1]:], skip_special_tokens=True).strip()}\n")
        yes_id = tok.encode("yes", add_special_tokens=False)[0]
        no_id = tok.encode("no", add_special_tokens=False)[0]
        correct = 0
        for text, concern in CLASSIFY:
            ids = chat(tok, CLASSIFY_SYSTEM, f'Message: "{text}"\nDoes this message mention pain, a fall, '
                                             f'feeling unwell, not eating, or loneliness?')
            with torch.no_grad():
                logits = model(ids).logits[0, -1]
            score = float(logits[yes_id] - logits[no_id])
            correct += (score > 0) == concern
            print(f"{'CONCERN' if concern else 'fine   '} score {score:+.2f}  {text}")
        print(f"{model_id}: classification {correct}/{len(CLASSIFY)} correct at threshold 0")


if __name__ == "__main__":
    main()
