"""Authorize source editing only after the execution gate prerequisites pass."""

from __future__ import annotations

import argparse
import hashlib
import json
import time
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--phase", default="execution")
    parser.add_argument("--source-revision", required=True)
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    errors: list[str] = []
    if state.get("current_phase") != args.phase or state.get("phase_status") != "in_progress":
        errors.append("authorization requires the requested phase to be in_progress")
    if state.get("product_status") not in {"confirmed", "assumptions_accepted"}:
        errors.append("product brief is not confirmed")
    if state.get("work_plan_status") != "approved":
        errors.append("work plan is not approved")
    required = set(state.get("required_skills", []))
    loaded = set(state.get("loaded_skills", []))
    if required - loaded:
        errors.append("required skills are not loaded")
    if state.get("recovery", {}).get("status") == "required":
        errors.append("recovery incident must be recorded first")
    gate = state.get("verification_gate", {})
    if gate.get("status") != "passed" or gate.get("last_mode") != "execution":
        errors.append("execution gate must pass immediately before authorization")
    if errors:
        for error in errors:
            print(f"AUTHORIZATION_BLOCK: {error}")
        return 1

    token_input = f"{args.phase}:{args.source_revision}:{time.time_ns()}"
    token = hashlib.sha256(token_input.encode("utf-8")).hexdigest()
    state["execution_authorization"] = {
        "status": "approved",
        "phase": args.phase,
        "token": token,
        "authorized_revision": args.source_revision,
    }
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"EXECUTION_AUTHORIZED phase={args.phase} token={token[:12]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
