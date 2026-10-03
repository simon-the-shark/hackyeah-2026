#!/usr/bin/env bash
set -euo pipefail

SESSION="elder-care-backend"
DATABASE_URL="postgres://elder:elder@127.0.0.1:5433/elder_care"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required. Install it with: brew install tmux"
  exit 1
fi

if ! container list | grep -q "elder-care-postgres"; then
  echo "Postgres is not running. Start the elder-care-postgres Apple Container first."
  exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" \
    "cd \"$(pwd)\" && DATABASE_URL=\"$DATABASE_URL\" PUSH_PROVIDER=log PORT=8787 pnpm dev"
fi

exec tmux attach-session -t "$SESSION"
