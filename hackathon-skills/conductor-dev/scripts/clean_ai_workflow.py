"""Remove unfinished template placeholders from AI_WORKFLOW.md."""

from __future__ import annotations

import argparse
from pathlib import Path


PLACEHOLDERS = (
    "[Tool name]",
    "[Version/source]",
    "[Ideation, implementation, review, testing, debugging, etc.]",
    "[YYYY-MM-DD]",
    "[Tool/model]",
    "[Prompt summary]",
    "[Files/design/code]",
    "[How it was checked]",
    "[Summarize the important project prompt",
    "[Describe how AI influenced",
    "[Describe the AI-assisted coding workflow",
    "[Record builds, linting, tests",
    "[What was tried, why it failed",
    "[Product, platform, model, data",
    "[Concise lesson that would help",
    "[Name/version/provider]",
    "[On-device, remote, or hybrid",
    "[What leaves the device",
    "[How errors, latency, offline use",
    "[Test cases, quality measures",
)
STALE_LINES = (
    "Build: to be run",
    "Lint: to be run",
    "Device/UI paths: to be run",
    "Initial validation commands are recorded",
    "Verification is pending implementation",
    "Build: to be run after implementation",
    "Lint: to be run after the UI build checkpoint",
    "Device/UI paths: to be run if",
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workflow_file")
    parser.add_argument("--state-file")
    args = parser.parse_args()
    path = Path(args.workflow_file)
    lines = path.read_text(encoding="utf-8").splitlines()
    cleaned = [
        line for line in lines
        if not any(marker in line for marker in PLACEHOLDERS)
        and not any(marker in line for marker in STALE_LINES)
    ]
    deduped: list[str] = []
    for line in cleaned:
        if line.strip() and line in deduped and not line.lstrip().startswith("|"):
            continue
        deduped.append(line)
    path.write_text("\n".join(deduped).rstrip() + "\n", encoding="utf-8")
    remaining = [marker for marker in PLACEHOLDERS if marker in path.read_text(encoding="utf-8")]
    if remaining:
        print(f"AI workflow cleanup blocked; placeholders remain: {', '.join(remaining)}")
        return 1
    if args.state_file:
        state_path = Path(args.state_file)
        state = __import__("json").loads(state_path.read_text(encoding="utf-8"))
        state.setdefault("ai_workflow", {})["clean"] = True
        state_path.write_text(__import__("json").dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"AI workflow placeholders removed: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
