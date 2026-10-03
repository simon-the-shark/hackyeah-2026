"""Select the smallest Conductor phase set for the requested workflow profile."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("state_file")
    parser.add_argument("--record", action="store_true")
    args = parser.parse_args()
    state: dict[str, Any] = json.loads(Path(args.state_file).read_text(encoding="utf-8"))
    profile = state.get("workflow_profile", "standard")
    if profile == "quick":
        plan = {
            "profile": "quick",
            "phases": ["product_confirmation", "execution", "focused_verification"],
            "required_approvals": ["product_and_scope"],
            "device_pass": False,
            "full_handover": False,
            "reason": "Low-risk local change; use one confirmation and one focused check.",
        }
    elif profile == "strict":
        plan = {
            "profile": "strict",
            "phases": [
                "initialization", "design_analysis", "strategy", "work_plan_approval",
                "execution", "ui_approval", "self_review_verification", "synchronization", "handover",
            ],
            "required_approvals": ["product", "work_plan", "ui", "device_tests"],
            "device_pass": True,
            "full_handover": True,
            "reason": "High-risk or submission Track; retain complete evidence.",
        }
    else:
        brief = state.get("product_brief", {})
        interaction_text = " ".join(str(brief.get(key, "")) for key in ("core_flow", "mvp", "acceptance_criteria")).lower()
        needs_mvvm = (
            state.get("track_kind") == "ui"
            and (
                sum(token in interaction_text for token in ("add", "complete", "filter", "delete", "edit", "save")) >= 3
                or any(term in interaction_text for term in ("persist", "multiple pages", "shared state"))
            )
        )
        needs_device_approval = state.get("ui_impact") in {"interaction", "runtime"}
        plan = {
            "profile": "standard",
            "phases": [
                "product_confirmation", "work_plan_approval", "execution",
                "focused_verification", "handover",
            ],
            "required_approvals": ["product", "work_plan"] + (["ui", "device_tests"] if needs_device_approval else []),
            "device_pass": needs_device_approval,
            "full_handover": True,
            "required_architecture_skills": ["hmos-arkui-mvvm-pattern"] if needs_mvvm else [],
            "reason": "Normal application work; retain a compact verification record.",
        }
    if args.record:
        state["workflow_plan"] = {
            "status": "recorded",
            "profile": plan["profile"],
            "recorded_by": "workflow_plan.py",
            "required_architecture_skills": plan.get("required_architecture_skills", []),
            "phases": plan["phases"],
        }
        Path(args.state_file).write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"WORKFLOW_PLAN_RECORDED profile={plan['profile']}")
    else:
        print(json.dumps(plan, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
