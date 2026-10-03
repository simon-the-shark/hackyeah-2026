"""Initialize risk/profile state without writing an invalid combination."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--risk", choices=["low", "medium", "high"], required=True)
    parser.add_argument("--profile", choices=["lean", "strict"], required=True)
    parser.add_argument("--track-kind", choices=["ui", "logic", "infrastructure"], required=True)
    parser.add_argument("--ui-impact", choices=["none", "visual", "interaction", "runtime"], required=True)
    parser.add_argument("--workflow-profile", choices=["quick", "standard", "strict"], default="standard")
    parser.add_argument("--token-budget", type=int)
    parser.add_argument("--risk-signal", action="append", choices=["persistence", "device", "network", "security", "architecture"], default=[])
    args = parser.parse_args()
    if args.profile == "lean" and args.risk != "low":
        parser.error("lean is only valid for low risk Tracks")
    if args.profile == "lean" and args.risk_signal:
        parser.error("risk signals require strict execution")
    path = Path(args.state_file)
    if path.exists():
        state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    else:
        template = Path(__file__).resolve().parent.parent / "assets" / "conductor-template" / "setup_state.json"
        state = json.loads(template.read_text(encoding="utf-8"))
        path.parent.mkdir(parents=True, exist_ok=True)
    state.update({
        "risk_level": args.risk,
        "execution_profile": args.profile,
        "track_kind": args.track_kind,
        "ui_impact": args.ui_impact,
        "risk_signals": args.risk_signal,
        "workflow_profile": args.workflow_profile,
        "token_budget": args.token_budget or {"quick": 40000, "standard": 80000, "strict": 140000}[args.workflow_profile],
        "command_output_budget": "compact",
    })
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"state initialized: risk={args.risk} profile={args.profile}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
