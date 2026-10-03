"""Build and optionally deploy only the affected module with compact output."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path

from change_impact import classify, changed_files


def resolve_command(command: list[str]) -> list[str]:
    executable = shutil.which(command[0])
    if not executable:
        return command
    if executable.lower().endswith(".ps1"):
        return ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", executable, *command[1:]]
    return [executable, *command[1:]]


def run(command: list[str], log_path: Path, cwd: Path, marker: str | None = None) -> int:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    command = resolve_command(command)
    completed = subprocess.run(
        command,
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    output = completed.stdout + completed.stderr
    log_path.write_text(output, encoding="utf-8")
    if completed.returncode != 0:
        first_error = next((line.strip() for line in output.splitlines() if "ERROR" in line or "FAILED" in line), "non-zero exit")
        print(f"COMMAND_FAIL exit={completed.returncode} error={first_error} log={log_path}")
        return completed.returncode
    if marker and marker not in output:
        print(f"COMMAND_UNCONFIRMED exit=0 marker={marker} log={log_path}")
        return 1
    print(f"COMMAND_PASS exit=0 marker={marker or 'none'} log={log_path}")
    return 0


def resolve_device(device: str, cwd: Path, log_path: Path) -> str:
    if "[IP_ADDRESS]" not in device:
        return device
    command = resolve_command(["devecocli", "device", "list", "--format", "json"])
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, check=False)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode != 0:
        return device
    try:
        devices = json.loads(result.stdout)
    except json.JSONDecodeError:
        return device
    if isinstance(devices, list) and len(devices) == 1 and devices[0].get("name"):
        resolved = str(devices[0]["name"])
        print(f"DEVICE_FALLBACK name={resolved} reason=redacted-serial")
        return resolved
    return device


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("project_root")
    parser.add_argument("--device")
    parser.add_argument("--module", default="entry")
    parser.add_argument("--build-mode", default="debug")
    parser.add_argument("--snapshot")
    parser.add_argument("--paths", nargs="*", help="Changed paths, for deterministic CI or dry-run checks.")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    root = Path(args.project_root).resolve()
    impact = classify(args.paths if args.paths else changed_files(root))
    print(json.dumps(impact, separators=(",", ":")))
    if impact["build_scope"] == "none":
        print("INCREMENTAL_SKIP reason=no-build-impact")
        return 0
    if impact["build_scope"] == "module":
        modules = impact["modules"] or [args.module]
        build = ["devecocli", "build", "--modules", modules[0], "--build-mode", args.build_mode]
    else:
        build = ["devecocli", "build", "--build-mode", args.build_mode]
    if args.dry_run:
        lint = ["devecocli", "check", "lint", "--format", "json", str(root)]
        print(json.dumps({"lint": lint, "build": build, "deploy": bool(args.device)}, separators=(",", ":")))
        return 0
    log_dir = root / "artifacts" / "logs"
    lint = ["devecocli", "check", "lint", "--format", "json", str(root)]
    code = run(lint, log_dir / "incremental-lint.log", root)
    if code != 0:
        return code
    code = run(build, log_dir / "incremental-build.log", root)
    if code != 0 or not args.device:
        return code
    resolved_device = resolve_device(args.device, root, log_dir / "incremental-device-resolution.log")
    code = run(["devecocli", "device", "list", "--format", "json"], log_dir / "incremental-device-list.log", root)
    if code != 0:
        return code
    run_command = ["devecocli", "run", "--skip-build", "--device", resolved_device, "--module", args.module]
    code = run(run_command, log_dir / "incremental-run.log", root)
    if code == 0 and args.snapshot:
        screenshot = ["devecocli", "ui", "screenshot", "--device", resolved_device, "--path", args.snapshot]
        code = run(screenshot, log_dir / "incremental-screenshot.log", root)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
