"""Record the standard approved product/work-plan execution state quietly."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def set_path(root: dict[str, Any], path: str, value: Any) -> None:
    parts = path.split(".")
    current: dict[str, Any] = root
    for part in parts[:-1]:
        child = current.get(part)
        if not isinstance(child, dict):
            child = {}
            current[part] = child
        current = child
    current[parts[-1]] = value


def main() -> int:
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("state_file", type=Path)
    parser.add_argument("brief_file", type=Path)
    parser.add_argument("--skill", action="append", default=[])
    args = parser.parse_args()

    state = json.loads(args.state_file.read_text(encoding="utf-8"))
    brief = json.loads(args.brief_file.read_text(encoding="utf-8"))
    assumptions = brief.pop("assumptions", [
        "Local on-device persistence",
        "Phone emulator target",
        "No accounts, sync, or AI",
    ])
    for key, value in brief.items():
        set_path(state, f"product_brief.{key}", value)
    set_path(state, "product_status", "confirmed")
    set_path(state, "product_confirmation.user_confirmed", True)
    set_path(state, "product_confirmation.decision", "approved")
    set_path(state, "product_confirmation.assumptions", assumptions)
    set_path(state, "work_plan_status", "approved")
    set_path(state, "required_skills", args.skill)
    set_path(state, "current_phase", "execution")
    set_path(state, "phase_status", "in_progress")
    set_path(state, "track_status", "in_progress")
    set_path(state, "phase_requires_boundary_pass", True)
    set_path(state, "verification_boundary.status", "pending")
    set_path(state, "ui_checkpoint.status", "pending")
    set_path(state, "next_phase", "ui_approval")
    args.state_file.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Execution state recorded.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
