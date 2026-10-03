"""Write one phase summary from the authoritative Conductor state."""

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
        help="Phase summary path (default: artifacts/conductor-summary.md beside the state file)",
    )
    parser.add_argument(
        "--tasks-file",
        help="Optional TASKS.md to update at the same phase boundary",
    )
    parser.add_argument(
        "--task-id",
        required=True,
        help="Task identifier whose checkbox should be marked complete",
    )
    args = parser.parse_args()
    state_path = Path(args.state_file)
    summary_path = Path(args.summary_file) if args.summary_file else state_path.parent / "artifacts" / "conductor-summary.md"
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    acceptance = state.get("acceptance_results", {})
    required_acceptance = {"add", "complete", "filter", "delete", "persistence"}
    missing_acceptance = sorted(required_acceptance - acceptance.keys())
    if missing_acceptance:
        raise SystemExit("sync_phase requires acceptance results: " + ", ".join(missing_acceptance))
    if state.get("current_phase") != "synchronization" or state.get("phase_status") != "in_progress":
        raise SystemExit("sync_phase requires current_phase=synchronization and phase_status=in_progress")
    if not isinstance(state.get("next_action"), str) or not state.get("next_action", "").strip():
        raise SystemExit("sync_phase requires --next-action \"...\" or a non-empty next_action")
    state["phase_status"] = "completed"
    state["track_status"] = "verified"
    state["last_completed_phase"] = "synchronization"
    state["next_phase"] = "handover"
    state["synchronization_record"] = {
        "status": "completed",
        "phase": "synchronization",
        "task_id": args.task_id,
        "summary_file": str(summary_path),
    }
    boundary = state.get("verification_boundary", {})
    lines = [
        f"# Phase Summary: {state.get('current_phase', 'unknown')}",
        "",
        f"- Phase status: {state.get('phase_status', 'unknown')}",
        f"- Track status: {state.get('track_status', 'unknown')}",
        f"- Risk: {state.get('risk_level', 'unset')}",
        f"- Execution profile: {state.get('execution_profile', 'unset')}",
        f"- Track kind: {state.get('track_kind', 'unset')}",
        f"- UI impact: {state.get('ui_impact', 'unset')}",
        f"- Boundary pass: {boundary.get('status', 'unknown')}",
        f"- Signing: {boundary.get('signing', 'unknown')}",
        f"- Next action: {state.get('next_action', '')}",
    ]
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    if args.tasks_file and args.task_id and state.get("phase_status") == "completed":
        tasks_path = Path(args.tasks_file)
        task_lines = tasks_path.read_text(encoding="utf-8").splitlines()
        matches = [index for index, line in enumerate(task_lines) if args.task_id in line and line.lstrip().startswith(("- [ ]", "- [x]"))]
        if matches:
            first = matches[0]
            task_lines[first] = task_lines[first].replace("- [ ]", "- [x]", 1)
            for index in reversed(matches[1:]):
                del task_lines[index]
            tasks_path.write_text("\n".join(task_lines) + "\n", encoding="utf-8")
            print(f"task synchronized idempotently: {args.task_id}")
        else:
            print(f"task not found: {args.task_id}")
            return 1
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"phase summary written: {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
