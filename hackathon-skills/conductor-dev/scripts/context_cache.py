"""Reuse phase context when its files and phase are unchanged."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


def fingerprint(files: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(files, key=lambda item: str(item)):
        digest.update(str(path).encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--phase", required=True)
    parser.add_argument("--files", nargs="+", required=True)
    parser.add_argument("--record", action="store_true")
    args = parser.parse_args()
    state_path = Path(args.state_file)
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    state_resolved = state_path.resolve()
    files = [Path(item).resolve() for item in args.files if Path(item).resolve() != state_resolved]
    current_fingerprint = fingerprint(files)
    cache = state.setdefault("context_cache", {})
    reusable = cache.get("phase") == args.phase and cache.get("fingerprint") == current_fingerprint

    if args.record:
        cache.update({"phase": args.phase, "fingerprint": current_fingerprint, "files": [str(item) for item in files]})
        state["context_fingerprint"] = current_fingerprint
        state["loaded_context"] = [str(item) for item in files]
        state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"CONTEXT_RECORDED files={len(files)} fingerprint={current_fingerprint[:12]}")
        return 0

    if reusable:
        print(f"REUSE_CONTEXT files={len(files)} fingerprint={current_fingerprint[:12]}")
        return 10
    changed = [str(item) for item in files if str(item) not in cache.get("files", [])]
    print(f"RELOAD_CONTEXT files={len(files)} new_or_changed={len(changed)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"context cache error: {error}", file=sys.stderr)
        raise SystemExit(2)
