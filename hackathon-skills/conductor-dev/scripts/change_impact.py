"""Classify changed files so build and verification can stay incremental."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path


def changed_files(root: Path) -> list[str]:
    top = Path(subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
        text=True,
    ).strip()).resolve()
    relative_root = os.path.relpath(root, top).replace("\\", "/")
    scope = [] if relative_root == "." else [relative_root]
    result = subprocess.run(
        ["git", "-C", str(top), "status", "--porcelain", "--untracked-files=all", "--", *scope],
        capture_output=True,
        text=True,
        check=True,
    )
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if len(line) >= 4:
            path = line[3:].strip().replace("\\", "/")
            if relative_root != "." and path.startswith(relative_root + "/"):
                path = path[len(relative_root) + 1:]
            paths.append(path)
    return sorted(set(paths))


def classify(paths: list[str]) -> dict[str, object]:
    ignored_prefixes = ("artifacts/", "conductor/", "hackathon-resources/", "oh_modules/", ".idea/")
    paths = [path for path in paths if not path.startswith(ignored_prefixes) and path not in {"AI_WORKFLOW.md", "AGENTS.md"}]
    source = [path for path in paths if path.endswith((".ets", ".ts", ".tsx", ".js"))]
    resources = [path for path in paths if "/resources/" in path]
    config = [path for path in paths if Path(path).name in {
        "build-profile.json5", "module.json5", "oh-package.json5", "oh-package-lock.json5",
        "code-linter.json5", "app.json5"
    }]
    docs = [path for path in paths if path.endswith((".md", ".txt"))]
    tests = [path for path in paths if "/test/" in path or "/tests/" in path]
    production_source = [path for path in source if path not in tests]
    known = set(source + resources + config + docs + tests)
    unknown = [path for path in paths if path not in known]
    module_paths = sorted({path.split("/", 1)[0] for path in production_source + resources if "/" in path})
    if config or unknown:
        scope = "full"
    elif production_source or resources:
        scope = "module"
    elif tests:
        scope = "tests"
    else:
        scope = "none"
    return {
        "changed_files": paths,
        "source_files": source,
        "resource_files": resources,
        "config_files": config,
        "test_files": tests,
        "documentation_files": docs,
        "unknown_files": unknown,
        "modules": module_paths,
        "build_scope": scope,
        "device_required": bool(production_source or resources or config or unknown),
        "hot_reload_candidate": len(production_source) == 1 and not resources and not config and not unknown,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("project_root", nargs="?", default=".")
    parser.add_argument("--paths", nargs="*")
    args = parser.parse_args()
    root = Path(args.project_root).resolve()
    paths = args.paths if args.paths is not None and args.paths else changed_files(root)
    print(json.dumps(classify(paths), separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
