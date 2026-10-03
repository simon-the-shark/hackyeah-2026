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
| 2026-10-03 | OpenCode / `openai/gpt-5.6-terra` | Verify build tooling | Attempted the project build and checked for DevEco CLI | `npx hvigor` cannot resolve an OpenHarmony build tool from npm; `devecocli` is not installed |

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
- This environment does not have DevEco's `hvigor` wrapper or `devecocli`, so a
  native build and emulator run remain unverified.

## Lessons Learned

- None recorded.

## AI Feature Disclosure

Not applicable until AI becomes part of the product itself.
