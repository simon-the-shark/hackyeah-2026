"""Create the standard Conductor artifact directories before evidence commands."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_root", nargs="?", default=".")
    args = parser.parse_args()
    root = Path(args.project_root)
    for relative in ("artifacts/snapshots", "artifacts/logs"):
        (root / relative).mkdir(parents=True, exist_ok=True)
    print(f"artifact directories ready: {root.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
