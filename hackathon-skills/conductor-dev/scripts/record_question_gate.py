"""Record a user decision made through the interactive question tool."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("state_file")
    parser.add_argument("--decision", choices=["approved", "declined"], required=True)
    parser.add_argument("--kind", choices=["product", "work_plan", "ui", "device_tests"], required=True)
    parser.add_argument("--method", choices=["interactive_question", "fallback_text"], required=True)
    parser.add_argument("--note", default="")
    args = parser.parse_args()
    path = Path(args.state_file)
    state = json.loads(path.read_text(encoding="utf-8"))
    gate = state.setdefault("question_gate", {"status": "pending", "method": None, "decisions": {}})
    gate["method"] = args.method
    gate.setdefault("decisions", {})[args.kind] = {
        "decision": args.decision,
        "note": args.note,
        "recorded_by": "record_question_gate.py",
    }
    gate["status"] = "approved" if all(item.get("decision") == "approved" for item in gate["decisions"].values()) else "pending"
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"QUESTION_GATE_RECORDED kind={args.kind} decision={args.decision} method={args.method}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
