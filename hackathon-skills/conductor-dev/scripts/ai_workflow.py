"""Append only new AI workflow entries and remember their fingerprints."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("workflow_file")
    parser.add_argument("--phase", required=True)
    parser.add_argument("--entry", required=True)
    args = parser.parse_args()
    state_path = Path(args.state_file)
    workflow_path = Path(args.workflow_file)
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    record = state.setdefault("ai_workflow", {})
    fingerprint = hashlib.sha256(args.entry.encode("utf-8")).hexdigest()
    seen = record.setdefault("tools", [])

    if fingerprint in seen:
        print("SKIP_AI_WORKFLOW: unchanged entry")
        return 10

    workflow_path.parent.mkdir(parents=True, exist_ok=True)
    with workflow_path.open("a", encoding="utf-8") as output:
        output.write(f"\n## {args.phase}\n{args.entry}\n")
    seen.append(fingerprint)
    record["revision"] = fingerprint
    record["last_recorded_phase"] = args.phase
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print("AI_WORKFLOW_RECORDED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
