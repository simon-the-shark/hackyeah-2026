# OpenHarmony Hackathon - Participant Setup

This guide walks you through the setup we recommend for your hackathon submission: one path that is known to work end to end. It's not the only valid way, this guide was created just to make your life easier.

The challenge itself - themes, technical requirements, deliverables and judging criteria - is described in the [challenge statement](hackathon_challenge.md). Read it before you start designing.

Stuck on something? The [FAQ](FAQ.md) has short answers to common questions about setup, agent tooling, testing and submission.

The [workshop presentation](presentation/Huawei%20Hackathon%20Challenge%20Workshop.pdf) introduces the OpenHarmony, HarmonyOS and Oniro challenge, what to build, and how to make a strong submission. Join Huawei's [task teaser session](https://hackyeah.pl/conference-agenda) on Saturday from 12:00 to 12:45 on the Softskills track.

<p align="center">
  <img src="presentation/workshop-first-slide.png" alt="First slide of the Huawei Hackathon Challenge workshop presentation" width="50%">
</p>

## Table of contents

- [The default workflow](#the-default-workflow)
  - [Prerequisites](#prerequisites)
  - [1. Install DevEco Studio](#1-install-deveco-studio)
  - [2. Set up the agent tooling](#2-set-up-the-agent-tooling)
  - [3. Create a project from the hackathon template](#3-create-a-project-from-the-hackathon-template)
  - [4. Start building](#4-start-building)
- [Alternative options](#alternative-options)
  - [Conductor Hackathon Template](#conductor-hackathon-template)
  - [Empty Ability (bare starter)](#empty-ability-bare-starter)
  - [Oniro App Builder and Oniro IDE](#oniro-app-builder-and-oniro-ide)
  - [React Native for OpenHarmony](#react-native-for-openharmony)
  - [Tool comparison](#tool-comparison)
  - [Emulator capability comparison](#emulator-capability-comparison)
- [Learning ArkTS](#learning-arkts)
- [Further resources](#further-resources)

## The default workflow

This is the path we recommend to every team. It uses the most mature toolchain and has the best emulator coverage. The automated agent setup is designed for this DevEco Studio toolchain; it does not automate the alternative toolchains listed later. By the end of it you will have DevEco Studio configured for emulation, an AI coding agent equipped with the hackathon skills and templates, and a project created from the hackathon starter that you can build and run.

### Prerequisites

Have these ready before you start. The agent setup in step 2 checks for them but deliberately does not install or upgrade any of them - if something is missing it tells you what and stops.

- **Windows** - the agent setup requires it (see step 1 for macOS).
- **DevEco Studio** - installed in step 1 and **launched at least once**, with its first-launch setup completed. That is what creates its configuration files, including the `country.region.xml` file that the agent setup switches to the China region.
- **Git** - any current release, from [git-scm.com](https://git-scm.com/download/win).
- **Node.js 22 or later, with npm** - from [nodejs.org](https://nodejs.org/). npm is included, and Node.js 22 or later is required because the DevEco CLI that the agent setup adds needs it.
- **Python 3** - from [python.org](https://www.python.org/downloads/windows/). The `python` command must run it.
- **npm's global executable directory on your `PATH`** - get it with `npm.cmd config get prefix` (usually `%AppData%\npm`). This is not the same directory as `npm` itself. The DevEco CLI that the agent setup installs, `devecocli`, only runs by name when this directory is on `PATH`, and npm does not add it for you.

Git, Node.js, npm and Python must be available on your `PATH`, because the agent setup only checks `PATH` and does not search your disk for them. Keep each installer's option to add the tool to `PATH` enabled, and reopen your agent and terminal after installing so that they pick up the change. To check, run `git --version`, `node --version`, `npm.cmd --version` and `python --version` in a terminal.

If `npm.cmd config get prefix` prints a directory that is not on your `PATH`, add that one directory to your user `PATH` yourself. It needs no administrator rights, and the agent setup will not do it for you. Then reopen your agent and terminal and paste the prompt again.

### 1. Install DevEco Studio

Follow the [Oniro environment setup guide](https://docs.oniroproject.org/application-development/environment-setup-guide/) and its [DevEco Studio installation page](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/installation/). Those pages cover both Windows and macOS. Launch DevEco Studio at least once and complete its first-launch setup, so that its configuration files are created; the agent setup in step 2 needs this.

If your Huawei account is still being activated and you cannot download DevEco Studio yet, use the [installer shared by the organizers](https://we.tl/t-7vo3xfckTY584PcV) as a fallback.

The default workflow in this README assumes **Windows**, because the agent tooling installed in step 2 requires it. On macOS, DevEco Studio itself still works, but the agent setup does not: make the [region change](FAQ.md#how-do-i-switch-the-deveco-studio-region-to-china-manually) by hand and set up your agent yourself.

### 2. Set up the agent tooling

Coding agents, AI assistants, MCP servers and agent skills are explicitly allowed and strongly encouraged by the challenge. This hackathon provides a prepared agent setup, delivered as an installer prompt rather than a script. Use a **coding agent**, not a chat-only chatbot: it must be able to run shell commands and write files on your computer.

1. Open [INSTALLATION_PROMPT.md](INSTALLATION_PROMPT.md) in this repository and copy its contents.
2. Paste the prompt into your coding agent - Codex, Claude Code, opencode, or another agent with local shell and file access.
3. Let the agent complete the user-level installation. Early on it may ask you to close DevEco Studio so that it can switch the region. It then prepares two project-template folders and gives you their exact source and destination paths.
4. Copying the two prepared template folders into place will most likely be the only manual step, because DevEco Studio normally stores its templates inside its protected installation directory. Close DevEco Studio and use File Explorer to copy both prepared folders into the destination. Windows will most likely ask you to approve the copy, because that destination is normally inside the DevEco Studio installation directory. If DevEco Studio is installed somewhere you can already write to, no approval is needed.
5. Tell the agent when the copy is complete. It verifies the templates and reports back with a status table.

The installer expects the [prerequisites](#prerequisites) to already be present, including DevEco Studio with a known installation directory. It deliberately does not install or upgrade any of them - if something is missing it will tell you what and stop.

This is what the prompt is doing:

- **Switches the DevEco Studio region to China** by editing `country.region.xml`. Outside China DevEco Studio only emulates smart watches; with the region set to China you can also emulate phones, tablets, 2-in-1 devices and TVs.
- **Installs nine agent skills at user level**:
  - `ohos-app-scaffold` - creates a new, untouched project skeleton and stops.
  - `ohos-app-dev` - the inner dev loop for an existing app: lint, build, run, logs and UI checks.
  - `ohos-system-app-dev` - privilege preflight and the development loop for standalone apps whose APIs, permissions or signing may require system-app identity.
  - `ohos-system-dev` - platform components built inside the OpenHarmony source tree, such as systemui and launcher.
  - `conductor-dev` - drives development through Conductor's orchestration.
  - `hmos-arkts-knowledge-retriever` - looks up grounded ArkTS and API references instead of relying on memory.
  - `hmos-arkui-scenario-development` - scenario-based ArkUI development routed through its REQ, DEV, FIX and VAL phases.
  - `hmos-arkui-develop-skill` - ArkUI work: pages, components, layout and state.
  - `hmos-arkui-mvvm-pattern` - MVVM layering and refactoring.
- **Installs the DevEco CLI** - `@deveco/deveco-cli` 1.3.4, globally, pinned to that exact version because our patches are verified only against it.
- **Applies two patches to the DevEco CLI**:
  - fix confusing wording in the linter output,
  - disable a memory sampler that we found to cause performance issues on some setups.
- **Installs the CLI's bundled skill** by running `devecocli init --skill`.
- **Installs two DevEco Studio project templates** - **Hackathon Template** and **Conductor Hackathon Template**.

It never overwrites content it did not install. Something it manages, such as one of the skills or the DevEco CLI, is updated when it is unmodified and outdated; anything that already differs is reported as a conflict and left alone. It does not change your PowerShell execution policy, does not add anything to `PATH`, and does not request administrator rights.

Two restarts are needed before you continue: **restart DevEco Studio** so the templates appear in the Create Project wizard, and **restart your agent** so it loads the new skills.

![Coding agent reporting that the skills, project templates and DevEco CLI were installed successfully](_deveco_screenshots/install_prompt_finished.png)

### 3. Create a project from the hackathon template

1. In DevEco Studio choose **Create Project**.
2. Select the **Hackathon Template** starter. It is published under the `ability` category and is combined with the built-in project and module templates.
3. Pick your device type. **Phone** is the safe default; the template also supports tablet, 2-in-1, car, wearable and TV.
4. Set **Compatible SDK** to **6.0.0 (API 20)**. This is the hackathon's minimum supported API.
5. Name the project and finish the wizard.
6. In the newly created project, open the project-level `build-profile.json5` file in the project root. Confirm that `compileSdkVersion` uses **API 23**, the newest OpenHarmony SDK available through DevEco Studio, and set `targetSdkVersion` to **API 24**, the newest emulator version available for the hackathon.

![Create Project wizard configured with the Hackathon Template, Compatible SDK 6.0.0 (API 20) and Phone as the device type](_deveco_screenshots/project_creation.png)

The following fields are in the project-level `build-profile.json5` file at the root of your project:

| Setting | What it controls | Hackathon default |
| --- | --- | --- |
| **Compatible SDK** (`compatibleSdkVersion`) | The oldest API level on which the app may be installed and run. Raise it if the app requires newer APIs on every supported device. | **API 20**, the challenge minimum |
| **Compile SDK** (`compileSdkVersion`) | The SDK used to compile the app and the APIs available to the compiler. | **API 23**, the newest OpenHarmony SDK available through DevEco Studio |
| **Target SDK** (`targetSdkVersion`) | The API level whose behavior the app is designed and tested against. | **API 24**, matching the newest available emulator |

In other words, compile against API 23, test against API 24 and retain compatibility with API 20. If you use an API introduced after API 20 without a compatible fallback, raise Compatible SDK to that API level.

The starter is already set up for the hackathon. It includes:

- `AGENTS.md` - project-level guidance that your coding agent picks up automatically.
- `CLAUDE.md` and `GEMINI.md` - compatibility shims that import the canonical guidance from `AGENTS.md`.
- `HACKATHON_BRIEF.md` - a place to write the brief for your own submission.
- `AI_WORKFLOW.md` - the mandatory public disclosure of the AI models, agents, MCP servers and skills you used, and of how you reviewed and validated their output.
- `hackathon-resources/` - participant reference material bundled so your agent can read it from the checkout: a short index, the `devecocli` command-line and agent capability matrix, and the emulator capability comparison. The challenge statement itself is not bundled; `AGENTS.md` points your agent to where it's kept.

### 4. Start building

Use the [Previewer](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/previewer/) for fast iteration on layout and logic, and the emulator when you need to exercise real device behaviour. If you have never built an OpenHarmony app before, [Create Your First App](https://docs.oniroproject.org/application-development/create-your-first-app/) is a complete walkthrough of the same flow.

Before asking your agent to build and deploy to an emulator for the first time, create a virtual device and download its system image yourself in DevEco Studio's Device Manager, then start it - this is a manual, GUI-only step that your agent cannot do for you, and the image download can be several gigabytes. See the [Emulator guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/emulator/) and the [FAQ](FAQ.md#no-devices-show-up-when-i-try-to-run-the-app-on-an-emulator-what-now) if no device shows up.

The starter is deliberately lightweight. It sets up the project structure and the hackathon constraints, but it does not prescribe how you work. `AGENTS.md` in particular is just plain guidance for your coding agent, not a fixed contract: if the agent's behaviour does not suit you, rewrite it. Your submission is judged on the app you build, not on whether `AGENTS.md` still reads the way the template generated it.

Before you go further, two sections below are worth a look: [Learning ArkTS](#learning-arkts) for tutorials and code labs, and the [emulator capability comparison](#emulator-capability-comparison) to see what the DevEco emulator can and cannot simulate.

Two reminders before you submit:

- The solution must run on an OpenHarmony, HarmonyOS or Oniro emulator or a compatible physical device. Test it there, not only in the previewer.
- If you used AI tools, `AI_WORKFLOW.md` is not optional. The challenge statement lists exactly what it has to document.

## Alternative options

The default workflow is the recommended one, but it is not the only supported one. The challenge explicitly allows compatible alternative toolchains, as long as your submission is reproducible and can be demonstrated.

### Conductor Hackathon Template

**Conductor Hackathon Template** is the second starter installed in step 2. Follow the [default workflow](#the-default-workflow) as written, but choose **Conductor Hackathon Template** in step 3 instead of **Hackathon Template**. It produces the same project structure and hackathon constraints as the default starter, but expects the `conductor-dev` skill to be the single workflow running the work. Choose it if you want to drive development through Conductor's orchestration rather than direct prompting. It omits `HACKATHON_BRIEF.md`, because Conductor tracks product scope and delivery state through its own artifacts instead.

### Empty Ability (bare starter)

**Empty Ability** is the built-in DevEco Studio template that the hackathon starter is based on. Starting from it gives you a clean project with none of the hackathon additions: no `AGENTS.md`, no `AI_WORKFLOW.md` and no bundled resources. That is a fine choice if you would rather set up your own workflow. Just note that `AI_WORKFLOW.md` is still required at submission time if you used AI tools at all, so create it at the project root before you submit.

### Oniro App Builder and Oniro IDE

**Oniro App Builder** is a command-line tool that provides everything needed to develop an OpenHarmony app:

- initialising a project,
- signing and building the app,
- testing it on an emulator.

**Oniro IDE** is a Visual Studio Code extension built on top of Oniro App Builder. It offers mostly the same utilities through a graphical interface.

Follow [this tutorial](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/) to install Oniro App Builder or Oniro IDE and learn how to use them. This path targets Windows and Linux, uses a QEMU-based emulator, and is still under active development, so expect rough edges. Before choosing it, check the [emulator capability comparison](#emulator-capability-comparison) to make sure the Oniro Emulator supports the features your project needs.

If you are developing with an AI coding agent, install the [Oniro Agent Skills](https://github.com/eclipse-oniro4openharmony/agent-skills). They provide the same app-development workflows as the skills in the default setup, but use `oniro-app` instead of `devecocli`.

### React Native for OpenHarmony

If you would rather build a cross-platform application, React Native for OpenHarmony (RNOH) is an accepted option. Note that cross-platform development is an alternative to native APIs, not a substitute for the platform: a submission still has to include an OpenHarmony or HarmonyOS target together with the native container, bridge and build configuration required to produce a working platform package. An Android, iOS, web or desktop build on its own is not sufficient.

- [React Native for OpenHarmony](https://gitcode.com/CPF-RN/ohos_react_native/tree/0.77-main/docs/en) - English documentation
- [React Native for OpenHarmony tutorial](https://docs.oniroproject.org/application-development/codeLabs/cross-platform/rn-example/)

### Tool comparison

| | DevEco Studio (IDE) | Oniro App Builder (CLI) / Oniro IDE (VS Code extension) |
|---|---|---|
| Operating system | Windows 10/11 64-bit or macOS 12/13/14 (Arm) | Windows or Linux |
| Emulator | DevEco Studio Emulator | Oniro Emulator (QEMU-based) |
| Maturity | Mature tool maintained by Huawei | Still in development - you might encounter some bugs |

### Emulator capability comparison

This table shows the differences in emulated capabilities between the DevEco Studio Emulator and the Oniro Emulator.

| Feature | DevEco Studio Emulator | Oniro Emulator (QEMU-based) |
|---|---|---|
| Push notifications support | ✅ | ✅ |
| Granting extended app privileges (e.g. notification listener access) | ✅ | ✅ |
| Install system apps | ✅ | ✅ |
| Screen resolution customization | ✅ | ✅ |
| Internet access | ✅ | ✅ |
| Widgets support | ✅ | ✅ |
| Advanced internet configuration | ✅ | ❌ |
| Multi-device profiles (phone, tablet, 2in1, wearable, TV) | ✅ | ❌ |
| Screen density / orientation testing | ✅ | ❌ |
| Basic sensor simulation (accelerometer, gyroscope, GPS) | ✅ | ❌ |
| Wearable-specific simulation (heart rate, step count, crown button) | ✅ | ❌ |
| TV / remote control simulation | ✅ | ❌ |
| Distributed feature testing | ❌ | ❌ |
| Real camera hardware | ❌ | ❌ |
| NFC (Near Field Communication) | ❌ | ❌ |
| Bluetooth pairing with real devices | ❌ | ❌ |
| Cellular/SIM features | ❌ | ❌ |
| Biometric hardware | ❌ | ❌ |
| Accurate battery and thermal behavior | ❌ | ❌ |

## Learning ArkTS

- [Create your first app in ArkTS](https://docs.oniroproject.org/application-development/create-your-first-app/)
- [More tutorials](https://docs.oniroproject.org/application-development/basic-concepts/)
- [Code labs](https://docs.oniroproject.org/application-development/codeLabs/) - example apps with explained implementation details

## Further resources

- [Official Oniro GitHub page](https://github.com/eclipse-oniro4openharmony)
- [OpenHarmony Documentation](https://github.com/openharmony/docs)
- [Oniro Documentation](https://docs.oniroproject.org/)
- [HarmonyOS Development Documentation](https://developer.huawei.com/consumer/en/harmonyos/develop/)
- [HarmonyOS Release Notes](https://developer.huawei.com/consumer/en/doc/harmonyos-releases/overview-allversion)
- [HMOS Code Workshop](https://github.com/onirodeveloper/harmonyos_samples) - Huawei's open-source HarmonyOS sample app: a browsable component library plus official code samples and best-practice articles
- [Oniro Agent Skills](https://github.com/eclipse-oniro4openharmony/agent-skills) - skills for AI agents working on ArkTS apps
- [OpenCode guide](opencode-guide.md) - what OpenCode is and how to install and use it as your coding agent
- [FAQ](FAQ.md) - short answers to common questions about setup, agent tooling, testing and submission
- [Quickstart guide](quickstart-guide.md) - DevEco Studio and Oniro setup, the DevEco region configuration, and ArkTS and React Native learning links
