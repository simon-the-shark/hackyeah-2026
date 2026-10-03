# Frequently Asked Questions

Quick answers for hackathon participants. For the full setup walkthrough, see the [README](README.md), and for the rules, see the [challenge statement](hackathon_challenge.md).

## Table of contents

- [Setup](#setup)
- [Agent tooling](#agent-tooling)
- [Building and testing](#building-and-testing)
- [Signing](#signing)
- [Submission](#submission)
- [Oniro App Builder and Oniro App IDE](#oniro-app-builder-and-oniro-app-ide)

## Setup

### Do I have to use Windows?

**Windows is recommended, not strictly required.**

The agent installer in [INSTALLATION_PROMPT.md](INSTALLATION_PROMPT.md) only supports Windows. DevEco Studio itself also runs on macOS; there you make the [region change](#how-do-i-switch-the-deveco-studio-region-to-china-manually) by hand and set up your agent yourself. Its emulator is available only on supported Apple Silicon Macs, so Intel Macs need a physical target. Oniro App Builder and Oniro IDE target Windows and Linux for this hackathon instead. See [README step 1](README.md#1-install-deveco-studio), the [tool comparison](README.md#tool-comparison), and the Oniro documentation's [environment overview](https://docs.oniroproject.org/application-development/environment-setup-guide/#deveco-studio).

### What do I do if I'm not on Windows?

**On macOS, use DevEco Studio with the manual steps; on Linux, use Oniro App Builder or Oniro IDE instead.**

DevEco Studio itself runs on macOS but not Linux; on macOS you get the same toolchain as the default workflow, but you make the [region change](#how-do-i-switch-the-deveco-studio-region-to-china-manually) by hand and install your agent's skills yourself, since the automated installer is Windows-only. The DevEco Studio emulator is available only on supported Apple Silicon Macs, so use a physical target on an Intel Mac. On Linux, DevEco Studio isn't available at all, so use [Oniro App Builder or Oniro IDE](README.md#oniro-app-builder-and-oniro-ide) instead - a CLI and VS Code extension that target Windows and Linux with a QEMU-based emulator, plus the [Oniro Agent Skills](https://github.com/eclipse-oniro4openharmony/agent-skills) if you want the same agent workflow. See the [tool comparison](README.md#tool-comparison) and [emulator capability comparison](README.md#emulator-capability-comparison) before choosing, since the Oniro Emulator supports less than the DevEco Studio Emulator.

### Why do I need to switch the DevEco Studio region to China?

**To unlock emulator images for more device types.**

Outside China DevEco Studio only emulates smart watches; with the region set to China you can also emulate phones, tablets, 2-in-1 devices and TVs. The setting is `<countryregion name="CN"/>` in `country.region.xml`. On Windows the [agent installer](INSTALLATION_PROMPT.md#switch-the-deveco-studio-region-to-china) does this for you; on macOS, or if you skip the installer, do it yourself as described in [How do I switch the DevEco Studio region to China manually](#how-do-i-switch-the-deveco-studio-region-to-china-manually).

### How do I switch the DevEco Studio region to China manually?

**Edit `country.region.xml` with DevEco Studio closed.**

You only need this if you are not using the [agent installer](INSTALLATION_PROMPT.md#switch-the-deveco-studio-region-to-china) - on macOS, or with one of the [alternative options](README.md#alternative-options). The setting lives in a `country.region.xml` file inside your DevEco Studio configuration directory, and its `<countryregion>` element must have the `name` attribute set to `CN`:

```xml
<countryregion name="CN"/>
```

**Windows:** close DevEco Studio, then open `%AppData%\Huawei\DevEcoStudio<version>\options\country.region.xml` and set the `name` attribute to `CN`. Use exactly this path, and not `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Huawei`.

**macOS:** close DevEco Studio, then open `~/Library/Application Support/Huawei/DevEcoStudio<version>/options/country.region.xml` and set the `name` attribute to `CN`. The command in the screenshot below is usually the quickest way to do it. Use exactly this path.

![Terminal command that modifies country.region.xml](_deveco_screenshots/macos_command.png)

For the exact `DevEcoStudio<version>` directory name, see [the next question](#which-deveco-studio-version-directory-do-i-edit). Then start DevEco Studio again and confirm in the device or emulator manager that the phone, tablet, 2-in-1 and TV profiles are now available.

![DevEco Studio Device Manager showing the additional emulator device profiles available after the region change](_deveco_screenshots/deveco_emulators.png)

### Which DevEco Studio `<version>` directory do I edit?

**At the time of writing, most likely `DevEcoStudio6.1`.**

But do not assume it: the name is the product's data directory, and it is not the IDE build number (something like `243.24978…`) that the registry shows as the version. Read it from `dataDirectoryName` in `product-info.json` inside the DevEco Studio installation directory, or take the major and minor parts of its `version` (`6.1.1.280` gives `DevEcoStudio6.1`), and check it against the directories in `%AppData%\Huawei`. If several `DevEcoStudio*` directories exist, use the one that matches your installed version and leave the others alone. This is also the directory to use instead of `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Huawei`, which looks similar but is the wrong one.

### I can't find `country.region.xml`. What now?

**Launch DevEco Studio once first.**

Its first-launch setup creates the configuration files, including this one, so complete that and try again. Edit the file at `%AppData%\Huawei\DevEcoStudio<version>\options\country.region.xml` (Windows) or `~/Library/Application Support/Huawei/DevEcoStudio<version>/options/country.region.xml` (macOS), with DevEco Studio closed. See [README step 1](README.md#1-install-deveco-studio) for the first launch and [How do I switch the DevEco Studio region to China manually](#how-do-i-switch-the-deveco-studio-region-to-china-manually) for the region change.

### Which Node.js version do I need?

**Node.js 22 or later, with npm included.**

The DevEco CLI that the installer adds requires it. See the [prerequisites](README.md#prerequisites) in the README and [README step 2](README.md#2-set-up-the-agent-tooling).

### Does the installer install Git, npm or Python for me?

**No.**

Git, Node.js/npm and Python 3 (the `python` command must work) are prerequisites - the installer only checks for them on your `PATH` and will not install, upgrade, or search your disk for them. Install each one yourself, keep each installer's option to add it to `PATH` enabled, then reopen your agent and terminal so the updated `PATH` is picked up. See the [prerequisites](README.md#prerequisites) in the README and the [prerequisites](INSTALLATION_PROMPT.md#prerequisites) in the installation prompt.

### `devecocli` is not found even though npm and Node.js are installed. What now?

**Add npm's global executable directory to `PATH`.**

That directory (`npm.cmd config get prefix`, usually `%AppData%\npm`) is different from npm itself, and npm does not add it for you, so commands like `devecocli` only run by name once it is there. If it is missing, add it to your user `PATH` yourself; no administrator rights are needed. See the [prerequisites](README.md#prerequisites) in the README.

### `devecocli` is installed but crashes or behaves strangely. What now?

**Make sure the first `node` on your `PATH` is version 22 or later.**

DevEco Studio ships its own Node.js, which can be older than the 22 that `devecocli` requires. If the DevEco Studio `tools\node` directory comes first on `PATH`, `devecocli` starts under that older Node and fails while loading, typically with a `SyntaxError: Invalid regular expression flags` from inside its own `node_modules`. Check which copy wins:

```powershell
where.exe node
node --version
```

If `where.exe` lists a `Huawei\DevEco Studio\tools\node` path first, or `node --version` reports anything below 22, reorder your user `PATH` so your own Node.js 22+ directory comes first, then reopen your agent and terminal. See [Which Node.js version do I need?](#which-nodejs-version-do-i-need) and the [prerequisites](README.md#prerequisites) in the README.

### `python --version` fails or opens the Microsoft Store. What now?

**Python isn't actually installed and working as the `python` command.**

Windows ships a `python` shortcut (an app execution alias in `%LOCALAPPDATA%\Microsoft\WindowsApps`) that opens the Microsoft Store instead of running Python, and someone who only has the `py` launcher has no `python` command at all. The installer checks that `python --version` prints `Python 3.x`, so either case counts as Python being missing. Install Python 3 from [python.org](https://www.python.org/downloads/windows/) with the option to add it to `PATH` enabled, or turn off the two `python` aliases in Settings → Apps → Advanced app settings → App execution aliases. Then reopen your agent and terminal. See the [prerequisites](README.md#prerequisites) in the README.

### The agent cannot find DevEco Studio. What now?

**Give it the installation directory yourself.**

The installer needs the DevEco Studio installation directory (for example `C:\Program Files\Huawei\DevEco Studio`), but DevEco Studio is not on `PATH` and the installer does not scan your disk for it. You can check a candidate directory yourself: `product-info.json` must be directly inside it and show `"name": "DevEco Studio"`. If you are not sure where it is installed, the `InstallLocation` value of its uninstall entry in the registry (under `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`) shows it. See the [prerequisites](INSTALLATION_PROMPT.md#prerequisites) in the installation prompt.

## Agent tooling

### Do I need CodeGenie?

**No.**

CodeGenie is the AI agent built into DevEco Studio. It is not necessary for this hackathon; you can work with any external coding agent, such as Codex, Claude Code or opencode. See the note in the [quickstart guide](quickstart-guide.md#deveco-studio).

### Which agent can I use with the installer prompt?

**Any coding agent with local shell and file access.**

A chatbot without those capabilities will not work, because the installer has to run commands and write files on your machine. See [README step 2](README.md#2-set-up-the-agent-tooling).

### Do I need administrator rights?

**Usually not.**

You should not need to run your agent or terminal as administrator, and the installer does not ask to be elevated. The template copy will most likely be the only step that needs administrator rights: DevEco Studio normally keeps its project templates inside its protected installation directory, so you copy the two prepared template directories there yourself with File Explorer, and Windows will most likely ask you to approve that copy. If DevEco Studio is installed somewhere you can already write to, even that copy will not need approval. If you have no administrator rights at all, Windows refuses the copy and you need IT to do it or to give you the rights. If any step turns out to need approval on your machine, the installer prepares it completely and asks you to perform only that step, then checks the result itself. See [README step 2](README.md#2-set-up-the-agent-tooling) and the [template step of the installation prompt](INSTALLATION_PROMPT.md#prepare-the-deveco-studio-templates-for-manual-installation).

### Why does the installer pin DevEco CLI to version 1.3.4?

**Because its patches are verified only against that exact version.**

The patches applied by `scripts/apply-devecocli-patches.mjs` are verified only against 1.3.4, so the installer uses it even if a newer release exists. See [Install DevEco CLI](INSTALLATION_PROMPT.md#install-deveco-cli) in the installation prompt.

### Do I have to restart anything after the installer finishes?

**Yes, two things.**

Restart DevEco Studio so the **Hackathon Template** and **Conductor Hackathon Template** appear in the Create Project wizard, and restart your agent so it loads the new skills. See [README step 2](README.md#2-set-up-the-agent-tooling) and [Restarts and final report](INSTALLATION_PROMPT.md#restarts-and-final-report) in the installation prompt.

### Which template should I pick: Hackathon Template or Conductor Hackathon Template?

**Hackathon Template, unless you specifically want Conductor's orchestration.**

The Conductor variant has the same project structure and hackathon constraints, but expects the `conductor-dev` skill to run the work and omits `HACKATHON_BRIEF.md`. See [README step 3](README.md#3-create-a-project-from-the-hackathon-template) and [Conductor Hackathon Template](README.md#conductor-hackathon-template).

### `npm install -g` fails with a permission error (EPERM or EACCES). What now?

**Point npm's global prefix at a directory in your own profile.**

This happens when npm's global prefix is inside `C:\Program Files\nodejs`, which needs administrator rights, and the installer does not elevate. Run `npm.cmd config set prefix "%APPDATA%\npm"` and run the installer again. This edits your `~\.npmrc`, so let your agent ask you before it does it. See [Install DevEco CLI](INSTALLATION_PROMPT.md#install-deveco-cli) in the installation prompt.

### The installer reports a conflict with an existing skill. What now?

**A same-named skill from another source is already installed.**

`npx.cmd skills ls -g` lists it with `Source: local`. The installer never overwrites content that differs, so it reports the conflict and leaves your copy in place. To replace it, back it up first, remove it with `npx.cmd skills remove <name> -g -y`, and install it again from the link in the [installation prompt](INSTALLATION_PROMPT.md#install-skills).

### The installer reports a conflict with an existing template. What now?

**An old copy of the template differs from the new one, so the installer leaves it alone.**

An earlier copy of **Hackathon Template** or **Conductor Hackathon Template** may already be in DevEco Studio's templates directory. The installer will not overwrite or merge it. Close DevEco Studio, rename the old directory in File Explorer (keeping it as a backup) or delete it, copy in the freshly prepared one, and let your agent verify it. Do not use "Copy and Replace" over the old directory: Explorer merges the two and keeps files that exist only in the old one, so the result is never identical to the prepared template. See the [template step of the installation prompt](INSTALLATION_PROMPT.md#prepare-the-deveco-studio-templates-for-manual-installation).

### My repository is a downloaded ZIP and files are blocked. What now?

**Unblock the extracted files, or clone with `git` instead.**

Files from a browser download carry the Windows "downloaded from the internet" mark, which can block PowerShell scripts under a `RemoteSigned` policy, and `Copy-Item` copies the mark, so templates copied into the DevEco Studio directory would carry it too. Prefer a `git clone`. If you use a ZIP, extract it to a short path such as `C:\oni` and run `Get-ChildItem <folder> -Recurse -File | Unblock-File` on the extracted folder. This removes only the mark and does not change file contents. See [Install DevEco CLI](INSTALLATION_PROMPT.md#install-deveco-cli) in the installation prompt.

### Something fails with a path that is too long. What now?

**Keep the checkout in a short path, and enable Windows long paths if you need to.**

Windows refuses to create paths longer than 260 characters unless long paths are enabled, and this repository is deep enough to hit that limit once you clone it into a long directory. It can bite in two places: checking out or extracting the repository, and copying a prepared template into DevEco Studio's templates directory. The symptoms are a `Filename too long` error from `git`, or a copy that fails or silently comes out incomplete.

Check the setting with:

```powershell
(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled).LongPathsEnabled
```

If it prints `0`, long paths are off. You have two options. The cheapest is to keep everything in a short path - clone to something like `C:\oni` instead of a deep folder under your user profile - and for the clone pass the option for that clone only:

```powershell
git -c core.longpaths=true clone <url> C:\oni
```

The other is to enable long paths itself, under Settings → System → About → Advanced system settings, or by setting that registry value to `1`. That needs administrator rights, so it is your decision rather than your agent's. If a template copy came out short, delete the incomplete directory and copy the prepared template again from scratch - do not copy over the top of it, because Explorer merges rather than replaces. See [README step 2](README.md#2-set-up-the-agent-tooling) and the [template step of the installation prompt](INSTALLATION_PROMPT.md#prepare-the-deveco-studio-templates-for-manual-installation).

## Building and testing

### Which API level should I target?

**Use API 24 for the default DevEco Studio workflow; use API 23 for the Oniro Emulator workflow.**

The challenge only requires API 20 or later, declared as the minimum where applicable. In the default DevEco Studio workflow, keep **Compatible SDK** at **6.0.0 (API 20)** for the widest device compatibility, and separately set `targetSdkVersion` to API 24 in `build-profile.json5` unless your app relies on APIs introduced later. The Oniro Emulator itself runs OpenHarmony 6.1/API 23, so install SDK 6.1 and create Oniro App Builder projects with `--sdk 23`; do not depend on API-24-only behavior when that emulator is your target. See [README step 3](README.md#3-create-a-project-from-the-hackathon-template), the [technical requirements](hackathon_challenge.md#technical-requirements), and the Oniro documentation's [version/API reference](https://docs.oniroproject.org/application-development/environment-setup-guide/#openharmony-version-and-api-level-reference).

### My project will not build, or it builds for the wrong platform. What should I check?

**Start with the selected product in the project-level `build-profile.json5`.**

The file at the project root chooses the runtime, SDK and signing configuration. A module-level file such as `entry/build-profile.json5` controls that module's build options and targets; it does not normally decide whether the project is OpenHarmony or HarmonyOS. In the root file, inspect the entry in `app.products` that you are building (`default` unless you select another product):

| Setting | OpenHarmony product | HarmonyOS product |
| --- | --- | --- |
| `runtimeOS` | `"OpenHarmony"` | `"HarmonyOS"` |
| `compileSdkVersion` | API number, for example `23` | Release label, for example `"6.1.1(24)"` |
| `compatibleSdkVersion` | API number, for example `20` | Release label, for example `"6.0.0(20)"` |
| Referenced `signingConfig` | OpenHarmony material generated by `oniro-app sign` | AppGallery Connect material generated by `oniro-app sign --harmonyos`, with `type: "HarmonyOS"` |

For example, the product portion looks like this:

```json5
// OpenHarmony
{
  "name": "default",
  "signingConfig": "default",
  "compileSdkVersion": 23,
  "compatibleSdkVersion": 20,
  "runtimeOS": "OpenHarmony"
}

// HarmonyOS
{
  "name": "default",
  "signingConfig": "default",
  "compileSdkVersion": "6.1.1(24)",
  "compatibleSdkVersion": "6.0.0(20)",
  "runtimeOS": "HarmonyOS"
}
```

Use these clues to narrow down the failure:

- `SDK component missing` usually means a HarmonyOS `compileSdkVersion` does not name the exact installed SDK release, or the required SDK is not installed.
- Missing ArkTS properties or APIs usually means the selected compile SDK is too old; see [the dependency-error answer](#why-does-the-build-report-missing-arkts-properties-or-apis-inside-a-dependency).
- A build that unexpectedly uses the OpenHarmony SDK may have a missing or misspelled `runtimeOS`: App Builder treats only the exact value `"HarmonyOS"` as HarmonyOS.
- A HAP that builds but is rejected by a HarmonyOS device may reference OpenHarmony signing material; see [the HarmonyOS signing answer](#why-does-a-harmonyos-hap-build-successfully-but-fail-to-install).
- If there are several products, confirm the intended product's values and pass its name with `oniro-app build --product <name>`.
- The product's `signingConfig` value must match the `name` of an entry in `app.signingConfigs`.

Prefer creating the project with the correct App Builder template instead of converting the file by hand. The default `EmptyAbility` template is OpenHarmony; `--template HarmonyOSApp` is HarmonyOS. You still pass a numeric API to `--sdk`, and App Builder writes the appropriate numeric OpenHarmony value or versioned HarmonyOS label. See the App Builder [HarmonyOS workflow](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/blob/main/packages/cli/README.md#harmonyos-apps).

### Is the Previewer enough to test my app?

**No.**

The Previewer is good for fast layout and logic iteration, but the solution must run on an OpenHarmony, HarmonyOS or Oniro emulator or a compatible physical device. Test it there. See [README step 4](README.md#4-start-building) and the [technical requirements](hackathon_challenge.md#technical-requirements).

### No devices show up when I try to run the app on an emulator. What now?

**Create and start a virtual device with its system image first.**

This usually means no virtual device has been created yet in DevEco Studio, or one exists but its system image was never downloaded, or it was downloaded but the emulator was never started - none of that happens automatically. Open DevEco Studio's Device Manager, create (or pick) a virtual device matching your target device type and API level, download its system image if needed, and start it before asking your agent to build and deploy again. The system image download can be several gigabytes. See the [Emulator guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/emulator/) and [README step 4](README.md#4-start-building).

### Which emulator or system image version should I use?

**The newest one available.**

When you create or update a virtual device in DevEco Studio's Device Manager, pick the latest system image offered for your target device type rather than an older one - it gives the broadest API and platform-capability coverage. See the [Emulator guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/emulator/) and, if none show up yet, [the previous question](#no-devices-show-up-when-i-try-to-run-the-app-on-an-emulator-what-now).

### What can the emulator not simulate?

**Mostly real hardware-dependent behaviour.**

Among other things, it cannot simulate real camera hardware, NFC, Bluetooth pairing with real devices, cellular/SIM features, biometrics or accurate battery and thermal behaviour. See the full [emulator capability comparison](README.md#emulator-capability-comparison) before choosing device-dependent behaviour.

### Can I build and test a system app?

**Yes, on an emulator—but not on a physical device.**

If your project needs system-app identity or privileged APIs, use an emulator as your target. Ordinary apps can still be installed and tested on compatible physical devices. See the [emulator capability comparison](README.md#emulator-capability-comparison) for the available emulator options.

### Can I build a cross-platform app?

**Yes, but it still needs a working OpenHarmony or HarmonyOS target.**

React Native for OpenHarmony is one accepted option, but an Android, iOS, web or desktop build alone is not sufficient. The submission must include an OpenHarmony or HarmonyOS target with the native container, bridge and build configuration needed to produce a working platform package. See [React Native for OpenHarmony](README.md#react-native-for-openharmony) and the [technical requirements](hackathon_challenge.md#technical-requirements).

## Signing

### Do I need a Huawei account to sign my app?

**Only for automatic signing. A debug build from DevEco Studio needs no account.**

DevEco Studio's recommended setup is **File → Project Structure → Signing Configs → Automatically generate signing configuration**, and that asks you to sign in with a Huawei/HarmonyOS developer account so it can generate the keystore, certificate and provisioning profile for you. You do not need it to run your app: a debug build produced by the IDE's Run and Debug is signed with a development certificate automatically and installs on your own emulator or device. You only need an account-backed signing configuration once you want a `.hap` you can hand in or share. See the [signing guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/build-variants-and-signing/) and the [required deliverables](hackathon_challenge.md#required-deliverables).

### Why does the build say my app is not signed?

**The project has no signing configuration attached to the product.**

A new project is created with `"signingConfigs": []`, and the product entry in `build-profile.json5` points at a signing config name that does not exist yet, so the build has nothing to sign with. Open **File → Project Structure → Signing Configs**, create one (automatic is fine for a debug build), and make sure the product in `build-profile.json5` references it by name. See the [signing guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/build-variants-and-signing/).

### Why does `oniro-app sign` report that Java or `keytool` is missing?

**Oniro App Builder needs a JDK on `PATH` to generate signing material.**

Install a JDK, open a new terminal or restart VS Code so it receives the updated environment, and check that both commands resolve:

```powershell
java -version
keytool -help
```

A JRE by itself may provide `java` without the `keytool` utility needed here. See the prerequisite in the [Oniro tools setup guide](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/#installing-the-tools).

### Why does a HarmonyOS HAP build successfully but fail to install?

**It may be signed with OpenHarmony material, or its HarmonyOS debug profile may have expired.**

For a product whose `runtimeOS` is `HarmonyOS`, a stale OpenHarmony signing configuration can still produce `BUILD SUCCESSFUL` and an `entry-default-signed.hap`, but a HarmonyOS device will reject that HAP. Sign through AppGallery Connect, then rebuild:

```text
oniro-app auth login
oniro-app sign --harmonyos .
oniro-app build .
```

HarmonyOS debug profiles are short-lived - currently issued profiles have been observed with a roughly 14-day validity period - and App Builder does not print the expiry date. If a previously installable HAP starts being rejected, rerun `oniro-app sign --harmonyos .` to refresh expired material; add `--force` if you need to regenerate it before the CLI considers it expired, then rebuild. Do not diagnose this from the `-signed.hap` filename alone: that only says that some signing material was used. See the open issues for [wrong-platform signing](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/issues/19) and [hidden profile expiry](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/issues/24).

### `devecocli signature generate` does not work. What now?

**That command is region-restricted; use DevEco Studio to create signing material.**

`signature generate` is present in the CLI but does not work outside mainland China, so a failure here is expected rather than a broken installation. Create the signing material in DevEco Studio instead, through the Signing Configs described above. See the [devecocli capability matrix](default_template/hackathon-resources/devecocli.md) and the [signing guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/build-variants-and-signing/).

### Installing a new build fails because the signing information differs. What now?

**The app already on the device was installed with a different signing identity.**

This usually shows up as `9568332 install sign info inconsistent`, and it happens when the bundle on the device was signed by another keystore or profile than the one you are installing now - after switching from automatic to manual signing, or between team members' machines. The safe fix is to uninstall the old copy and install fresh. Ask your agent first: removing a bundle deletes its data, and for a privileged or system app uninstalling can be destructive, so do not let it happen silently. See [README step 4](README.md#4-start-building).

### Should I commit my keystore and its passwords?

**You shouldn't. Never commit signing material, and never commit its passwords.**

Nothing in Git or DevEco Studio stops you: a keystore, a certificate and a password in a config file are all just files, so committing them works and nothing will warn you. That is precisely what makes it dangerous rather than impossible. Your keystore (`.p12`), certificates and provisioning profile are credentials, and anyone who has them can sign as you. Keep them out of the repository with `.gitignore`, and keep passwords in a local or CI secret rather than a tracked file. If you have already committed them, treat them as leaked and generate new ones - deleting the file in a later commit does not remove it from the history. The submission is a [public source code repository](hackathon_challenge.md#required-deliverables), so this applies even to a hackathon project. See the [signing guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/build-variants-and-signing/).

## Submission

### What do I have to submit?

**A public repo, build/run instructions, a working `.hap`, a demo recording, and an architecture description - plus `AI_WORKFLOW.md` if you used AI.**

In full: a public source code repository; reproducible setup, build, installation and launch instructions; a working `.hap` package; a brief recorded demonstration; a concise architecture and implementation description; and `AI_WORKFLOW.md` when AI-assisted tools were used. If the product has AI features, add extra AI integration documentation. The full list is in the [challenge statement](hackathon_challenge.md#required-deliverables).

### Is `AI_WORKFLOW.md` mandatory?

**Yes, if you used AI at all.**

That covers using AI tools during development as well as shipping an AI feature. Both hackathon templates already include a copy to fill in. See [Use of AI](hackathon_challenge.md#use-of-ai) in the challenge statement and [README step 3](README.md#3-create-a-project-from-the-hackathon-template).

### What does `AI_WORKFLOW.md` have to document?

**Your AI tools, prompts, workflow, and validation approach.**

In full: the models, agents, MCP servers and skills you used, the main prompts and instructions, your workflow, and how you reviewed and validated the output, plus known limitations. Remove API keys, credentials and personal data before publishing. See [Use of AI](hackathon_challenge.md#use-of-ai) in the challenge statement.

### Who records the demo video?

**You do.**

Your agent can remind you and help you rehearse the demo narrative, but capturing the recording is your task. The recording is one of the [required deliverables](hackathon_challenge.md#required-deliverables).

### Can I use AI tools?

**Yes, and it's encouraged.**

Coding agents, AI assistants, MCP servers and agent skills are permitted and strongly encouraged, as long as you document them in `AI_WORKFLOW.md`. See [Use of AI](hackathon_challenge.md#use-of-ai).

### Which challenge themes can I pick?

**Intelligent Experiences, Spatial Experiences, or Human-Centric Technology.**

Many of the best ideas sit across more than one, but the idea should clearly lead with one of them. See the [challenge description](hackathon_challenge.md#challenge).

## Oniro App Builder and Oniro App IDE

### Why does Oniro App Builder say a device command succeeded when nothing happened on my device?

**Look for a visible `hdc` line beginning with `[Fail]`: `hdc` probably could not choose a device, and Oniro App Builder mistook that for success.**

This most commonly happens when several devices or emulators are connected and the command does not include `--device`. For example, an installation can produce contradictory output like this:

```text
Installing app from C:\path\to\project...
[hdc] [Fail]ExecuteCommand need connect-key? please confirm a device by help info.
App installed.
```

The exact `hdc` wording can vary by version, but the `[Fail]` line is the real result and the later success message is incorrect. The same problem can affect launch, apply, uninstall, stop, file-transfer, reboot, input, gesture and log-watching commands. List the available targets, then rerun the command with the serial or `host:port` address of the device you want:

```powershell
oniro-app devices
oniro-app app install . --device <device-serial-or-address>
```

Use a target whose status is `Connected`. If it is `Offline`, reconnect it; if it is `Unauthorized`, unlock the device and approve the debugging connection. Supplying the serial of an offline or unauthorized device does not make it usable.

Pass the same `--device` value to every later command that communicates with that device; the CLI does not remember the selection between commands. Until this is fixed, do not rely on the success message alone when `--device` was omitted, and verify the result on the intended device. OpenHarmony's [hdc documentation](https://github.com/openharmony/docs/blob/master/en/application-dev/dfx/hdc.md#connecting-to-the-specified-target-device) says that selecting a target is mandatory when several devices are connected. See the [Oniro App Builder command reference](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/blob/main/packages/cli/README.md) for the `--device` option on each device command.

### Why does my Oniro App Builder log capture include old logs?

**The current log watcher includes entries already in the device's HiLog buffer.**

The `--for` value controls how long `oniro-app watch` keeps the log stream open; it does not limit the results by their timestamp. When the stream starts, HiLog first emits its existing buffered entries, so matching older logs can appear alongside logs generated during the requested interval. If you need only new logs, clear the buffer immediately before starting the watcher:

```powershell
hdc -t <device-serial-or-address> shell hilog -r
oniro-app watch --log '<pattern>' --for <milliseconds> --device <device-serial-or-address>
```

Clearing the buffer discards its existing logs. See the OpenHarmony documentation for [`hilog -r`](https://github.com/openharmony/docs/blob/master/en/application-dev/dfx/hilog.md#clearing-the-log-buffer).

### Why do install, launch or logs fail in Oniro App IDE when several devices are connected?

**The VS Code extension cannot currently select a specific `hdc` device.**

Oniro App IDE has no device picker or device setting, and its install, launch, **Run All** and HiLog actions do not pass a device serial or address to `hdc`. They therefore work reliably only when `hdc` can select the intended device automatically. **Run All** also starts the Oniro Emulator, so using it while a physical device is connected can create the two-target situation that triggers this failure. Disconnect or stop every other device and emulator, or keep using the extension to build and use Oniro App Builder in the integrated terminal for device operations:

```powershell
oniro-app devices
oniro-app app install . --device <device-serial-or-address>
oniro-app app launch . --device <device-serial-or-address>
```

There is currently no extension setting equivalent to the CLI's `--device` option. See the [Oniro App IDE repository](https://github.com/eclipse-oniro4openharmony/oniro-vscode-ext) for the current extension.

### Why doesn't my real Oniro device appear in `oniro-app devices`?

**Check the device's USB mode or establish the Wi-Fi `hdc` connection first.**

For USB, connect the device and choose **Transfer files** when it asks which USB mode to use. For Wi-Fi, put the computer and device on the same network, enable **Developer Options**, **HDC Debugging** and **Debugging via WLAN** on the device, note the displayed `IP_ADDRESS:PORT`, and run:

```powershell
oniro-app emulator connect --address <IP_ADDRESS>:<PORT>
oniro-app devices
```

Despite its name, `emulator connect` can establish the `hdc` connection to a physical device address. Wi-Fi connection is available only through Oniro App Builder, not Oniro App IDE. Once connected, use the device's serial or address with `--device` if another target is present. See the official [real-device connection guide](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/real-device/).

### Why does the Oniro Emulator fail before a window opens on Windows or Linux?

**Installing the emulator image is not enough: QEMU and the host accelerator must also be ready.**

On both systems, install QEMU and make sure `qemu-system-x86_64` is on `PATH`. On Windows, enable **Windows Hypervisor Platform** and install Git Bash, MSYS2 or Cygwin for the launcher. On Linux, enable KVM and make sure the current user can access it. To preserve the launcher output instead of discarding it, start with a log file:

```powershell
oniro-app emulator start --log oniro-emulator.log
```

The [official Oniro setup guide](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/#downloading-the-emulator) lists the platform-specific emulator prerequisites.

### Why does the Oniro Emulator fail to open on macOS?

**The current graphical launcher is incompatible with the standard Homebrew QEMU build.**

The bundled `run.sh` selects the correct macOS accelerator, but it also hard-codes an SDL display. The [standard Homebrew QEMU formula](https://formulae.brew.sh/formula/qemu) is built without SDL, so graphical startup fails with an error such as:

```text
qemu-system-x86_64: Display 'sdl' is not available.
```

This affects the standalone script and the App Builder and IDE actions that call it. App Builder normally discards launcher output; use `oniro-app emulator start --log oniro-emulator.log` if you need to confirm the failure. For the hackathon, use DevEco Studio's emulator on a supported Apple Silicon Mac or connect a physical device; the DevEco Studio emulator is unavailable on Intel Macs. The launcher's `--headless` mode avoids the SDL window and exposes the display over VNC, but treat that as a manual workaround; Apple Silicon also uses slower TCG emulation. The current [`run.sh` implementation](https://github.com/eclipse-oniro4openharmony/device_board_oniro/blob/main/x86_general/kernel/run.sh) and the [Oniro setup guide](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/#downloading-the-emulator) show the relevant launcher and host details.

### Why doesn't `oniro-app cmdtools install` download the tools on Windows or macOS?

**Automatic command-line-tools downloads are available only on Linux.**

The public Huawei mirror does not provide Windows or macOS command-line tools for App Builder to download. Download the command-line-tools ZIP for your operating system from the [Huawei Developer downloads page](https://developer.huawei.com/consumer/en/download/), leave it as a ZIP, and pass its path explicitly:

```powershell
oniro-app cmdtools install --from-zip "C:\path\to\command-line-tools.zip"
oniro-app cmdtools status
```

In Oniro App IDE, open **SDK Manager**, click **Install** in the command-line-tools box, and select the same ZIP when prompted. The SDK is a separate download; do not pass an SDK archive to `cmdtools install`. See [Command-Line Tools on Windows and macOS](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/#command-line-tools-on-windows-and-macos).

### Why does my build still report missing command-line-tool directories after `cmdtools install` succeeded?

**A previous failed installation may have left a partial `command-line-tools` directory.**

If `oniro-app cmdtools install` runs out of space or otherwise fails while copying files, it does not roll back everything already written to the installation directory. A retry can then report success while the resulting tree is still incomplete. Rename the configured directory (by default `~/command-line-tools`) as a backup, free enough space for both the archive and extracted files, and install again into an empty destination. On Windows and macOS, use the manually downloaded archive:

```text
oniro-app cmdtools install --from-zip <path-to-command-line-tools-zip>
```

On Linux, rerun `oniro-app cmdtools install`. Then run `oniro-app cmdtools status` and try a clean build; the status command is only a basic check and may not detect every missing subdirectory. See the [command-line tools installation notes](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/blob/main/packages/cli/README.md#cmdtools--manage-the-openharmony-command-line-tools-provides-hvigorw-ohpm-hdc-codelinter) and the [open partial-install bug](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/issues/16).

### Why does the build report missing ArkTS properties or APIs inside a dependency?

**The SDK used for the build may be older than the APIs the dependency actually uses.**

This can look like `Property 'isCapsLockOn' does not exist on type 'KeyEvent'` or `Property 'getGlobalWindowMode' does not exist on type 'typeof window'`, with every location inside `oh_modules`. The compiler does not say that the real problem is the SDK: those examples occur when building against HarmonyOS 5.1/API 18 even though the dependency calls APIs introduced in API 19 and 20.

Check the SDK actually selected for the build and update it to one that contains the required APIs. For the Oniro Emulator workflow, the documented combination is OpenHarmony 6.1/API 23 (`oniro-app sdk install 6.1`). For a HarmonyOS project, install a sufficiently recent HarmonyOS command-line-tools archive; the reported example was fixed by HarmonyOS 6.1.1/API 24. Also keep the project's `compileSdkVersion` compatible with that installed SDK. See the [Oniro SDK setup guide](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/#downloading-the-sdk-and-command-line-tools) and the [open diagnostic issue](https://github.com/eclipse-oniro4openharmony/oniro-app-builder/issues/22).
