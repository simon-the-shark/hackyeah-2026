"""Generate a compact project bootstrap summary from Conductor state."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument(
        "summary_file",
        nargs="?",
        help="Summary path (default: conductor/bootstrap.md beside the state file)",
    )
    args = parser.parse_args()
    state_path = Path(args.state_file)
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    lines = [
        "# Conductor Bootstrap",
        "",
        f"- Phase: {state.get('current_phase', 'unknown')} ({state.get('phase_status', 'unknown')})",
        f"- Track: {state.get('track_status', 'unknown')}",
        f"- Risk/profile: {state.get('risk_level', 'unset')} / {state.get('execution_profile', 'unset')}",
        f"- Product: {state.get('product_status', 'unset')}",
        f"- Work plan: {state.get('work_plan_status', 'unset')}",
        f"- Required skills: {', '.join(state.get('required_skills', [])) or 'none'}",
        f"- Loaded skills: {', '.join(state.get('loaded_skills', [])) or 'none'}",
        f"- Next action: {state.get('next_action', '')}",
        f"- Blocker: {state.get('blocker') or 'none'}",
    ]
    path = Path(args.summary_file) if args.summary_file else state_path.parent / "conductor" / "bootstrap.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"BOOTSTRAP_SUMMARY_WRITTEN {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
