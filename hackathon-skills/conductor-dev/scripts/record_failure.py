"""Record a consequential recovery incident before retrying a command."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("learning_file")
    parser.add_argument("--command", required=True)
    parser.add_argument("--symptom", required=True)
    parser.add_argument("--cause", required=True)
    parser.add_argument("--recovery", required=True)
    parser.add_argument("--scope", default="current Track")
    parser.add_argument("--state-file")
    args = parser.parse_args()
    path = Path(args.learning_file)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text("# Learning Log\n\n## Known Tool Limitations\n\n## Incidents\n", encoding="utf-8")
    entry = (
        f"\n- Command: `{args.command}`\n"
        f"  - Symptom: {args.symptom}\n"
        f"  - Cause: {args.cause}\n"
        f"  - Recovery: {args.recovery}\n"
        f"  - Scope: {args.scope}\n"
    )
    with path.open("a", encoding="utf-8") as output:
        output.write(entry)
    if args.state_file:
        state_path = Path(args.state_file)
        state: dict[str, object] = json.loads(state_path.read_text(encoding="utf-8"))
        state["recovery"] = {
            "status": "recorded",
            "incident": {
                "command": args.command,
                "symptom": args.symptom,
                "cause": args.cause,
                "recovery": args.recovery,
                "scope": args.scope,
            },
        }
        state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"failure recorded before recovery: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
