"""Safe, compact bridge for language-agnostic devecocli documentation search/read.

The bridge forwards only short, relevant snippets. Full ``docs read`` output is
never passed through directly. Non-English content is an internal translation
queue; only translated English ``ready_context`` is final context.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any


CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")


def contains_cjk(value: str) -> bool:
    return bool(CJK_RE.search(value))


def compact_results(payload: Any, translations: dict[str, str], limit: int, mode: str = "agent") -> dict[str, Any]:
    if not isinstance(payload, list):
        return {"results": [], "omitted": 0, "error": "unexpected devecocli JSON shape"}
    results: list[dict[str, str]] = []
    translation_queue: list[dict[str, str]] = []
    omitted = 0
    for item in payload[:limit]:
        if not isinstance(item, dict):
            continue
        document_id = str(item.get("documentId", ""))
        snippet = str(item.get("snippet", ""))
        translated = translations.get(document_id)
        summary = translated or snippet
        if contains_cjk(summary):
            translation_queue.append({
                "document_id": document_id[:300],
                "source_language": "zh",
                "text": summary[:1200],
            })
            omitted += 1
            continue
        result = {
            "title": str(item.get("title", ""))[:160],
            "document_id": document_id[:300],
            "section": str(item.get("sectionTitle", ""))[:160],
            "source": "devecocli",
            "source_language": "zh" if contains_cjk(summary) else "en",
        }
        result["summary"] = summary[:600]
        results.append(result)
    return {
        "query_limit": limit,
        "results": results,
        "omitted_non_english": omitted,
        "translation_queue": translation_queue,
        "context_status": "ready" if omitted == 0 else "translation_required",
    }


def compact_read(document_id: str, content: str, translations: dict[str, str]) -> dict[str, Any]:
    source = content.strip()[:6000]
    translated = translations.get(document_id, "").strip()
    if translated:
        return {
            "document_id": document_id,
            "source_language": "zh" if contains_cjk(source) else "en",
            "ready_context": translated[:1600],
            "translation_queue": [],
            "context_status": "ready",
        }
    if contains_cjk(source):
        return {
            "document_id": document_id,
            "source_language": "zh",
            "ready_context": None,
            "translation_queue": [{"document_id": document_id, "text": source}],
            "context_status": "translation_required",
        }
    return {
        "document_id": document_id,
        "source_language": "en",
        "ready_context": source[:1600],
        "translation_queue": [],
        "context_status": "ready",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("keywords", nargs="*")
    parser.add_argument("--document-id")
    parser.add_argument("--read", action="store_true")
    parser.add_argument("--limit", type=int, default=3)
    parser.add_argument("--translation-map", type=Path)
    parser.add_argument("--mode", choices=["agent", "map", "omit"], default="agent")
    args = parser.parse_args()
    if args.read and not args.document_id:
        parser.error("--read requires --document-id")
    if not args.read and not args.keywords:
        parser.error("provide search keywords or use --read --document-id <id>")
    translations: dict[str, str] = {}
    if args.translation_map:
        translations = json.loads(args.translation_map.read_text(encoding="utf-8"))
    executable = shutil.which("devecocli")
    if not executable:
        print(json.dumps({"results": [], "error": "devecocli was not found"}, separators=(",", ":")))
        return 1
    if args.read:
        command = [executable, "docs", "read", args.document_id]
    else:
        command = [executable, "docs", "search", "--format", "json", "--limit", str(args.limit), *args.keywords]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        print(json.dumps({"results": [], "error": "devecocli docs search failed"}, separators=(",", ":")))
        return completed.returncode
    if args.read:
        print(json.dumps(compact_read(args.document_id, completed.stdout, translations), ensure_ascii=True, separators=(",", ":")))
        return 0
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError:
        print(json.dumps({"results": [], "error": "devecocli returned invalid JSON"}, separators=(",", ":")))
        return 1
    mode = "map" if args.translation_map else args.mode
    print(json.dumps(compact_results(payload, translations, args.limit, mode), ensure_ascii=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
