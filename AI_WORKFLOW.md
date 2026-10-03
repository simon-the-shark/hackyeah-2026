# AI Workflow

This project uses AI-assisted development. Keep this document current and
public-safe. Do not include credentials, tokens, personal data, private
endpoints, or confidential prompts.

## Tools Used

| Model, agent, MCP server, or Agent Skill | Version or source | Role in the project |
| --- | --- | --- |
| OpenCode | `openai/gpt-5.6-terra` | Repository setup, implementation, and validation assistance |
| Context7 MCP | Context7 | Current third-party library documentation when required |

## Important Prompts And Instructions

- `AGENTS.md` defines the repository's platform, validation, and hackathon constraints.
- The HackYeah 2026 challenge statement defines the public submission requirements.

## AI-Assisted Work Log

| Date | Tool/model | Request or task | Generated or changed | Human review and validation |
| --- | --- | --- | --- | --- |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Align project with the HackYeah challenge starter and requirements | Challenge documentation, resource references, skills archive, SDK policy, and starter screen | Build verification pending |
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Configure DevEco environment and build across several sessions | Located DevEco's bundled hvigor and SDK root, resolved SDK sync configuration, added the macOS build wrapper, and assessed API 23 installation | `assembleHap` completed successfully with API 24; API 23 is being installed through DevEco Studio. Signing, emulator installation, and launch remain unverified. |

## Workflow

### Ideation And Architecture

The product concept has not been selected.

### Implementation

AI-assisted changes are reviewed against the challenge statement and existing
ArkTS project configuration before acceptance.

### Testing And Debugging

Record builds, linting, tests, emulator runs, logs, screenshots, and manual
checks here as they are completed.

## Unsuccessful Approaches

- None recorded.

## Known Limitations

- The starter contains no product functionality beyond the generated screen.
- The `.hap` is unsigned because no signing profile is configured. Emulator
  installation and launch remain unverified.
- API 23 cannot be selected until its SDK components are downloaded in DevEco
  Studio; the project currently compiles with the installed API 24 SDK.

## Lessons Learned

- None recorded.

## AI Feature Disclosure

Not applicable until AI becomes part of the product itself.
