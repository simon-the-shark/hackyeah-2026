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
this). The device runs float16 kernels (fp32 weights did not fit in the emulator's
memory), and Qwen2.5's residual stream reaches ~1,700, so RMSNorm divides by 16 before
squaring and q and k are each pre-scaled by the square root of the attention scale; both
are exact in float32 and keep float16 intermediates below 65,504.

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Python 3.10, torch, transformers, onnxruntime, MindSpore Lite 2.3.1 converter and runtime |
| `export_classifier.py` | Exports the graph; asserts Hugging Face, the graph and onnxruntime agree; writes tokenizer files and test vectors |
| `weight_quant.cfg` | Converter settings: int8 weight-only quantization |
| `check_classifier.cc` | Runs the `.ms` through the MindSpore Lite runtime (float32); fails if any yes/no decision changes |
| `check_fp16.py` | Runs the graph in float16 with PyTorch, as the device does; fails if any decision changes |
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

## Measured on the HarmonyOS emulator (Pura 90, HarmonyOS 6.1.0 API 23, 4 GB RAM)

From the app's Developer Tools diagnostics, 2026-10-04:

| Check | Result |
| --- | --- |
| System MindSpore Lite loads the 2.3.1 `.ms` | yes |
| Model load in the worker (copy check, tokenizer, build) | ≈ 4.0–5.6 s; first launch also copies 512 MB |
| ArkTS tokenizer vs Hugging Face reference encodings | 6/6 |
| Decisions on the 12 messages at threshold 0.5 | 12/12 (at threshold 0: 11/12) |
| Latency per check | ≈ 190–360 ms (average 224 ms on the final run) |
| App memory (VmRSS) | ≈ 2.2 GB peak while loading, ≈ 1.65–1.8 GB after |

On the device, int8 weights plus float16 kernels raise harmless messages' scores by ~0.4–0.7 (highest
+0.09) while worries stay ≥ 1.50, so the app flags a message only above 0.5. That threshold was chosen
on the same 12 synthetic messages and needs a larger evaluation set.

Failures found on the emulator and fixed: building the model on the UI thread froze the app for more
than 6 s and the watchdog killed it (now a Worker); float32 kernels expanded the weights to ~2 GB and the
low-memory killer stopped the app (now float16 kernels); the original graph overflowed in float16 and
answered "yes" to every message (now overflow-safe, see Graph).
