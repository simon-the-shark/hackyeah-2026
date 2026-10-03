"""Run a command with full output in a log and compact output for the agent."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", required=True)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--require-marker")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("a command is required after --")
    log_path = Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    executable = shutil.which(command[0])
    if executable:
        command[0] = executable
    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=args.timeout, check=False)
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or "") + (error.stderr or "")
        log_path.write_text(output, encoding="utf-8")
        print(f"COMMAND_TIMEOUT log={log_path}")
        return 124
    output = completed.stdout + completed.stderr
    log_path.write_text(output, encoding="utf-8")
    if completed.returncode != 0:
        first_error = next((line.strip() for line in output.splitlines() if re.search(r"ERROR|FAILED|error", line)), "non-zero command exit")
        print(f"COMMAND_FAIL exit={completed.returncode} error={first_error} log={log_path}")
        return completed.returncode
    if args.require_marker and args.require_marker not in output:
        print(f"COMMAND_UNCONFIRMED exit=0 marker={args.require_marker} log={log_path}")
        return 1
    marker = f" marker={args.require_marker}" if args.require_marker else ""
    print(f"COMMAND_PASS exit=0{marker} log={log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
