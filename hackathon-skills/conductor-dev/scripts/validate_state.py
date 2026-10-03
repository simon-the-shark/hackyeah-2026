"""Validate a Conductor SESSION_STATE.json transition state."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


PHASES = {
    "initialization",
    "design_analysis",
    "strategy",
    "work_plan_approval",
    "execution",
    "ui_approval",
    "self_review_verification",
    "synchronization",
    "handover",
}
PHASE_ORDER = [
    "initialization",
    "design_analysis",
    "strategy",
    "work_plan_approval",
    "execution",
    "ui_approval",
    "self_review_verification",
    "synchronization",
    "handover",
]
PHASE_STATUSES = {"pending", "in_progress", "blocked", "completed"}
BOUNDARY_STATUSES = {"not_required", "pending", "gate_passed", "in_progress", "passed", "blocked"}
TRACK_STATUSES = {
    "not_started",
    "in_progress",
    "awaiting_ui_approval",
    "blocked",
    "verified",
    "handed_over",
}
PROFILES = {None, "lean", "strict"}
RISKS = {None, "low", "medium", "high"}
TRACK_KINDS = {None, "ui", "logic", "infrastructure"}
UI_IMPACTS = {None, "none", "visual", "interaction", "runtime"}
WORKFLOW_PROFILES = {None, "quick", "standard", "strict"}
PRODUCT_STATUSES = {"unconfirmed", "direction_selected", "brief_pending", "confirmed", "assumptions_accepted"}
WORK_PLAN_STATUSES = {"pending", "approved", "changes_requested"}
UI_CHECKPOINT_STATUSES = {"not_required", "pending", "accepted", "blocked"}


def non_empty(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


class DuplicateKeyError(ValueError):
    pass


def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def validate_state(state: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    required = {
        "current_phase",
        "phase_status",
        "track_status",
        "last_completed_phase",
        "next_phase",
    }
    for key in sorted(required - state.keys()):
        errors.append(f"missing required field: {key}")

    current = state.get("current_phase")
    phase_status = state.get("phase_status")
    track_status = state.get("track_status")
    last_completed = state.get("last_completed_phase")
    next_phase = state.get("next_phase")

    if current not in PHASES:
        errors.append(f"current_phase must be one of: {', '.join(sorted(PHASES))}")
    if phase_status not in PHASE_STATUSES:
        errors.append(
            "phase_status must be one of: " + ", ".join(sorted(PHASE_STATUSES))
        )
    if track_status not in TRACK_STATUSES:
        errors.append(
            "track_status must be one of: " + ", ".join(sorted(TRACK_STATUSES))
        )
    if last_completed is not None and last_completed not in PHASES:
        errors.append("last_completed_phase must be null or a known phase")
    if next_phase is not None and next_phase not in PHASES:
        errors.append("next_phase must be null or a known phase")
    if state.get("execution_profile") not in PROFILES:
        errors.append("execution_profile must be null, lean, or strict")
    if state.get("risk_level") not in RISKS:
        errors.append("risk_level must be null, low, medium, or high")
    workflow_profile = state.get("workflow_profile")
    if workflow_profile not in WORKFLOW_PROFILES:
        errors.append("workflow_profile must be null, quick, standard, or strict")
    if workflow_profile == "quick" and state.get("risk_level") != "low":
        errors.append("quick workflow_profile is only valid for low risk Tracks")
    if workflow_profile == "quick" and state.get("risk_signals"):
        errors.append("quick workflow_profile cannot use device, persistence, network, security, or architecture risk signals")
    if state.get("execution_profile") == "lean" and state.get("risk_level") != "low":
        errors.append("lean execution_profile is only valid for low risk Tracks")
    risk_signals = state.get("risk_signals")
    if not isinstance(risk_signals, list) or not all(item in {"persistence", "device", "network", "security", "architecture"} for item in risk_signals):
        errors.append("risk_signals must be a list of known risk signals")
    brief_data = state.get("product_brief", {}).get("data_behavior", "") if isinstance(state.get("product_brief"), dict) else ""
    if state.get("execution_profile") == "lean" and any(term in str(brief_data).lower() for term in ("persist", "preference", "本地", "存储")):
        errors.append("persistent data behavior requires strict execution")
    if state.get("product_status") not in PRODUCT_STATUSES:
        errors.append("product_status must be unconfirmed, direction_selected, brief_pending, confirmed, or assumptions_accepted")
    if state.get("track_kind") not in TRACK_KINDS:
        errors.append("track_kind must be null, ui, logic, or infrastructure")
    if state.get("ui_impact") not in UI_IMPACTS:
        errors.append("ui_impact must be null, none, visual, interaction, or runtime")
    if state.get("track_kind") == "ui" and state.get("ui_impact") == "none":
        errors.append("UI tracks cannot use ui_impact=none")
    if state.get("track_kind") in {"logic", "infrastructure"} and state.get("ui_impact") not in {None, "none"}:
        errors.append("non-UI tracks must use ui_impact=null or none")

    product_brief = state.get("product_brief")
    required_brief_fields = {
        "problem", "primary_user", "desired_outcome", "core_flow", "mvp",
        "non_goals", "target_device", "data_behavior", "visual_direction",
        "acceptance_criteria",
    }
    if not isinstance(product_brief, dict):
        errors.append("product_brief must be an object")
    else:
        missing_brief = required_brief_fields - product_brief.keys()
        if missing_brief:
            errors.append("product_brief is missing: " + ", ".join(sorted(missing_brief)))

    confirmation = state.get("product_confirmation")
    if not isinstance(confirmation, dict):
        errors.append("product_confirmation must be an object")
    else:
        if not isinstance(confirmation.get("user_confirmed"), bool):
            errors.append("product_confirmation.user_confirmed must be boolean")
        if not isinstance(confirmation.get("assumptions"), list):
            errors.append("product_confirmation.assumptions must be a list")
        if state.get("product_status") in {"confirmed", "assumptions_accepted"}:
            if confirmation.get("user_confirmed") is not True:
                errors.append("confirmed product status requires explicit user confirmation")
            if state.get("product_status") == "assumptions_accepted" and not confirmation.get("assumptions"):
                errors.append("assumptions_accepted requires recorded assumptions")
            if isinstance(product_brief, dict):
                confirmed_fields = required_brief_fields
                if state.get("workflow_profile") == "quick":
                    confirmed_fields = {"problem", "desired_outcome", "mvp", "acceptance_criteria"}
                for field in confirmed_fields:
                    if not non_empty(product_brief.get(field)):
                        errors.append(f"confirmed product brief requires non-empty {field}")

    if state.get("work_plan_status") not in WORK_PLAN_STATUSES:
        errors.append("work_plan_status must be pending, approved, or changes_requested")

    recovery = state.get("recovery")
    if not isinstance(recovery, dict) or recovery.get("status") not in {"none", "required", "recorded"}:
        errors.append("recovery.status must be none, required, or recorded")
    sync_record = state.get("synchronization_record")
    if not isinstance(sync_record, dict) or sync_record.get("status") not in {"not_started", "completed"}:
        errors.append("synchronization_record.status must be not_started or completed")
    authorization = state.get("execution_authorization")
    if not isinstance(authorization, dict) or authorization.get("status") not in {"pending", "approved", "revoked"}:
        errors.append("execution_authorization.status must be pending, approved, or revoked")
    if isinstance(authorization, dict) and authorization.get("status") == "approved":
        if not authorization.get("phase") or not authorization.get("token") or not authorization.get("authorized_revision"):
            errors.append("approved execution authorization requires phase, token, and authorized_revision")

    required_skills = state.get("required_skills")
    if not isinstance(required_skills, list) or not all(isinstance(item, str) for item in required_skills):
        errors.append("required_skills must be a list of skill names")
    loaded_skills = state.get("loaded_skills")
    if not isinstance(loaded_skills, list) or not all(isinstance(item, str) for item in loaded_skills):
        errors.append("loaded_skills must be a list of skill names")
    api_evidence_sources = state.get("api_evidence_sources")
    if not isinstance(api_evidence_sources, list) or not all(isinstance(item, str) for item in api_evidence_sources):
        errors.append("api_evidence_sources must be a list of paths or IDs")
    elif state.get("track_status") != "not_started":
        missing_skills = set(required_skills or []) - set(loaded_skills or [])
        if missing_skills:
            errors.append("required skills not loaded: " + ", ".join(sorted(missing_skills)))
        if "hmos-arkts-knowledge-retriever" in (required_skills or []) and not api_evidence_sources:
            errors.append("ArkTS retriever Tracks require api_evidence_sources")
    api_evidence_scopes = state.get("api_evidence_scopes")
    if api_evidence_scopes is not None and (not isinstance(api_evidence_scopes, list) or not all(item in {"components", "state", "signatures"} for item in api_evidence_scopes)):
        errors.append("api_evidence_scopes must contain only components, state, or signatures")

    ui_checkpoint = state.get("ui_checkpoint")
    if not isinstance(ui_checkpoint, dict):
        errors.append("ui_checkpoint must be an object")
    else:
        checkpoint_status = ui_checkpoint.get("status")
        if checkpoint_status not in UI_CHECKPOINT_STATUSES:
            errors.append("ui_checkpoint.status is invalid")
        if state.get("ui_impact") in {None, "none"} and checkpoint_status not in {"not_required", "blocked"}:
            errors.append("non-visual tracks must not have an accepted UI checkpoint")
        if state.get("ui_impact") in {"visual", "interaction", "runtime"} and checkpoint_status == "accepted":
            snapshot = ui_checkpoint.get("snapshot")
            if not ui_checkpoint.get("source_revision") or not non_empty(snapshot):
                errors.append("accepted UI checkpoint requires source_revision and snapshot")
            elif not snapshot.replace("\\", "/").startswith("artifacts/snapshots/"):
                errors.append("accepted UI checkpoint snapshot must be under artifacts/snapshots/")

    if current in PHASES and next_phase in PHASES:
        current_index = PHASE_ORDER.index(current)
        next_index = PHASE_ORDER.index(next_phase)
        expected_index = current_index + 1
        if state.get("track_kind") != "ui" and current == "execution":
            expected_index += 1
        if next_index != expected_index and phase_status in {"in_progress", "completed"}:
            errors.append(
                f"next_phase must follow {current} in the selected track flow"
            )
    if state.get("workflow_profile") != "quick" and state.get("track_kind") == "ui" and current == "execution" and next_phase != "ui_approval" and phase_status in {"in_progress", "completed"}:
        errors.append("UI tracks must enter ui_approval after execution")

    boundary_required = state.get("phase_requires_boundary_pass")
    boundary = state.get("verification_boundary")
    if not isinstance(boundary_required, bool):
        errors.append("phase_requires_boundary_pass must be boolean")
    if not isinstance(boundary, dict):
        errors.append("verification_boundary must be an object")
    else:
        boundary_status = boundary.get("status")
        if boundary_status not in BOUNDARY_STATUSES:
            errors.append(
                "verification_boundary.status must be one of: "
                + ", ".join(sorted(BOUNDARY_STATUSES))
            )
        if boundary_status == "passed" and boundary.get("recorded_by") != "record_boundary.py":
            errors.append("passed verification boundary must be recorded by record_boundary.py")
        if boundary.get("signing") not in {"not_configured", "skipped", "passed", "failed"}:
            errors.append(
                "verification_boundary.signing must be not_configured, skipped, passed, or failed"
            )
        if state.get("workflow_profile") != "quick" and boundary_required and boundary_status == "not_required":
            errors.append(
                "a phase requiring a boundary pass cannot have status not_required"
            )
        if state.get("workflow_profile") != "quick" and phase_status == "completed" and boundary_required and boundary_status != "passed":
            errors.append(
                "completed application-changing phase requires a passed boundary pass"
            )

    known_checks = state.get("known_checks")
    if not isinstance(known_checks, dict):
        errors.append("known_checks must be an object")
    else:
        lint = known_checks.get("lint")
        if not isinstance(lint, dict):
            errors.append("known_checks.lint must be an object")
        elif lint.get("result") not in {None, "passed", "failed", "zero_files"}:
            errors.append("known_checks.lint.result is invalid")

    if phase_status == "completed":
        if last_completed != current:
            errors.append(
                "completed phase requires last_completed_phase to equal current_phase"
            )
        if next_phase == current:
            errors.append(
                "completed phase cannot use current_phase as an unstarted next_phase"
            )
        if not non_empty(state.get("next_action")):
            errors.append("completed phase requires a non-empty next_action")

    if phase_status == "in_progress" and last_completed == current:
        errors.append(
            "in_progress phase cannot also be the last_completed_phase; start the next phase explicitly"
        )

    if phase_status == "blocked" and not non_empty(state.get("blocker")):
        errors.append("blocked phase requires a non-empty blocker")

    if track_status == "not_started" and phase_status == "in_progress":
        errors.append("in_progress phase requires track_status in progress or later")

    if track_status != "not_started" and state.get("product_status") not in {"confirmed", "assumptions_accepted"}:
        errors.append("a Track cannot start before the product direction is user-confirmed")
    if phase_status in {"in_progress", "completed"} and state.get("recovery", {}).get("status") == "required":
        errors.append("recovery is required before continuing this phase")
    guarded_phases = {"execution", "ui_approval", "self_review_verification", "synchronization", "handover"}
    if state.get("workflow_profile") != "quick" and current in guarded_phases - {"execution"} and phase_status in {"in_progress", "completed"}:
        if state.get("execution_authorization", {}).get("status") != "approved":
            errors.append("guarded phase requires approved execution authorization")
    if state.get("workflow_profile") != "quick" and current in {"execution", "ui_approval", "self_review_verification", "synchronization", "handover"} and state.get("work_plan_status") != "approved":
        errors.append("implementation and later phases require approved work plan")

    if track_status == "handed_over":
        if current != "handover" or phase_status != "completed":
            errors.append(
                "handed_over track requires completed handover phase"
            )
        if last_completed != "handover":
            errors.append("handed_over track requires last_completed_phase=handover")
        if next_phase is not None:
            errors.append("handed_over track must not have a next_phase")

    if current == "handover" and phase_status == "in_progress" and track_status != "verified":
        errors.append("handover phase requires track_status=verified before the report")
    if current == "handover" and phase_status == "completed" and track_status != "handed_over":
        errors.append("completed handover requires track_status=handed_over")
    if current == "handover" and state.get("synchronization_record", {}).get("status") != "completed":
        errors.append("handover requires completed synchronization_record")
    test_approval = state.get("automated_test_approval")
    if not isinstance(test_approval, dict) or test_approval.get("status") not in {"pending", "approved", "declined", "not_required"}:
        errors.append("automated_test_approval.status is invalid")
    if current == "handover" and state.get("ui_impact") in {"interaction", "runtime"}:
        if state.get("automated_test_approval", {}).get("status") != "approved":
            errors.append("handover requires approved automated device test consent")

    acceptance = state.get("acceptance_results")
    required_acceptance = {"add", "complete", "filter", "delete", "persistence"}
    if not isinstance(acceptance, dict) or not required_acceptance.issubset(acceptance.keys()):
        errors.append("acceptance_results must include add, complete, filter, delete, and persistence")
    elif any(
        (isinstance(value, dict) and (
            value.get("result") not in {"passed", "blocked", "not_attempted", "out_of_scope"}
            or value.get("recorded_by") != "record_acceptance.py"
        ))
        or (not isinstance(value, dict) and value != "not_attempted")
        for value in acceptance.values()
    ):
        errors.append("acceptance_results entries must use a known result and record_acceptance.py")
    elif current == "handover" and state.get("ui_impact") in {"interaction", "runtime"}:
        persistence_out_of_scope = str(state.get("product_brief", {}).get("data_behavior", "")).lower()
        persistence_allowed = "no persistence" in persistence_out_of_scope or "without persistence" in persistence_out_of_scope
        missing = [
            name for name in sorted(required_acceptance)
            if not isinstance(acceptance.get(name), dict)
            or acceptance.get(name, {}).get("recorded_by") != "record_acceptance.py"
            or (
                acceptance.get(name, {}).get("result") != "passed"
                and not (name == "persistence" and persistence_allowed and acceptance.get(name, {}).get("result") == "out_of_scope")
            )
        ]
        if missing:
            errors.append("handover requires passed acceptance paths: " + ", ".join(missing))

    runtime_evidence = state.get("runtime_evidence")
    if not isinstance(runtime_evidence, dict) or runtime_evidence.get("status") not in {"pending", "matched", "blocked"}:
        errors.append("runtime_evidence.status is invalid")
    runtime_status = runtime_evidence.get("status") if isinstance(runtime_evidence, dict) else None
    if current == "handover" and state.get("ui_impact") in {"interaction", "runtime"} and (runtime_status != "matched" or not isinstance(runtime_evidence, dict) or runtime_evidence.get("recorded_by") != "record_runtime_evidence.py"):
        errors.append("handover requires runtime evidence matching the source revision")

    scope_change = state.get("scope_change")
    if not isinstance(scope_change, dict) or scope_change.get("status") not in {"none", "pending", "approved", "rejected"}:
        errors.append("scope_change.status is invalid")
    if state.get("scope_change", {}).get("status") in {"pending", "rejected"} and current in {"execution", "ui_approval", "self_review_verification", "synchronization", "handover"}:
        errors.append("scope change must be approved before continuing")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "state_file",
        nargs="?",
        default="SESSION_STATE.json",
        help="Path to the Conductor runtime state JSON file",
    )
    args = parser.parse_args()
    path = Path(args.state_file)

    try:
        state = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_keys)
    except FileNotFoundError:
        print(f"state file not found: {path}", file=sys.stderr)
        return 2
    except DuplicateKeyError as error:
        print(f"invalid state: {error}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as error:
        print(f"invalid JSON in {path}: {error}", file=sys.stderr)
        return 2

    if not isinstance(state, dict):
        print("state root must be a JSON object", file=sys.stderr)
        return 2

    errors = validate_state(state)
    if errors:
        for error in errors:
            print(f"INVALID: {error}", file=sys.stderr)
        return 1

    print(f"valid Conductor state: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
