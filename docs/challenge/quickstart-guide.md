# Hackathon OpenHarmony Quickstart Guide

## Overview

There are two available tools for developing OpenHarmony apps in the ArkTS language (alternatively, you can develop a cross-platform application using React Native):

|                   | DevEco Studio (IDE)                           | Oniro App Builder (CLI) / Oniro IDE (VS Code extension) |
|-------------------|-----------------------------------------------|---------------------------------------------------------|
| Operating System  | Windows 10/11 64-bit or macOS 12/13/14 (Arm) | Windows or Linux                                 |
| Emulator          | DevEco Studio Emulator                        | Oniro Emulator (QEMU-based)                              |
| Maturity          | Mature tool maintained by Huawei               | Still in development — you might encounter some bugs.   |

See the [emulator capability comparison](README.md#emulator-capability-comparison) for a detailed breakdown of what each emulator can and cannot simulate.

## DevEco Studio

This walks through installing DevEco Studio on Windows and macOS, then running an OpenHarmony app with it and testing it on an emulator. It follows the [Oniro Environment Setup Guide](https://docs.oniroproject.org/application-development/environment-setup-guide/); the one addition here is a configuration-file tweak that guide doesn't cover but is needed for emulation to work.

> ℹ️ **CodeGenie is not necessary.** CodeGenie is the AI agent built into DevEco Studio. You do not need to set it up or use it for this hackathon; you can work with any external coding agent instead (see the [README](README.md#2-set-up-the-agent-tooling)).

### Windows

1. **First launch & SDK setup** — see the [installation guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/installation/).
2. **Switch the DevEco Studio region to China in the configuration file** — not covered in the official docs, but required to emulate anything other than a smart watch (and to avoid region-restricted emulator downloads). If you use the agent setup prompt ([INSTALLATION_PROMPT.md](INSTALLATION_PROMPT.md)), it does this for you and you can skip the rest of this step. Otherwise:
   - In `%AppData%/Huawei/DevEcoStudio<version>/options`, open `country.region.xml` and set `countryregion name` to `CN`.

   > ⚠️ **Use exactly this path.** Edit the `country.region.xml` in the `options` folder of your installed DevEco Studio version (`DevEcoStudio<version>`), with DevEco Studio closed, then restart it. Do **not** use `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Huawei`.

   <img src="_deveco_screenshots/windows_path.png" alt="File Explorer address bar showing the DevEco Studio options folder path" style="max-width:850px;">
   <img src="_deveco_screenshots/windows_conf_file.png" alt="country.region.xml opened in an editor with the countryregion name set to CN" style="max-width:850px;">
3. **Run an application** — create a new project (**Create Project > Empty Ability**, or follow [Create Your First App](https://docs.oniroproject.org/application-development/create-your-first-app/) for a full walkthrough). Use the [Previewer](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/previewer/) for a quick check. If you want to test more deeply, use the emulator (see below).

### macOS

1. **First launch & SDK setup** — see the [installation guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/installation/).
2. **Switch the DevEco Studio region to China in the configuration file** — not covered in the official docs, but required to emulate anything other than a smart watch (and to avoid region-restricted emulator downloads):
   - In `~/Library/Application Support/Huawei/DevEcoStudio<version>/options`, open `country.region.xml` and set `countryregion name` to `CN`.

   > ⚠️ **Use exactly this path.** Edit the `country.region.xml` in the `options` folder of your installed DevEco Studio version (`DevEcoStudio<version>`), with DevEco Studio closed, then restart it.

   <img src="_deveco_screenshots/macos_command.png" alt="Command that you can use to modify `country.region.xml` file" style="max-width:1000px;">
3. **Run an application** — create a new project (**Create Project > Empty Ability**, or follow [Create Your First App](https://docs.oniroproject.org/application-development/create-your-first-app/) for a full walkthrough). Use the [Previewer](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/previewer/) for a quick check. If you want to test more deeply, use the emulator (see below).

### DevEco Studio Emulator

See the [Emulator guide](https://docs.oniroproject.org/application-development/environment-setup-guide/deveco-studio/emulator/) for setting up and running your app on a virtual device, and the [emulator capability comparison](README.md#emulator-capability-comparison) for what it can and cannot simulate.

## Oniro App Builder & Oniro IDE

**Oniro App Builder** is a command-line tool that provides all the necessary tools for developing an OpenHarmony app:

- initializing a project
- signing and building the app
- testing it on an emulator

**Oniro IDE** is a Visual Studio Code extension based on the Oniro App Builder. It provides mostly the same utilities as Oniro App Builder.

Follow [this tutorial](https://docs.oniroproject.org/application-development/environment-setup-guide/oniro/setup/) to install Oniro App Builder or Oniro IDE and learn how to use them.

## ArkTS App Development Tutorials

- [Create your first app in ArkTS](https://docs.oniroproject.org/application-development/create-your-first-app/)
- [More tutorials](https://docs.oniroproject.org/application-development/basic-concepts/)
- [Code labs](https://docs.oniroproject.org/application-development/codeLabs/) — example apps with explained implementation details

## Resources

- [Official Oniro github page](https://github.com/eclipse-oniro4openharmony)

- [OpenHarmony Documentation](https://github.com/openharmony/docs)
- [Oniro Documentation](https://docs.oniroproject.org/)
- [HarmonyOS Development Documentation](https://developer.huawei.com/consumer/en/harmonyos/develop/)
- [HarmonyOS Release Notes](https://developer.huawei.com/consumer/en/doc/harmonyos-releases/overview-allversion)

- [Oniro Agent Skills](https://github.com/eclipse-oniro4openharmony/agent-skills) — skills for AI agents working on ArkTS apps.

## React Native for OpenHarmony

- [React Native for OpenHarmony](https://gitcode.com/CPF-RN/ohos_react_native/tree/0.77-main/docs/en) — English documentation
- [React Native for OpenHarmony tutorial](https://docs.oniroproject.org/application-development/codeLabs/cross-platform/rn-example/)
