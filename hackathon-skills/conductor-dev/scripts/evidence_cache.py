"""Reuse API evidence for the same topic, SDK, and query fingerprint."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


def cache_key(topic: str, sdk: str, query: str) -> str:
    value = "\0".join((topic, sdk, query))
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state_file")
    parser.add_argument("--topic", required=True)
    parser.add_argument("--sdk", required=True)
    parser.add_argument("--query-fingerprint", required=True)
    parser.add_argument("--record", action="store_true")
    parser.add_argument("--document-id")
    parser.add_argument("--section")
    parser.add_argument("--source-kind")
    parser.add_argument("--summary")
    parser.add_argument("--api-symbol", action="append", default=[])
    parser.add_argument("--scope", action="append", choices=["components", "state", "signatures"], default=[])
    args = parser.parse_args()
    state_path = Path(args.state_file)
    state: dict[str, Any] = json.loads(state_path.read_text(encoding="utf-8"))
    cache = state.setdefault("api_evidence_cache", {})
    key = cache_key(args.topic, args.sdk, args.query_fingerprint)

    if args.record:
        required = (args.document_id, args.section, args.source_kind, args.summary)
        if not all(required):
            print("recording evidence requires document, section, source kind, and summary", file=sys.stderr)
            return 2
        cache[key] = {
            "topic": args.topic,
            "sdk": args.sdk,
            "query_fingerprint": args.query_fingerprint,
            "document_id": args.document_id,
            "section": args.section,
            "source_kind": args.source_kind,
            "summary": args.summary,
            "api_symbols": args.api_symbol,
            "scopes": args.scope,
        }
        scopes = state.setdefault("api_evidence_scopes", [])
        for scope in args.scope:
            if scope not in scopes:
                scopes.append(scope)
        state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print("EVIDENCE_RECORDED")
        return 0

    if key in cache:
        print("USE_CACHED_EVIDENCE")
        return 10
    print("FETCH_EVIDENCE")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"evidence cache error: {error}", file=sys.stderr)
        raise SystemExit(2)
