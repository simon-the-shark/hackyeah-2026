# Carely: an elderly-care companion for HarmonyOS

Carely helps an older person stay independent. They can ask for help (SOS) from
their phone or watch, stay within a safe area, take their medication on time and
call trusted people with one tap. A guardian is alerted and gets a daily
AI-written wellbeing summary from a hands-free spoken check-in.

- **Theme:** Human-Centric Technology, supported by Intelligent Experiences
  (voice check-in through the OpenAI Realtime model)
- **Demo video:** TODO link
- **Ready-built `.hap` files (phone and watch):** TODO Google Drive link
- **Stack:** ArkTS, ArkUI, Stage model; compile SDK `6.1.1(24)`, target SDK
  `6.1.0(23)`, compatible
  with API 20; Hono + PostgreSQL backend in [`backend/`](backend/)

## Quickstart

**Prerequisites:** macOS with DevEco Studio 6.1.1 (bundled HarmonyOS SDK
`6.1.1(24)`), and a phone emulator created in DevEco Studio's Device Manager
(we test on HarmonyOS 6.1.0(23)). The app uses the hosted backend, which stays up
during judging, so no backend setup is needed.

1. **Build** both HAPs (phone and watch):

   ```zsh
   ./scripts/build-hap.sh   # set DEVECO_STUDIO_HOME if DevEco Studio is not in /Applications
   ```

   Output: `entry/build/default/outputs/default/entry-default-unsigned.hap`
   (phone) and `watch/build/default/outputs/default/watch-default-unsigned.hap`
   (watch).

2. **Install** on the running emulator. The emulator accepts the unsigned HAP,
   as DevEco Studio's Run does. `hdc` ships with DevEco Studio in
   `Contents/sdk/default/openharmony/toolchains/`; add it to your `PATH`.

   ```zsh
   hdc shell mkdir -p data/local/tmp/carely
   hdc file send entry/build/default/outputs/default/entry-default-unsigned.hap data/local/tmp/carely/
   hdc shell bm install -p data/local/tmp/carely
   ```

   Or open the project in DevEco Studio and Run the `entry` module. A physical
   device needs the HAP signed with your own DevEco debug signature (File →
   Project Structure → Signing Configs); no signing material is committed.

3. **Launch:**

   ```zsh
   hdc shell aa start -a EntryAbility -b pl.solvro.hackyeah26
   ```

**Optional watch:** create a wearable emulator (we use HarmonyOS 6.1.0(23)). If
a phone emulator already uses hdc port 5555, start the watch on another port
with `Emulator -start <name> -hdcPort 5557` (`Emulator` is in DevEco Studio's
`Contents/tools/emulator/`). Install
`watch-default-unsigned.hap` the same way (pick the device with `hdc -t <serial>`),
then launch with `hdc shell aa start -a WatchAbility -b pl.solvro.hackyeah26 -m watch`.

## Demo Path

Use two phone emulators, or set up one role, sign out, then the other.

1. **Senior phone:** I am a senior → enter a name → Set up senior phone. Then
   Settings → copy the Guardian pairing code.
2. **Guardian phone:** I am a guardian → enter a name and the code → Pair with
   senior.
3. **Guardian:** set the Safe Area. **Senior:** Safe Area → Turn on sharing; move
   the position outside the area in the emulator's GPS panel. The guardian's
   Alerts tab shows the safe-area exit.
4. **Senior:** SOS → after the 3-second countdown the guardian sees the SOS with
   its location and can call the senior.
5. **Senior:** Medication → mark a dose Taken. **Wellbeing:** Talk with Carely,
   then Finish. The guardian reads the summary under Insights → Wellbeing
   Reports.
6. **Optional watch:** senior Settings → Smartwatch → Pair a watch, enter the
   code on the watch, then set a heart rate in the emulator's Virtual Sensor
   panel. The guardian sees it under Watch & vitals.

## What Is Real vs Simulated

The phone app was verified on the emulator and on two real phones; the watch
app only on the emulator.

| Feature | On the emulator |
| --- | --- |
| Pairing, SOS, safe-area alerts, medication, contacts, calling | Real app and backend; location comes from the emulator's GPS panel |
| Watch heart rate and location | Emulator sensor values, labelled **SIMULATED** in the app |
| Wellbeing voice check-in | Real OpenAI Realtime model through the backend; a full spoken conversation on the emulator is not yet verified |
| Guardian notifications | Foreground polling plus local notifications; Push Kit delivery is implemented in the backend but unverified (needs a verified Huawei developer account) |
| Barcode scan, 3D medicine model | Scan Kit and ArkGraphics 3D unverified on the emulator; a labelled simulated scan and a still render are shown |

Full list: [Known limitations](AI_WORKFLOW.md#known-limitations).

## Tests

```zsh
# ArkTS unit tests (66 tests)
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test -p module=entry@default -p product=default

# Backend integration tests (needs Docker for PostgreSQL)
cd backend && docker compose up -d && pnpm install && pnpm test
```

To run the backend locally instead of the hosted one, see
[`backend/README.md`](backend/README.md#setup) and change `BACKEND_BASE_URL` in
`entry/src/main/ets/providers/backend/BackendUrl.ets` and
`watch/src/main/ets/services/BackendUrl.ets`.

## Docs

- [`ARCHITECTURE.md`](ARCHITECTURE.md): components, platform capabilities used, key flows, failure handling
- [`AI_WORKFLOW.md`](AI_WORKFLOW.md): AI tools, workflow, limitations, AI feature disclosure ([full work log](docs/AI_WORK_LOG.md))
- [`backend/README.md`](backend/README.md): backend setup and API contract
- [`docs/BACKGROUND_LOCATION.md`](docs/BACKGROUND_LOCATION.md): background location behavior
- [`HACKATHON_BRIEF.md`](HACKATHON_BRIEF.md), [`MOBILE_PLAN.md`](MOBILE_PLAN.md): product scope and the original plan
