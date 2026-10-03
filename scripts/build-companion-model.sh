#!/usr/bin/env bash
# Builds the on-device concern-check model and copies it into the app's raw files.
#
# Downloads Qwen2.5-0.5B-Instruct (Apache-2.0) from Hugging Face, exports the one-pass yes/no graph, converts
# it to MindSpore Lite (.ms, int8 weights) and checks the converted model against Hugging Face scores through
# the MindSpore Lite runtime. Runs in Docker (linux/arm64 or amd64); needs ~12 GB Docker memory and ~8 GB disk.
# Run once before building the .hap; the outputs are git-ignored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/tools/companion-model"
WORK="$TOOLS/.work"
DEST="$ROOT/entry/src/main/resources/rawfile/companion"
IMAGE="carely-companion-model"

mkdir -p "$WORK/out" "$WORK/hf-cache" "$DEST"

echo "==> Building the toolchain image"
docker build -t "$IMAGE" "$TOOLS"

run() {
  docker run --rm -v "$TOOLS:/src:ro" -v "$WORK/out:/work/out" -v "$WORK/hf-cache:/root/.cache/huggingface" \
    -e HF_HUB_DOWNLOAD_TIMEOUT=120 "$IMAGE" "$@"
}

echo "==> Exporting and checking the classifier graph (Hugging Face vs ONNX)"
run python /src/export_classifier.py --out /work/out

echo "==> Checking the graph in float16 (the device runs float16 kernels)"
run bash -c 'cd /src && PYTHONDONTWRITEBYTECODE=1 python check_fp16.py'

echo "==> Converting to MindSpore Lite with int8 weights"
run bash -c 'cd /work/out && rm -f concern_classifier.ms && /opt/msl/tools/converter/converter/converter_lite \
  --fmk=ONNX --modelFile=concern_classifier.onnx --outputFile=concern_classifier --configFile=/src/weight_quant.cfg'

echo "==> Checking the converted model through the MindSpore Lite runtime"
run bash -c 'check_classifier /work/out/concern_classifier.ms 128 \
  "$(python -c "import json; print(json.load(open(\"/work/out/model_meta.json\"))[\"padId\"])")" \
  < /work/out/check_prompts.txt'

echo "==> Copying into $DEST"
cp "$WORK/out/concern_classifier.ms" "$DEST/"
cp "$WORK/out/tokenizer/vocab.json" "$WORK/out/tokenizer/merges.txt" "$DEST/"
cp "$WORK/out/tokenizer_config.json" "$WORK/out/tokenizer_vectors.json" "$DEST/"
python3 - "$WORK/out/model_meta.json" "$DEST/model_meta.json" "$DEST/concern_classifier.ms" <<'EOF'
import hashlib, json, sys
meta = json.load(open(sys.argv[1]))
digest = hashlib.sha256()
with open(sys.argv[3], "rb") as model:
    for chunk in iter(lambda: model.read(1 << 20), b""):
        digest.update(chunk)
# The app needs the shape and padding; the check prompts let the diagnostics screen re-run the scores on device.
# modelHash names the app's cached copy, so a rebuilt model is never mistaken for the old one.
json.dump({"model": meta["model"], "maxTokens": meta["maxTokens"], "padId": meta["padId"],
           "modelHash": digest.hexdigest()[:16],
           "checks": [{"message": c["message"], "concern": c["concern"], "score": c["score"]} for c in meta["checks"]]},
          open(sys.argv[2], "w"))
EOF
ls -la "$DEST"
echo "Done. Large intermediates are in $WORK (safe to delete)."
