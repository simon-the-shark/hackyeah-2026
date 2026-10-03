"""Record and approve a scope change before editing out-of-plan files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--decision", choices=["pending", "approved", "rejected"], required=True)
    parser.add_argument("--reason", required=True)
    parser.add_argument("--file", action="append", default=[])
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    state["scope_change"] = {
        "status": args.decision,
        "reason": args.reason,
        "files": args.file,
    }
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"SCOPE_CHANGE={args.decision}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
