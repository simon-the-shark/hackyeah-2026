"""Converts tiny graphs that each use one construct of the step model and compares MindSpore Lite with
onnxruntime, to find constructs the converter or runtime mishandles."""
import os
import subprocess

import numpy as np
import onnxruntime as ort
import torch
from torch import nn

CONVERTER = "/opt/msl/tools/converter/converter/converter_lite"
BENCH = "/opt/msl/tools/benchmark/benchmark"


class Embed(nn.Module):
    def __init__(self):
        super().__init__()
        self.e = nn.Embedding(100, 8)

    def forward(self, token):
        return self.e(token.to(torch.int64))


class Rope(nn.Module):
    def __init__(self):
        super().__init__()
        self.register_buffer("inv", torch.linspace(1.0, 0.01, 4))

    def forward(self, position):
        f = position.to(torch.float32) * self.inv
        e = torch.cat((f, f), dim=-1)
        return torch.cos(e) + 2 * torch.sin(e)


class Mask(nn.Module):
    def __init__(self):
        super().__init__()
        self.register_buffer("slots", torch.arange(8, dtype=torch.float32))

    def forward(self, position):
        p = position.to(torch.float32)
        m = torch.where(self.slots < p, torch.zeros_like(self.slots), torch.full_like(self.slots, -10000.0))
        return torch.cat((m, torch.zeros(1)), dim=0)


class Rms(nn.Module):
    def __init__(self):
        super().__init__()
        self.w = nn.Parameter(torch.linspace(0.5, 1.5, 8))

    def forward(self, x):
        return self.w * (x * torch.rsqrt(x.pow(2).mean(-1, keepdim=True) + 1e-5))


class PastIndex(nn.Module):
    def forward(self, past):
        k = torch.ones(3, 2)
        return torch.cat((past[1], k.unsqueeze(1)), dim=1) * 2.0


class PastSlice3d(nn.Module):
    # Cache as [layers * kv, max, d]; layer 1 of 2 kv heads is rows 2..3.
    def forward(self, past):
        k = torch.ones(2, 2)
        layer = past[2:4]
        keys = torch.cat((layer, k.unsqueeze(1)), dim=1)
        q = torch.ones(2, 3, 2)
        return torch.softmax(torch.matmul(q, keys.transpose(1, 2)), dim=-1)


CASES = [
    ("embed", Embed(), np.array([42], np.int32)),
    ("rope", Rope(), np.array([5], np.int32)),
    ("mask", Mask(), np.array([3], np.int32)),
    ("rms", Rms(), np.random.default_rng(0).standard_normal((1, 8)).astype(np.float32)),
    ("past_index", PastIndex(), np.random.default_rng(1).standard_normal((4, 3, 5, 2)).astype(np.float32)),
    ("past_3d", PastSlice3d(), np.random.default_rng(2).standard_normal((6, 5, 2)).astype(np.float32)),
]

os.makedirs("/tmp/bisect", exist_ok=True)
for name, module, x in CASES:
    onnx_path = f"/tmp/bisect/{name}.onnx"
    torch.onnx.export(module.eval(), (torch.from_numpy(x),), onnx_path, opset_version=14,
                      input_names=["x"], output_names=["y"])
    expected = ort.InferenceSession(onnx_path).run(None, {"x": x})[0]
    subprocess.run([CONVERTER, "--fmk=ONNX", f"--modelFile={onnx_path}", f"--outputFile=/tmp/bisect/{name}"],
                   capture_output=True)
    x.tofile(f"/tmp/bisect/{name}.bin")
    with open(f"/tmp/bisect/{name}.txt", "w") as f:
        f.write(f"y {expected.ndim} {' '.join(map(str, expected.shape))}\n")
        f.write(" ".join(f"{v:.6f}" for v in expected.reshape(-1)) + "\n")
    out = subprocess.run([BENCH, f"--modelFile=/tmp/bisect/{name}.ms", f"--inDataFile=/tmp/bisect/{name}.bin",
                          f"--benchmarkDataFile=/tmp/bisect/{name}.txt", "--accuracyThreshold=100"],
                         capture_output=True, text=True).stdout
    bias = [line for line in out.splitlines() if "Mean bias of all" in line]
    got = [line for line in out.splitlines() if line.startswith("Data of node")]
    print(f"{name:11s} {bias[0] if bias else 'NO RESULT'}")
    if not bias or "0%" not in bias[0]:
        print("   expected:", " ".join(f"{v:.4f}" for v in expected.reshape(-1)[:10]))
        print("   got     :", got[0][:160] if got else out[-400:])
