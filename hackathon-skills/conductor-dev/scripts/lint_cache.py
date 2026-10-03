"""Check or record a reusable lint result in SESSION_STATE.json."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("state root must be a JSON object")
    return value


def lint_record(state: dict[str, Any]) -> dict[str, Any]:
    checks = state.setdefault("known_checks", {})
    lint = checks.setdefault("lint", {})
    if not isinstance(lint, dict):
        raise ValueError("known_checks.lint must be an object")
    return lint


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--tool-version", required=True)
    parser.add_argument("--config-fingerprint", required=True)
    parser.add_argument("--target-fingerprint", required=True)
    parser.add_argument("--record", choices=["passed", "failed", "zero_files"])
    args = parser.parse_args()
    path = Path(args.state_file)

    try:
        state = load(path)
        lint = lint_record(state)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"invalid lint cache state: {error}", file=sys.stderr)
        return 2

    current = {
        "tool_version": args.tool_version,
        "config_fingerprint": args.config_fingerprint,
        "target_fingerprint": args.target_fingerprint,
    }

    if args.record:
        lint.update(current)
        lint["result"] = args.record
        state.setdefault("validation_status", {})["lint"] = "passed" if args.record in {"passed", "zero_files"} else "blocked"
        path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"lint cache recorded: {args.record}")
        return 0

    reusable = lint.get("result") == "zero_files" and all(
        lint.get(key) == value for key, value in current.items()
    )
    if reusable:
        print("SKIP_LINT: unchanged zero-file result")
        return 10

    print("RUN_LINT: cache miss or non-zero-file result")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
