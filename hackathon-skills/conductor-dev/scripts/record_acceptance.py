"""Record one verified product acceptance path."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--path", choices=["add", "complete", "filter", "delete", "persistence"], required=True)
    parser.add_argument("--result", choices=["passed", "blocked", "not_attempted", "out_of_scope"], required=True)
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    results = state.setdefault("acceptance_results", {})
    results[args.path] = {"result": args.result, "recorded_by": "record_acceptance.py"}
    if args.path != "persistence":
        state.setdefault("validation_status", {})["interactions"] = "passed" if args.result == "passed" else "blocked"
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"ACCEPTANCE_RECORDED {args.path}={args.result}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
