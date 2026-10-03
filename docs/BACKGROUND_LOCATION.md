# Phone background location

## Behavior

The paired senior enables **Safe Area → Turn on sharing**, grants precise
location and enables notifications. Carely starts a HarmonyOS `LOCATION`
continuous task with a system notification that opens the app. The established
subscription is kept when the ability backgrounds. Switching pages does not
affect it. The watch continues to use its existing foreground-only monitoring.

- LocationKit is asked for a fix every 30 seconds, with no movement filter so
  stationary phones can supply new fixes. This is a requested cadence, not a
  delivery guarantee. Battery consumption needs physical-device measurement.
- A single reporting lane attempts a heartbeat every 30 seconds; slow requests
  do not overlap. A fix retains its original device `sampledAt`. After 2 minutes
  without a fresh fix, check-ins report `unavailable` and omit location. The
  guardian's device card distinguishes check-in time from position time.
- Safe-area configuration loads before evaluation and refreshes every minute
  while sharing. A cached boundary is used offline with a visible notice. A
  missing boundary means unknown, never the old hardcoded home coordinates.
- Two distinct clear fixes at least 10 seconds apart confirm an exit or entry.
  The accuracy circle must clear the boundary plus a small margin (up to 15 m).
  A gap over 2 minutes resets an unconfirmed candidate. Uncertain fixes do not
  replace the last confirmed side or generate another exit.
- Both `area_exit` and `area_enter` are saved before delivery. A serialized,
  senior-scoped outbox preserves order and event IDs. Delivery stops at the first
  failure and retries while sharing or when the Safe Area page is opened.
  Storage failures retain new transitions in memory and show a warning; those
  unsaved events cannot survive process termination. Legacy queue entries without
  a senior ID are discarded rather than attributed to a different pairing.
- Sharing preference and the last valid boundary survive relaunch for the same
  senior. Restart requires opening the app; there is no boot receiver or promise
  of recovery after force-stop. The detector establishes a fresh baseline after
  restart; being confirmed outside then can produce a new exit event.
- Explicit stop, sign-out, system task cancellation, revoked location access,
  disabled location, and rejected backend authorization stop monitoring. Access
  and the location switch are checked on each reporting tick. System cancellation
  requires the user to turn sharing on again; it is not silently overridden.

Guardian remote push registration/delivery is a separate integration. The
current guardian-side polling still runs only in the foreground; successful
senior background reporting alone does not guarantee a background guardian
notification. No backend contract changes are required for this implementation.

## Platform contract

Public SDK APIs, within compatible API 20:

- `backgroundTaskManager.startBackgroundRunning(context, BackgroundMode.LOCATION,
  wantAgent)` and `stopBackgroundRunning(context)` (API 9).
- `on/off('continuousTaskCancel')` (API 15).
- Manifest: `ohos.permission.KEEP_BACKGROUND_RUNNING` and the ability's
  `backgroundModes: ["location"]`.
- Foreground precise/approximate location grants. Huawei documents that a
  `LOCATION` continuous task with foreground location consent can obtain location
  in the background without `LOCATION_IN_BACKGROUND`.

References consulted alongside the installed HarmonyOS SDK declarations:

- [Continuous tasks](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/continuous-task)
- [User-granted permissions: LOCATION_IN_BACKGROUND](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/permissions-for-all-user)
- [Location permission guidance](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/location-permission-guidelines)
