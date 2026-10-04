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
- Plans came first: [`HACKATHON_BRIEF.md`](HACKATHON_BRIEF.md),
  [`MOBILE_PLAN.md`](MOBILE_PLAN.md) and [`backend/PLAN.md`](backend/PLAN.md).
  Agents then implemented the app and the backend in parallel workstreams.
- Each change was validated with `./scripts/build-hap.sh`, the ArkTS (hypium)
  and backend (vitest) tests, and, for UI flows, runs on the DevEco HarmonyOS
  emulator driven through `hdc` and `uitest`.
- Pull requests were additionally reviewed by Prelint (AI code and product
  review) before a human merged them.

## Tools Used

| Tool | Model or source | Role in the project |
| --- | --- | --- |
| Claude Code | Claude Opus 5.5, Claude Sonnet 5.5 (incl. forked subagents) | Backend, wellbeing voice check-in, navigation, end-to-end emulator testing and fixes, documentation |
| Cursor Agent | Claude Opus 5.5, Composer 2.5, Grok 4.7 | Navigation baseline, SOS UX, pairing-aware navigation, senior wellbeing screen |
| OpenCode | `openai/gpt-5.6-terra`, `gpt-6-astra`, `gpt-6.1-sol`, `gpt-6-luna` | Project setup, planning, deployment fix, 3D medication viewer, accessibility/design-system audit |
| Prelint | GitHub app (prelint.com) | Automated AI code and product-decision review on pull requests |
| Context7 MCP | Context7 | Current HarmonyOS and third-party library documentation |
| TypeUI MCP | Hosted MCP | Design-system guidance during the consistency audit |
| context7-mcp Agent Skill | Local skill | pnpm configuration documentation for the deployment fix |
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
2. Agents drafted `HACKATHON_BRIEF.md`, `MOBILE_PLAN.md` and `backend/PLAN.md`,
   including feasibility checks for each platform capability.
3. The team made the product decisions, recorded as dated user decisions in the
   brief (for example, moving the wellbeing assistant from on-device AI to the
   OpenAI Realtime model).

### Implementation, Testing And Lint

1. Agents wrote the app and the backend in parallel workstreams, sometimes as
   forked subagents working to a fixed API contract.
2. After each change the agent ran:
   - the phone and watch HAP build (`./scripts/build-hap.sh`), whose ArkTS
     static checks must pass with no new warnings;
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
   DevEco HarmonyOS phone emulator through `hdc` and `uitest`:
   - installed the unsigned HAP and set up synthetic test accounts;
   - walked the senior and guardian flows (pairing, SOS, medication, contacts,
     safe area, wellbeing), acting as the second role through the backend API;
   - used screenshots and UI layout dumps to check each screen;
   - reported findings first; after the team approved them, fixed each one
     and re-tested it on the emulator. It found 8 defects, for example a
     cancelled SOS still shown as New and a disabled Location switch with no
     recovery path.
2. **Human merge:** a team member merged every pull request.

## Known Limitations

- Tested end to end on the HarmonyOS API 23 phone emulator (unsigned installs)
  and verified on two real phones. Not run on a real watch (see below).
- Guardian alerts arrive by foreground polling (about every 20 s) plus local
  notifications. The backend's Push Kit sender is implemented but unverified:
  Push Kit needs an AppGallery Connect project, which requires a verified
  Huawei developer account (identity verification with a passport). Without
  it, nothing is notified while the guardian app is closed.
- The watch app was installed and launched on an API 23 wearable emulator. We
  tried to connect a real hardware watch but did not succeed, so the watch app
  has run only on the emulator. Its heart rate and location run only while it
  is open; emulator readings are labelled SIMULATED.
- Maps use public OpenStreetMap tiles. Map Kit needs the same AppGallery Connect
  setup as Push Kit, and with it a verified Huawei developer account (passport).
- Backend pairing and demo bootstrap are unauthenticated with in-memory rate
  limits; they are meant for the hackathon demo only.

## AI Feature Disclosure

### Wellbeing Check-in Chat (Implemented, Partly Verified)

- **Purpose:** A short daily check-in chat about mood, energy, sleep, pain and
  worries; when it ends, a summary goes to the guardian so they know how the
  senior feels. It supports wellbeing conversations; it is not a medical tool.
- **Model/service:** OpenAI API called only by the backend. The senior's
  conversation is spoken through the Realtime API (`OPENAI_REALTIME_MODEL`,
  default `gpt-realtime-2.1-mini`, voice `marin`, input transcription with
  `OPENAI_TRANSCRIBE_MODEL`). The guardian summary uses the Responses API with a
  strict JSON schema (`OPENAI_CHAT_MODEL`, default `gpt-6-luna`, reasoning
  medium). Text and push-to-talk endpoints remain in the backend but the app no
  longer uses them. The prompts are in `backend/src/assistant/prompts.ts`.
- **Inference flow:** The phone streams microphone PCM over a WebSocket to the
  backend → the backend relays it to the Realtime model, whose voice-activity
  detection ends each turn → spoken reply streamed back and played; both
  transcripts stored in the open session; tools signal a possible emergency or
  the end of the check-in. On finish (the model's goodbye, the Finish button, or
  20 minutes idle) the transcript is summarised into ratings, up to 5 concerns,
  an attention level and 2-4 sentences → report stored → push to guardians.
- **Data/privacy:** The API key stays on the server; audio passes through the
  backend to OpenAI and is not stored. The senior is told before
  starting that a summary goes to the guardian and that the guardian does not see
  the conversation. The transcript is deleted from the server once the summary
  exists; responses use `store: false`. Push notifications never contain the
  summary or health details. Only the guardian reads the summary; the senior
  sees a confirmation that it was sent. Account deletion removes sessions and reports.
- **Failure behavior:** Any OpenAI failure ends the voice connection with
  `assistant_unavailable`; the check-in stays open and Continue talking
  resumes it. A summary that
  cannot be written within 24 hours becomes a report marked "summary
  unavailable". Without a key the check-in shows as unavailable; there is no
  scripted fallback. SOS never depends on the assistant: on a possible
  emergency the assistant tells the senior to press SOS or call 112, the app
  shows a large SOS button, and the guardian gets one informational `wellbeing`
  alert; the AI never sends an SOS itself.
- **Limitations:** No diagnosis, medication advice or medication changes are
  allowed by the instructions, but generated replies and summaries can still be
  wrong or omit things; every summary is labelled as AI-written and not a
  medical assessment.
- **Evaluation:** Automated tests use a fake assistant (flow, limits, safety
  alert, finish, idle fallback) and a stubbed `fetch` for the OpenAI request and
  response handling, plus a fake Realtime socket for the relay. One real typed
  greeting (`gpt-6-luna`) and one real spoken greeting (`gpt-realtime-2.1`) were
  received. No systematic evaluation of factuality, missing topics, emergency wording or
  transcription of older voices has been run yet.
