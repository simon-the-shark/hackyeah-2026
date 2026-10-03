---
name: ohos-app-scaffold
description: Use ONLY to create a new, untouched HarmonyOS Empty Ability project with the `devecocli` CLI. Do not implement app features or edit generated source files; continue with `ohos-app-dev` for ordinary apps or `ohos-system-app-dev` when the requested APIs or permissions may require privileged system-app identity.
---

# OHOS App Scaffold

Create only the project skeleton from the Empty Ability template, then stop. Use the
**`devecocli` CLI** for project creation instead of manually copying a template. This
skill is a project-initialization skill, not an app-development skill. Building,
feature implementation, UI design, tests, and device validation belong to
`ohos-app-dev` after the project is created.

## Scope gate

Before acting, separate the request into two possible intents:

- **Scaffolding intent:** create a new OHOS/HarmonyOS project, specify its app name,
  bundle name, project path, or API level. Handle this with this skill.
- **Development intent:** implement a todo list, login screen, database, networking,
  custom UI, business logic, tests, or any other feature. Do not handle this with
  this skill. Stop after scaffolding and ask whether the user wants to continue with
  `ohos-app-dev`, or with `ohos-system-app-dev` for privilege preflight when the requested
  APIs or permissions may require `hos_system_app`, an elevated APL, ACL/provisioning, or
  a Full SDK system API.

If a request contains both intents, perform only the scaffolding intent. Do not infer
permission to implement the requested feature merely because the user named the app
after that feature (for example, `TodoList`).

> **Prereqs:** Node.js and npm, the DevEco CLI installed by the hackathon setup and on PATH,
> and an available DevEco Studio toolchain (`hvigor`, `ohpm`, `hdc`, etc.). Verify with
> `devecocli -V`.

### Windows toolchain selection

Require the caller's `PATH` to contain the preferred DevEco Studio Node directory first,
followed by the npm global bin directory and the DevEco toolchain directories. Do not
hard-code, probe, or modify installation paths in this skill. Verify the resolved tools:

```powershell
Get-Command node, npm, devecocli
node --version; npm --version; devecocli -V
```

Do not mix executables from different Node installations. If the resolved `node`, `npm`,
or `devecocli` is not the intended DevEco environment, stop and report the PATH issue.

## Scaffold

DevEco CLI creates a HarmonyOS application from the Empty Ability template. Provide the
project values as explicit options so the command is non-interactive:

```
devecocli create --project-path <project-dir> --app-name <AppName> --bundle-name <com.example.app> [--api-level <level>]
```

Options:

- `--project-path <project-dir>` — project directory; defaults to `./<app-name>`.
- `--app-name <AppName>` — application name.
- `--bundle-name <com.example.app>` — bundle name; defaults to `com.example.<app-name>`.
- `--api-level <level>` — optional API level; it is auto-detected from the SDK when omitted,
  and the minimum supported value is 17.

The project path must be an explicit directory path and must not be `.`. When the
current directory is the intended destination, pass its absolute path or its named
relative directory path (for example, `./my-app` rather than `.`).

The DevEco CLI interface documents the Empty Ability template only; do not assume a Native C++
template or unsupported `--template`/`--sdk` flags.

## Mandatory stop after scaffolding

After `devecocli create` succeeds:

1. Report the generated project path, app name, bundle name, and API level.
2. Confirm that only the CLI-generated scaffold was created.
3. Stop. Do not open, rewrite, or enhance `Index.ets` or any other generated source file.
4. Do not add feature code, resources, dependencies, tests, documentation, or configuration
   unrelated to the generated scaffold.
5. Do not run `devecocli build`, lint, run, install, or UI validation as part of this skill.

If the user also requested feature implementation, explicitly state that scaffolding is
complete and ask to continue with `ohos-app-dev`; do not silently continue in the same step.
For a standalone app whose APIs or permissions may require privileged identity, ask to
continue with `ohos-system-app-dev` for privilege preflight instead.

For a separately requested development step, use **`ohos-app-dev`** for the inner loop
(lint → build → run → logs → UI). Use **`conductor-dev`** only when the user requests
Conductor-based orchestration. ArkTS strict-mode rules and app architecture guidance
live in **`ohos-app-dev`** (`references/arkts-strict.md`, `references/architecture.md`).

## Out of scope

- Ordinary inner-loop work on an existing project → `ohos-app-dev`.
- Standalone apps that may require `hos_system_app`, elevated APL, ACL/provisioning, or a
  Full SDK system API → `ohos-system-app-dev`.
- System / persistent bundles (systemui, launcher, OHOS source-tree builds) → `ohos-system-dev`.
