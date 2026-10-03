# On-device companion model

Builds the model behind the Wellbeing check-in's AI check: Qwen2.5-0.5B-Instruct
(Apache-2.0) reduced to a one-pass yes/no scorer and converted to MindSpore Lite.
Run it through `scripts/build-companion-model.sh`, which writes the app's raw files to
`entry/src/main/resources/rawfile/companion/`.

## What the model does

The app asks one fixed question about the senior's own words:

> Message: "…" — Does this message mention pain, a fall, feeling unwell, not eating, or loneliness?

It compares the model's next-token logits for "yes" and "no" (score = yes − no; above
0 means a possible worry). Nothing is generated. The result only adds a flag next to
fixed keyword rules; the guardian note is a template built from the answers.

## Graph

`export_classifier.py` builds a static-shape graph: `tokens int32[128]` (prompt padded
with `<|endoftext|>`), `length int32[1]` → `scores float32[1,2]`. The tied output
embedding is reduced to the two answer rows, so the 545 MB output matrix is not stored
twice. Every tensor has at most three dimensions, because MindSpore Lite 2.3.1
reinterprets 4-D tensors as NCHW images and scrambled them (`bisect_ops.py` reproduces
this).

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Python 3.10, torch, transformers, onnxruntime, MindSpore Lite 2.3.1 converter and runtime |
| `export_classifier.py` | Exports the graph; asserts Hugging Face, the graph and onnxruntime agree; writes tokenizer files and test vectors |
| `weight_quant.cfg` | Converter settings: int8 weight-only quantization |
| `check_classifier.cc` | Runs the `.ms` through the MindSpore Lite runtime; fails if any yes/no decision changes |
| `eval_narrow.py`, `eval_summaries.py` | Model comparison on synthetic check-ins (why Qwen, and why the model does not write the note) |
| `bisect_ops.py` | Minimal reproduction of the 4-D tensor conversion problem |

## Measured results (synthetic data, Docker linux/arm64 on Apple silicon, 4 threads)

| Check | Result |
| --- | --- |
| Concern detection, 12 synthetic messages (Hugging Face fp32) | 12/12, margins ≥ +1.37 (concern) and ≤ −0.67 (fine) |
| `.ms` int8 weights vs fp32 | 12/12 decisions unchanged, max score difference 0.24 |
| Latency per check / model load | ≈ 1.1–1.3 s / 6–12 s |
| Size | 512 MB `.ms` (518 MB unsigned `.hap`) |

Rejected variants: dynamic int8 quantization changed decisions and took about 20 s per
check; fp16 weights were exact but 990 MB. SmolLM2-135M/360M-Instruct were at chance on
concern detection and invented details in replies and notes; Qwen2.5-0.5B also added
details and medical speculation when asked to write notes, so notes are not generated.

These are measurements on a computer, not on a HarmonyOS device. On-device behaviour
(MindSpore Lite runtime version, memory, latency) has to be verified with the
diagnostics action in the app's Developer Tools.
