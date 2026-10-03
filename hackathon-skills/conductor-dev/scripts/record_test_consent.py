"""Record the user's decision before automated device interaction tests."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--decision", choices=["approved", "declined", "not_required"], required=True)
    parser.add_argument("--phase", default="ui_approval")
    parser.add_argument("--note", default="")
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    state["automated_test_approval"] = {
        "status": args.decision,
        "user_decision": args.note or args.decision,
        "phase": args.phase,
    }
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"AUTOMATED_TEST_CONSENT={args.decision}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
