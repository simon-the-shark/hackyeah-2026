# AI Workflow

This project uses AI-assisted development. Keep this document current and
public-safe. Do not include credentials, tokens, personal data, private
endpoints, or confidential prompts. The full dated log of every AI-assisted
change, with its validation, is in [`docs/AI_WORK_LOG.md`](docs/AI_WORK_LOG.md).

## Summary

- Coding agents wrote most of the code and documentation, steered by a human
  team that made the product decisions and reviewed and merged each change.
- [`AGENTS.md`](AGENTS.md) holds the standing instructions every agent follows:
  fixed HarmonyOS/ArkTS stack, verify platform APIs against official docs and
  the installed SDK, never claim unverified build or device results, label
  simulations, keep the repository public-safe.
- Plans came first: [`HACKATHON_BRIEF.md`](archive/HACKATHON_BRIEF.md),
  [`MOBILE_PLAN.md`](archive/MOBILE_PLAN.md) and [`backend/PLAN.md`](backend/PLAN.md).
  Agents then implemented the app and the backend in parallel workstreams.
- Validation used `./scripts/build-hap.sh`, ArkTS (hypium) and backend (vitest)
  tests, and selected UI flows on the DevEco HarmonyOS emulator through `hdc`
  and `uitest`. Not every change received every check; the dated work log
  records actual results, blocked checks and remaining runtime gaps.
- Pull requests were additionally reviewed by Prelint (AI code and product
  review) before a human merged them.

## Tools Used

| Tool | Model or source | Role in the project |
| --- | --- | --- |
| Claude Code | Claude Opus 5.5, Claude Sonnet 5.5 (incl. forked subagents) | Backend, wellbeing voice check-in, navigation, end-to-end emulator testing and fixes, documentation |
| Cursor Agent | Claude Opus 5.5, Composer 2.5, Grok 4.7 | Navigation baseline, SOS UX, pairing-aware navigation, senior wellbeing screen |
| OpenCode | `openai/gpt-5.6-terra`, `gpt-6-astra`, `gpt-6.1-sol`, `gpt-6-luna` | Project setup, planning, deployment fix, 3D medication viewer, accessibility/design-system audit, challenge documentation review and corrections |
| Prelint | GitHub app (prelint.com) | Automated AI code and product-decision review on pull requests |
| Context7 MCP | Context7 | Current HarmonyOS and third-party library documentation |
| TypeUI MCP | Hosted MCP | Design-system guidance during the consistency audit |
| context7-mcp Agent Skill | Local skill | pnpm configuration documentation for the deployment fix; HarmonyOS tooling documentation during submission-doc corrections |
| `hmos-arkui-develop-skill` Agent Skill | Local `hackathon-skills/` | ArkUI coding rules |


## Workflow

### Context For The Agents

- Every agent reads `AGENTS.md` (stack, verification and honesty rules) and
  `AI_WORKFLOW.md` before starting.
- **MCP servers bring current documentation into the agent's context**, so
  agents do not rely on outdated training data for a fast-moving platform:
  - Context7 MCP serves the official HarmonyOS guides and API references
    (library IDs listed in `AGENTS.md`). Agents used it, for example, for
    continuous tasks and location permissions, notification slots, safe areas,
    the `Refresh` component, ArkGraphics 3D, Map Kit and Pasteboard Kit, and
    for the current pnpm configuration docs.
  - TypeUI MCP gave design-system guidance during the accessibility audit.
- The challenge's HarmonyOS Agent Skills (`hackathon-skills/`) add ArkUI
  coding rules.
- Agents also checked every platform API against the installed SDK
  declarations (API level, permissions, Public SDK), and the OpenAI
  integration against OpenAI's official docs and pricing pages.

### Planning

1. The team described the product and the constraints in prompts.
2. Agents drafted `archive/HACKATHON_BRIEF.md`, `archive/MOBILE_PLAN.md` and `backend/PLAN.md`,
   including feasibility checks for each platform capability.
3. The team made the product decisions, recorded as dated user decisions in the
   brief (for example, moving the wellbeing assistant from on-device AI to the
   OpenAI Realtime model).

