# Toolchain for building the bundled wellbeing-companion model.
# Runs on Linux aarch64 (Docker on Apple silicon) or x86_64; see README.md.
FROM python:3.10-slim

ARG MSL_VERSION=2.3.1
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates g++ && rm -rf /var/lib/apt/lists/*

# On Linux aarch64 the PyPI torch wheel is CPU-only; x86_64 builds should add the CPU index to avoid CUDA wheels.
RUN pip install --no-cache-dir --default-timeout=300 --retries 10 torch==2.4.1 transformers==4.44.2 onnx==1.16.2 onnxruntime==1.19.2 numpy==1.26.4 \
    huggingface_hub==0.24.6 safetensors==0.4.5

# MindSpore Lite converter (produces the .ms format the HarmonyOS MindSpore Lite Kit loads) and benchmark tool.
RUN set -eux; \
    if [ "$TARGETARCH" = "arm64" ]; then MSL_ARCH=aarch64; MSL_PKG=linux-aarch64; else MSL_ARCH=x86_64; MSL_PKG=linux-x64; fi; \
    curl -sSL "https://ms-release.obs.cn-north-4.myhuaweicloud.com/${MSL_VERSION}/MindSpore/lite/release/linux/${MSL_ARCH}/mindspore-lite-${MSL_VERSION}-${MSL_PKG}.tar.gz" \
      | tar xz -C /opt; \
    ln -s /opt/mindspore-lite-${MSL_VERSION}-${MSL_PKG} /opt/msl

ENV LD_LIBRARY_PATH=/opt/msl/tools/converter/lib:/opt/msl/runtime/lib:/opt/msl/runtime/third_party/glog:/opt/msl/runtime/third_party/libjpeg-turbo/lib
# Checks the converted model through the MindSpore Lite runtime (scores and latency).
COPY check_classifier.cc /opt/check_classifier.cc
RUN g++ -O2 -std=c++17 -I/opt/msl/runtime -I/opt/msl/runtime/include /opt/check_classifier.cc \
      -L/opt/msl/runtime/lib -lmindspore-lite -o /usr/local/bin/check_classifier

WORKDIR /work
