# OpenCode: What It Is and How to Deploy and Use

This document explains what **OpenCode** (the open source AI coding agent) is, and how to install, deploy, and use it. References:

- OpenCode official site: <https://opencode.ai>
- OpenCode source: <https://github.com/anomalyco/opencode>

---

## Overview

**OpenCode** is an **open source AI coding agent** that helps you write code in your **terminal, IDE, or desktop**. It is a "Claude Code / Cursor"-style agent that can read your codebase, plan, and make changes, driven by LLMs.

## Key features

- **Any model** — connects to 75+ LLM providers via Models.dev, including Claude, GPT, Gemini, local models, and free included models.
- **Any editor** — available as a terminal interface, a desktop app, and an IDE extension.
- **LSP enabled** — automatically loads the right language servers for the LLM.
- **Multi-session** — run multiple agents in parallel on the same project.
- **Share links** — share a link to any session for reference or debugging.
- **Bring your own subscription** — log in with GitHub to use your Copilot account, or with OpenAI to use ChatGPT Plus / Pro.
- **Privacy first** — does not store your code or context data, suitable for privacy-sensitive environments.

## Use OpenCode

1. Run `opencode` inside a project directory.
2. Configure the model / provider as needed (via interactive setup or the config file) — or log in with GitHub Copilot / OpenAI to reuse an existing subscription.
3. Describe a task in natural language; the agent reads the codebase, plans, edits files, and runs commands.
4. Useful commands inside the TUI:
   - `/help` — get help on using opencode
   - `/models` — switch the active model
   - `/sessions` — manage multiple sessions
   - Type a question directly to chat; type a task that modifies files to make changes.

The AI agent can call `devecocli` subprocesses from your prompt. See the `devecocli.md` guide bundled in your project's `hackathon-resources/` directory for the deveco-cli capability matrix.

---

## How to deploy

### Install OpenCode

```bash
# YOLO
curl -fsSL https://opencode.ai/install | bash

# Package managers
npm i -g opencode-ai@latest        # or bun/pnpm/yarn
scoop install opencode             # Windows
choco install opencode             # Windows
brew install anomalyco/tap/opencode # macOS and Linux (recommended, always up to date)
brew install opencode              # macOS and Linux (official brew formula, updated less)
sudo pacman -S opencode            # Arch Linux (Stable)
paru -S opencode-bin               # Arch Linux (Latest from AUR)
mise use -g opencode               # Any OS
nix run nixpkgs#opencode           # or github:anomalyco/opencode for latest dev branch
```

> **Tip**: Remove versions older than 0.1.x before installing.

You can launch it by:

```bash
opencode
```
