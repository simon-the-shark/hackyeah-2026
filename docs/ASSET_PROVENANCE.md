# Asset Provenance

Inventory reconciled on 2026-10-04. Source evidence is in the dated
[`AI work log`](AI_WORK_LOG.md); an asset being supplied to the team does not by
itself establish its redistribution license.

| Asset/resource | Recorded origin/use | Permission or attribution status |
| --- | --- | --- |
| `entry/src/main/resources/rawfile/models/medicine_3d.glb` | User-supplied model; generic demo bottle, reused for all medicines | made by teammember with ai assitance |
| `entry/src/main/resources/base/media/medicine_bottle_preview.png` | Static medicine reference used when the 3D engine fails | generated from the model above using script |
| Carely launcher foreground/background/start icons under `AppScope`, `entry` and `watch` resources | mabe by teammate | Synthetic demo catalog in the backend | Not a medical product database; barcode candidates do not establish a prescription |
| Map tiles | Public OpenStreetMap tiles; app displays “© OpenStreetMap contributors” | Retain attribution and follow the public tile service policy; tiles are fetched, not bundled as a licensed offline dataset |
| `docs/challenge/`, `hackathon-resources/`, `hackathon-skills/` | Organizer reference material/skills copied from the HackYeah challenge repository | Preserve upstream attribution; confirm upstream redistribution terms rather than treating them as team-authored assets |
| SDK system symbols | HarmonyOS SDK symbols referenced by resource name | Platform resources, not original Carely artwork |

Upstream challenge source:
<https://github.com/onirodeveloper/hackyeah2026-challenge>.
Map attribution: <https://www.openstreetmap.org/copyright>.
Tile service policy: <https://operations.osmfoundation.org/policies/tiles/>.
