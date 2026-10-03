"""Update JSON state atomically without duplicate keys or full-file output."""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any

from validate_state import reject_duplicate_keys, validate_state


def parse_value(raw: str) -> Any:
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # PowerShell can strip quotes from inline JSON arrays. Recover simple
        # string lists, while still requiring objects to use --set-file.
        if raw.strip().startswith("[") and raw.strip().endswith("]"):
            body = raw.strip()[1:-1].strip()
            if not body:
                return []
            return [item.strip().strip('"\'') for item in body.split(",")]
        return raw


def set_path(state: dict[str, Any], path: str, value: Any) -> None:
    parts = path.split(".")
    target = state
    for part in parts[:-1]:
        child = target.setdefault(part, {})
        if not isinstance(child, dict):
            raise ValueError(f"state path is not an object: {part}")
        target = child
    target[parts[-1]] = value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--set", action="append", default=[], metavar="PATH=VALUE")
    parser.add_argument(
        "--set-file",
        action="append",
        default=[],
        metavar="PATH=JSON_FILE",
        help="Set a nested object/list by reading JSON from a file; avoids shell quoting failures.",
    )
    parser.add_argument(
        "--next-action",
        help="Set next_action without PowerShell quoting or nested JSON syntax.",
    )
    parser.add_argument(
        "--required-skill",
        action="append",
        help="Append a required skill without PowerShell JSON-array quoting.",
    )
    parser.add_argument(
        "--assumption",
        action="append",
        help="Append a product assumption without PowerShell JSON-array quoting.",
    )
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicate_keys)
    for assignment in args.set:
        if "=" not in assignment:
            parser.error("--set must use PATH=VALUE")
        key, raw = assignment.split("=", 1)
        set_path(state, key, parse_value(raw))
    for assignment in args.set_file:
        if "=" not in assignment:
            parser.error("--set-file must use PATH=JSON_FILE")
        key, filename = assignment.split("=", 1)
        set_path(state, key, json.loads(Path(filename).read_text(encoding="utf-8")))
    if args.next_action is not None:
        set_path(state, "next_action", args.next_action)
    if args.required_skill is not None:
        set_path(state, "required_skills", args.required_skill)
    if args.assumption is not None:
        set_path(state, "product_confirmation.assumptions", args.assumption)
    if state.get("phase_requires_boundary_pass"):
        boundary = state.setdefault("verification_boundary", {})
        if boundary.get("status") in {None, "not_required", "gate_passed"}:
            boundary["status"] = "pending"
    errors = validate_state(state)
    if errors:
        for error in errors:
            print(f"STATE_UPDATE_BLOCK: {error}", file=sys.stderr)
        return 1
    handle, temporary = tempfile.mkstemp(prefix="session-state-", suffix=".json", dir=str(path.parent))
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as output:
            json.dump(state, output, indent=2)
            output.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    fields = len(args.set) + len(args.set_file)
    fields += sum(value is not None for value in (args.next_action, args.required_skill, args.assumption))
    print(f"STATE_UPDATED fields={fields}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