### Implementation, Testing And Lint

1. Agents wrote the app and the backend in parallel workstreams, sometimes as
   forked subagents working to a fixed API contract.
2. Depending on the change and available environment, agents used:
   - the phone and watch HAP build (`./scripts/build-hap.sh`) and review of
     ArkTS static-check warnings;
   - the ArkTS unit tests (`hvigorw test`);
   - backend `pnpm typecheck` and `pnpm test` (PostgreSQL, with fake push and
     OpenAI providers);
   - `git diff --check`.
3. The agent recorded what was and was not verified in the work log.
4. **Prelint (AI review):** changes went to a pull request, where the
   Prelint GitHub app ran two checks: code findings as inline comments, and a
   product-decision review with a verdict such as "Ship with changes". The
   agent checked each finding against the code, fixed the valid ones and
   re-ran the tests. Findings and outcomes are listed at the end of
   `docs/AI_WORK_LOG.md`.

### Final Verification

1. **End-to-end testing on the emulator:** Claude Code drove the app on the
   DevEco HarmonyOS API 24 phone emulator through `hdc` and `uitest`:
   - installed the unsigned HAP and set up synthetic test accounts;
   - walked the senior and guardian flows (pairing, SOS, medication, contacts,
      safe area and wellbeing availability), acting as the second role through
      the backend API; this did not verify a full spoken AI check-in;
   - used screenshots and UI layout dumps to check each screen;
   - reported findings first; after the team approved them, fixed each one
     and re-tested it on the emulator. It found 8 defects, for example a
     cancelled SOS still shown as New and a disabled Location switch with no
     recovery path.
2. **Human merge:** a team member merged every pull request.

## Known Limitations

- Detailed end-to-end checks and fix re-tests are recorded on the HarmonyOS
  API 24 phone emulator (unsigned installs). API 23 installation and selected UI
  checks are recorded separately. The team reports verification on two real
  phones, but device models, OS versions and a per-flow physical-device record
  are not yet documented. Not run on a real watch (see below).
- Guardian alerts arrive by foreground polling (about every 20 s) plus local
  notifications. The backend's Push Kit sender is implemented but unverified:
  Push Kit needs an AppGallery Connect project, which requires a verified
  Huawei developer account (identity verification with a passport). Without
  it, nothing is notified while the guardian app is closed.
- The watch app was installed and launched on an API 23 wearable emulator. We
  tried to connect a real hardware watch but did not succeed, so the watch app
  has run only on the emulator. Its heart rate and location run only while it
  is open; emulator readings are labelled SIMULATED. Successful watch pairing,
  sensor ingestion and SOS are not established by the recorded launch.
- Maps use public OpenStreetMap tiles. Map Kit needs the same AppGallery Connect
  setup as Push Kit, and with it a verified Huawei developer account (passport).
- Backend pairing and demo bootstrap are unauthenticated with in-memory rate
  limits; they are meant for the hackathon demo only.

## AI Feature Disclosure

### Wellbeing check-in

- Once a day the senior can have a short voice chat with the app about how
  they feel: mood, sleep, pain, worries. Afterwards the guardian gets a short
  summary. It is not a medical tool.
- The phone sends the senior's voice to our backend, which talks to OpenAI and
  sends the reply back. The conversation runs on `gpt-realtime-2.1-mini`; when
  it ends, `gpt-6-luna` writes the summary and the guardian is notified.
- The OpenAI key never leaves the server.
- We don't keep the audio, and the transcript is deleted as soon as the
  summary is written.
- Only the guardian reads the summary, and notifications never include it.
- The app asks for microphone access, but there is no separate consent screen
  for sending the conversation to OpenAI.
- If OpenAI stops responding, the conversation pauses and the senior can tap
  "Continue talking" to pick it up again.
- The SOS button works without the AI. If the senior mentions something that
  sounds like an emergency, the assistant asks them to press SOS or call 112,
  the app shows a large SOS button, and the guardian gets a notice. The AI never
  sends an SOS on its own.
- The assistant is told not to give medical advice, but its replies and
  summaries can still be wrong or miss things, so every summary is marked as
  AI-written.