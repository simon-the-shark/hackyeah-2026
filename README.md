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

**Prerequisites:** DevEco Studio 6.1.1, including the bundled HarmonyOS SDK
`6.1.1(24)`. 

1. **Clone and sync:**

   ```zsh
   git clone https://github.com/simon-the-shark/hackyeah-2026.git
   cd hackyeah-2026
   ```

   Open this directory (the one containing `build-profile.json5`) in DevEco
   Studio. Allow project sync and OHPM dependency installation to finish. Keep
   the committed lockfiles. Confirm the HarmonyOS SDK `6.1.1(24)` is installed;
   the root product uses `runtimeOS: "HarmonyOS"`, target `6.1.0(23)` and
   compatible `6.0.0(20)`.

2. **Create and start a target:** in DevEco Studio's Device Manager, create a
   phone virtual device, download its API 23 or API 24 system image, then start
   it and wait for the home screen. Image downloads can be several gigabytes.
   Creating a device does not download or start it automatically. Set its time
   zone to **Europe/Warsaw** for the medication demo.

   If phone images are missing, follow the
   organizer's [manual China-region setup](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/FAQ.md#how-do-i-switch-the-deveco-studio-region-to-china-manually).
   If no target appears, follow [No devices show up](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/FAQ.md#no-devices-show-up-when-i-try-to-run-the-app-on-an-emulator-what-now).

3. **Build** both HAPs: in DevEco Studio, build the `entry` and `watch` modules
   for the `default` product. The repository also includes a zsh build helper
   for the bundled toolchain:

   ```zsh
    ./scripts/build-hap.sh
   ```

   Output: `entry/build/default/outputs/default/entry-default-unsigned.hap`
   (phone) and `watch/build/default/outputs/default/watch-default-unsigned.hap`
   (watch).

4. **Select and install** on the running emulator.

   ```zsh
    hdc list targets -v
    export PHONE_TARGET='<phone connect key from the list>'
    hdc -t "$PHONE_TARGET" file send entry/build/default/outputs/default/entry-default-unsigned.hap /data/local/tmp/carely-phone.hap
    hdc -t "$PHONE_TARGET" shell bm install -p /data/local/tmp/carely-phone.hap
   ```

   Or open the project in DevEco Studio and Run the `entry` module. A physical
   device needs the HAP signed with your own DevEco debug signature (File →
   Project Structure → Signing Configs); no signing material is committed.

5. **Launch:**

   ```zsh
    hdc -t "$PHONE_TARGET" shell aa start -a EntryAbility -b pl.solvro.hackyeah26 -m entry
   ```


**Optional watch:** create, download and start a wearable emulator (the recorded
watch launch used API 23), then select its own connect key:

```zsh
hdc list targets -v
export WATCH_TARGET='<watch connect key from the list>'
hdc -t "$WATCH_TARGET" file send watch/build/default/outputs/default/watch-default-unsigned.hap /data/local/tmp/carely-watch.hap
hdc -t "$WATCH_TARGET" shell bm install -p /data/local/tmp/carely-watch.hap
hdc -t "$WATCH_TARGET" shell aa start -a WatchAbility -b pl.solvro.hackyeah26 -m watch
```

## Tests

```zsh
# ArkTS local unit tests (not a substitute for device checks)
hvigorw test -p module=entry@default -p product=default

# Backend integration tests (needs Docker for PostgreSQL)
cd backend
docker compose up -d
pnpm install --frozen-lockfile
pnpm typecheck
pnpm test
```

Run the ArkTS command with DevEco's `hvigorw` on `PATH` and `DEVECO_SDK_HOME`
set to the installed SDK root.

The backend requires Node 22+ (developed on 23.11), pnpm **11.7.0**, and Docker
with Compose/PostgreSQL 17. Follow [local backend setup](backend/README.md#setup)
for migration and emulator port-forwarding instructions, including both client
URL changes. No OpenAI or Push Kit credentials are needed for the core local
demo; without an OpenAI key the wellbeing assistant is unavailable.

## Docs

- [`ARCHITECTURE.md`](ARCHITECTURE.md): components, platform capabilities used, key flows, failure handling
- [`AI_WORKFLOW.md`](AI_WORKFLOW.md): AI tools, workflow, limitations, AI feature disclosure ([full work log](docs/AI_WORK_LOG.md))
- [`backend/README.md`](backend/README.md): backend setup and API contract
- [`docs/BACKGROUND_LOCATION.md`](docs/BACKGROUND_LOCATION.md): background location behavior
- [`HACKATHON_BRIEF.md`](archive/HACKATHON_BRIEF.md), [`MOBILE_PLAN.md`](archive/MOBILE_PLAN.md): product scope and the original plan
- [`docs/ASSET_PROVENANCE.md`](docs/ASSET_PROVENANCE.md): asset sources and unresolved permissions
