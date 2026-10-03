"""Complete a low-risk Quick Track without opening the full Conductor chain."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from validate_state import validate_state


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("state_file")
    parser.add_argument("--result", choices=["passed", "blocked"], required=True)
    parser.add_argument("--summary", required=True)
    args = parser.parse_args()
    path = Path(args.state_file)
    state = json.loads(path.read_text(encoding="utf-8"))
    if state.get("workflow_profile") != "quick":
        parser.error("quick_complete requires workflow_profile=quick")
    if state.get("current_phase") != "execution" or state.get("phase_status") != "in_progress":
        parser.error("quick_complete requires current_phase=execution and phase_status=in_progress")
    state["phase_status"] = "completed" if args.result == "passed" else "blocked"
    state["track_status"] = "verified" if args.result == "passed" else "blocked"
    state["last_completed_phase"] = "execution" if args.result == "passed" else state.get("last_completed_phase")
    state["next_phase"] = None
    state["next_action"] = args.summary
    if args.result == "blocked":
        state["blocker"] = args.summary
    errors = validate_state(state)
    if errors:
        for error in errors:
            print(f"QUICK_COMPLETE_BLOCK: {error}")
        return 1
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"QUICK_COMPLETE result={args.result}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
