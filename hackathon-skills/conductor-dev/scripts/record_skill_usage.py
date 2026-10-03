"""Record loaded specialist skills and evidence sources in session state."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--skill", action="append", default=[])
    parser.add_argument("--evidence", action="append", default=[])
    args = parser.parse_args()
    path = Path(args.state_file)
    state: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    loaded = state.setdefault("loaded_skills", [])
    sources = state.setdefault("api_evidence_sources", [])
    for skill in args.skill:
        if skill not in loaded:
            loaded.append(skill)
    for source in args.evidence:
        if source not in sources:
            sources.append(source)
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"skills recorded: {len(loaded)}; evidence sources: {len(sources)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
