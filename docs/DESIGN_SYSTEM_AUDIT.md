# Carely Design-System Audit

This records the 2026-10-03 design pass. Later UI changes are noted below;
the original validation describes that session, not the final app's full coverage.

## Direction

The phone and guardian app follows the supplied references: warm off-white page
background (`#FAF8F3`), white cards, dark green-black text (`#18312E`), and deep
teal (`#155E5A`) for primary actions and selection. Danger, success and warning
colors are reserved for those meanings, and are accompanied by plain-language
labels or symbols. The watch uses the same semantic palette on a dark surface.

## Audit coverage and changes

| Area | Screens/components reviewed | Consistency and accessibility treatment |
| --- | --- | --- |
| Primary, secondary and destructive actions | Setup/pairing, SOS, Safe Area, Settings, medication forms and actions, contacts, location, alerts, model controls, map controls, watch pairing | Shared `CareButtonStyle`: capsule shape, minimum 56 vp height, consistent type and clear primary/secondary/danger treatments; explicit loading text and disabled state. Essential round-watch SOS remains a large circular target. |
| Text inputs and validation | Connection, guardian contact and medication editors, Safe Area coordinates and dose time | Shared 56 vp input style, explicit labels, visible borders, focus outline and inline validation descriptions. Multi-line instructions receive a matching surface and focus treatment. |
| Toggle and checkbox | Developer Mode switch; medicine-name/package confirmation checkbox | Larger control hit areas and accessible descriptions; checkbox row delegates state/action to the actual native checkbox. The setting describes its on/off result in adjacent text. |
| Navigation and row actions | Senior and guardian home lists, four-destination bottom navigation, guardian alerts/medications/contacts | Large row hit targets, spoken action summaries and visible selected tab treatment; icons are paired with text. There is no sidebar in the current phone application. |
| Map controls | Guardian location and Safe Area map picker | Zoom actions include visible “Zoom in”/“Zoom out” labels; safe-area circles use the shared semantic palette; map credit retained. |
| Status and feedback | SOS, alerts, backend loading/error/empty states, watch pairing and device status, simulations | Replaced ambiguous success claims with explicit local/remote scope; errors retain existing data where possible; unavailable and simulated states have explanatory copy. |
| Wearable controls | Pair keypad, SOS, heart rate and location/status views | Increased keypad/action targets and supporting text within round-screen constraints; SOS delivery copy distinguishes care-service acceptance from guardian acknowledgement. |

## Color/contrast verification

`python3 scripts/check-design-contrast.py` computes WCAG relative luminance and
checks the configured phone text, action, border, focus, and watch text pairs.
The checked text pairs meet 4.5:1 and control/focus boundaries meet 3:1. The
phone palette is checked in both light and dark resources. This is a token-level
check, not a blanket WCAG 2.0 conformance claim: system-rendered controls,
transparency/compositing, text scaling, screen-reader traversal, and real device
touch behavior still require manual evaluation.

## Interaction inventory and follow-up

- The senior home has SOS and grouped safety/setup rows; senior tabs are Home,
  Medication, Contacts and Wellbeing. Guardian tabs are Home, Alerts, Location,
  Medication and Contacts, with further setup and watch detail screens reachable
  from their corresponding areas.
- Settings contains one session-only Developer Mode switch. Medication setup has
  a package-confirmation checkbox and selectable dose-time chips. Safe Area
  radius choices are exclusive buttons with a visible check on the current value.
- Guardian alerts use pull-to-refresh; the separate Refresh button was removed
  in the 2026-10-04 UI update. Retry remains available on load failure. Automatic checks
  happen while the app is open; live remote push remains unverified.
- Successful connection/pairing navigates directly to the appropriate role home.
  Senior pairing credentials remain available later under Settings.
- No web-style sidebar, general-purpose checkbox inventory, or desktop shell
  exists in this phone/watch application; native tab and grouped row patterns are
  the corresponding navigation surfaces.

## Validation

Later API 24 E2E/fix checks exercised populated medication/contact screens and
the static medicine fallback, as recorded in the AI work log. The manual
observations below are preserved as the scope of the original design audit.

- `./scripts/build-hap.sh` builds the phone and watch HAPs.
- `python3 scripts/check-design-contrast.py` validates semantic palette pairs.
- `git diff --check` validates patch whitespace.
- Manual emulator review was performed for the phone home, selected bottom tab,
  guardian Alerts with populated SOS/safe-area events, and a medication backend
  error state. The alert refresh action is visible; the test swipe did not produce
  a distinguishable post-refresh screenshot, so pull gesture callback observation
  is not claimed. The medication endpoint returned a server error during review,
  so its loaded list and dose controls could not be visually exercised in that
  session. Accessibility inspector, screen-reader, high text scale, and watch
  physical-device testing remain outstanding.
