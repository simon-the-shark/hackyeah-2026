"""Record the actual build/sign/device boundary result."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--status", choices=["passed", "blocked"], required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--packaging-revision", required=True)
    parser.add_argument("--signing", choices=["not_configured", "skipped", "passed", "failed"], required=True)
    parser.add_argument("--reason", required=True)
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    if state.get("verification_gate", {}).get("last_mode") != "phase-boundary" or state.get("verification_gate", {}).get("status") != "passed":
        print("BOUNDARY_BLOCK: phase-boundary gate must pass before recording result")
        return 1
    state["verification_boundary"] = {
        "status": args.status,
        "reason": args.reason,
        "source_revision": args.source_revision,
        "packaging_revision": args.packaging_revision,
        "runtime_impact": state.get("ui_impact") in {"interaction", "runtime"},
        "signing": args.signing,
        "recorded_by": "record_boundary.py",
    }
    state.setdefault("validation_status", {})["build"] = "passed" if args.status == "passed" else "blocked"
    state.setdefault("validation_status", {})["device"] = "passed" if args.status == "passed" else "blocked"
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"BOUNDARY_RECORDED status={args.status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
