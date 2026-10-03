"""Run the lightweight Conductor preflight for a phase boundary or handover."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from context_cache import fingerprint as context_fingerprint
from evidence_cache import cache_key as evidence_cache_key
from validate_state import validate_state


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--execution", action="store_true")
    mode.add_argument("--phase-boundary", action="store_true")
    mode.add_argument("--post-verification", action="store_true")
    mode.add_argument("--handover", action="store_true")
    parser.add_argument("--context-phase")
    parser.add_argument("--context-files", nargs="*")
    parser.add_argument("--lint-tool-version")
    parser.add_argument("--lint-config-fingerprint")
    parser.add_argument("--lint-target-fingerprint")
    parser.add_argument("--evidence-topic")
    parser.add_argument("--evidence-sdk")
    parser.add_argument("--evidence-query-fingerprint")
    parser.add_argument(
        "--api-symbol",
        action="append",
        default=[],
        help="New or changed API/component/member symbols requiring recorded evidence.",
    )
    parser.add_argument("--evidence-scope", action="append", choices=["components", "state", "signatures"], default=[])
    args = parser.parse_args()

    state_path = Path(args.state_file)
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    errors = validate_state(state)
    mode_name = "handover" if args.handover else "post-verification" if args.post_verification else "execution" if args.execution else "phase-boundary"
    if args.handover:
        if state.get("current_phase") != "handover":
            errors.append("handover gate requires current_phase=handover")
        if state.get("phase_status") not in {"in_progress", "completed"}:
            errors.append("handover gate requires an active or completed handover phase")
        if state.get("track_status") not in {"verified", "handed_over"}:
            errors.append("handover gate requires track_status=verified or handed_over")
        if state.get("phase_requires_boundary_pass") and state.get("verification_boundary", {}).get("status") != "passed":
            errors.append("handover gate requires a passed verification boundary")
        if not state.get("ai_workflow", {}).get("clean"):
            errors.append("handover gate requires clean AI_WORKFLOW.md")
    elif args.post_verification:
        if state.get("phase_requires_boundary_pass") and state.get("verification_boundary", {}).get("status") != "passed":
            errors.append("post-verification requires a passed verification boundary")
        if not args.lint_tool_version or not args.lint_config_fingerprint or not args.lint_target_fingerprint:
            errors.append("post-verification requires lint tool, config, and target fingerprints")
    else:
        if state.get("phase_requires_boundary_pass") and state.get("verification_boundary", {}).get("status") not in {"pending", "in_progress", "passed"}:
            errors.append("phase boundary has no usable verification_boundary state")

    if args.execution and (not args.context_phase or not args.context_files):
        errors.append("execution gate requires context phase and file list")
    if args.execution and state.get("workflow_profile") != "quick":
        if state.get("workflow_plan", {}).get("status") != "recorded":
            errors.append("execution requires a recorded workflow_plan.py result")
        decisions = state.get("question_gate", {}).get("decisions", {})
        for kind in ("product", "work_plan"):
            if decisions.get(kind, {}).get("decision") != "approved" or decisions.get(kind, {}).get("recorded_by") != "record_question_gate.py" or state.get("question_gate", {}).get("method") != "interactive_question":
                errors.append(f"execution requires approved interactive question decision: {kind}")
    if args.execution and "hmos-arkts-knowledge-retriever" in state.get("required_skills", []):
        if not (args.evidence_topic and args.evidence_sdk and args.evidence_query_fingerprint):
            errors.append("ArkTS execution requires evidence cache topic, SDK, and query fingerprint")
    if args.execution and "hmos-arkui-develop-skill" in state.get("required_skills", []):
        if not (args.evidence_topic and args.evidence_sdk and args.evidence_query_fingerprint):
            errors.append("ArkUI execution requires one focused local API evidence query")
        required_scopes = {"components", "signatures"}
        if state.get("ui_impact") in {"interaction", "runtime", "visual"} or "hmos-arkui-mvvm-pattern" in state.get("required_skills", []):
            required_scopes.add("state")
        missing_requested = sorted(required_scopes - set(args.evidence_scope))
        if missing_requested:
            errors.append("ArkUI execution requires evidence scopes: " + ", ".join(missing_requested))
        recorded_scopes = set(state.get("api_evidence_scopes", []))
        for evidence in state.get("api_evidence_cache", {}).values():
            recorded_scopes.update(evidence.get("scopes", []))
        missing_recorded = sorted(required_scopes - recorded_scopes)
        if missing_recorded:
            errors.append("ArkUI evidence is missing recorded scopes: " + ", ".join(missing_recorded))
    if args.post_verification and state.get("execution_authorization", {}).get("status") != "approved":
        errors.append("post-verification requires approved execution authorization")
    if args.post_verification and state.get("verification_boundary", {}).get("status") != "passed":
        errors.append("post-verification requires verification_boundary.status=passed")
    if args.post_verification and state.get("verification_gate", {}).get("last_mode") != "phase-boundary":
        errors.append("post-verification requires a passed phase-boundary gate")
    if args.post_verification and state.get("ui_impact") in {"interaction", "runtime"}:
        decisions = state.get("question_gate", {}).get("decisions", {})
        for kind in ("ui", "device_tests"):
            if decisions.get(kind, {}).get("decision") != "approved" or decisions.get(kind, {}).get("recorded_by") != "record_question_gate.py" or state.get("question_gate", {}).get("method") != "interactive_question":
                errors.append(f"post-verification requires approved interactive question decision: {kind}")

    checks: dict[str, str] = {}
    if args.context_phase and args.context_files:
        files = [Path(item).resolve() for item in args.context_files]
        current = context_fingerprint(files)
        cached = state.get("context_cache", {})
        checks["context"] = "reuse" if cached.get("phase") == args.context_phase and cached.get("fingerprint") == current else "reload"
    else:
        checks["context"] = "not_requested"

    if args.execution and checks["context"] == "reload":
        errors.append("execution requires context_cache --record after reloading context")

    if args.evidence_topic and args.evidence_sdk and args.evidence_query_fingerprint:
        key = evidence_cache_key(args.evidence_topic, args.evidence_sdk, args.evidence_query_fingerprint)
        checks["evidence"] = "reuse" if key in state.get("api_evidence_cache", {}) else "fetch"
        if args.execution and key not in state.get("api_evidence_cache", {}):
            errors.append("execution requires recorded evidence_cache result")
    else:
        checks["evidence"] = "not_requested"

    lint = state.get("known_checks", {}).get("lint", {})
    lint_matches = all(
        lint.get(field) == value
        for field, value in {
            "tool_version": args.lint_tool_version,
            "config_fingerprint": args.lint_config_fingerprint,
            "target_fingerprint": args.lint_target_fingerprint,
        }.items()
        if value is not None
    )
    checks["lint"] = "skip" if lint.get("result") == "zero_files" and lint_matches else "run"

    if args.post_verification and checks["lint"] == "run":
        errors.append("post-verification requires a recorded matching lint result")

    gate = state.setdefault("verification_gate", {})
    gate.update({"last_phase": state.get("current_phase"), "last_mode": mode_name, "status": "blocked" if errors else "passed", "checks": checks})
    if not errors and args.phase_boundary and state.get("phase_requires_boundary_pass"):
        state.setdefault("verification_boundary", {})["status"] = "gate_passed"
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")

    if errors:
        for error in errors:
            print(f"GATE_BLOCK: {error}", file=sys.stderr)
        return 1
    print(
        f"GATE_PASS mode={mode_name} phase={state.get('current_phase')} "
        f"context={checks['context']} evidence={checks['evidence']} lint={checks['lint']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"verification gate error: {error}", file=sys.stderr)
        raise SystemExit(2)
