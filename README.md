# pusher_sdk

Flutter client for [stats.pusher.tr](https://stats.pusher.tr).

Registers the install (device hello), keeps an optional FCM token on the device
row so the panel can target it, and posts notification receipts when a push
carries `data.nid` (delivered / opened).

Host app only supplies **project id** and **stats key**. Everything else
(device id, platform, OS/app version, signing, foreground listeners) stays
inside the SDK.

## Install

```yaml
dependencies:
  pusher_sdk:
    git:
      url: https://github.com/GeceGibi/pusher_sdk.git
```

Requires Firebase Messaging in the host app (`Firebase.initializeApp` before use).

## Keys

> Sign up at [pusher.tr](https://pusher.tr), create a project, then copy
> **project id** (`pid`) and generate the **Stats key** from the panel
> (project → Settings → Stats key). Both values come from the panel — they
> are not global env secrets.

| Arg | What |
| --- | --- |
| `projectId` | Project id (`pid`) from the panel |
| `statsKey` | Per-project stats key from the panel |
| `baseUrl` | Optional, default `https://stats.pusher.tr` |

## Quick start

```dart
import 'package:pusher_sdk/pusher_sdk.dart';

await PusherSdk.init(
  projectId: 'YOUR_PROJECT_ID',
  statsKey: 'YOUR_STATS_KEY',
);
```

`init` persists config (for the FCM background isolate), ensures a stable
install UUID (`pusher_sdk.device_id`), attaches foreground FCM listeners, and
posts device hello.

## Methods

### `init`

One-shot setup. Prefer calling this from your notification / Firebase service
after the app has initialized Firebase.

```dart
await PusherSdk.init(
  projectId: '6ac3654da423c64a0ecc7d48',
  statsKey: '…',
  // baseUrl: 'https://stats.pusher.tr',
);
```

### `onBackgroundMessage` (optional)

SDK does **not** register an FCM background handler. If you want delivered
receipts while the app is in background / terminated, call this from your own
handler:

```dart
@pragma('vm:entry-point')
Future<void> onBackgroundMessageHandler(RemoteMessage message) async {
  await PusherSdk.onBackgroundMessage(message);
}

// early in main / runner:
FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandler);
```

`PusherSdk.onBackgroundMessage` only reloads prefs and POSTs a receipt — it does
**not** need `Firebase.initializeApp()` in this handler. Add Firebase init only
if your own code in the same handler uses other Firebase APIs.

Posts **delivered** when `message.data['nid']` is set.

### `syncToken` (optional)

Upserts the FCM token on the stats device row (reuses hello). Use when the host
already owns token lifecycle, or on refresh, so the panel can push to this
device:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((token) {
  unawaited(PusherSdk.syncToken(token: token));
});

// or pull current token:
await PusherSdk.syncToken();
```

### `hello` / `attach` / `receipt`

Usually covered by `init`. Still public if you need them alone:

| Method | Role |
| --- | --- |
| `hello({token?})` | `POST /{pid}/hi` — device upsert |
| `attach()` | Foreground delivered + opened listeners |
| `receipt(nid:, status:)` | `POST /{pid}/n/{nid}` — `1` delivered, `2` opened |

```dart
await PusherSdk.hello();
await PusherSdk.receipt(nid: '…', status: PusherSdk.statusOpened);
```

### Readouts

```dart
PusherSdk.isInitialized; // bool
PusherSdk.deviceId;      // String? stable install UUID
```

## Receipts from FCM

Push payload must include notification id in data:

```json
{ "nid": "…" }
```

| App state | How |
| --- | --- |
| Foreground | `attach` → `onMessage` → delivered |
| Opened from background | `onMessageOpenedApp` → opened |
| Cold start tap | `getInitialMessage` → opened |
| Background / terminated receive | host `onBackgroundMessage` → delivered |

## Signing

HMAC-SHA256 over:

```text
METHOD
path+query
unixSeconds
body
```

Headers: `x-timestamp`, `x-signature`.

Sign path **without** `/v1` (nginx strips it). Public URL is `/v1/...`.

## Platform

Hello / receipts run on **android** and **ios**. Other hosts skip the request.
Device fields (`os_version`, `app_version`) come from
[device_helpers](https://github.com/GeceGibi/device_helpers).
