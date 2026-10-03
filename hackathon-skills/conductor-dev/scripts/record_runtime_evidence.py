"""Record whether the foreground device UI matches the source revision."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--status", choices=["matched", "blocked"], required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--reason", required=True)
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    state["runtime_evidence"] = {
        "status": args.status,
        "source_revision": args.source_revision,
        "reason": args.reason,
        "recorded_by": "record_runtime_evidence.py",
    }
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"RUNTIME_EVIDENCE={args.status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
