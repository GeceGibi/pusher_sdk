# pusher

Pusher mobile SDK for Flutter: device hello and notification receipts.

Flutter supplies **project id** and **stats key**. Native Android/iOS own
HMAC signing and HTTP (`hello` / receipts). `device_helpers` stays a Dart
dependency for OS/app fields on hello.

Supports **Swift Package Manager** (`ios/pusher/Package.swift`) and CocoaPods
(`ios/pusher.podspec`).

Dart entrypoint: `import 'package:pusher/pusher.dart'`.

## Install

```yaml
dependencies:
  pusher:
    git:
      url: https://github.com/GeceGibi/pusher_sdk.git
```

Requires Firebase Messaging in the host (`Firebase.initializeApp` before use).

Android package: `com.pusher.sdk`.

## Keys

| Arg | What |
| --- | --- |
| `projectId` | Project id (`pid`) from the panel |
| `statsKey` | Per-project stats key from the panel |

## Quick start

```dart
import 'package:pusher/pusher.dart';

await Pusher.init(
  projectId: 'YOUR_PROJECT_ID',
  statsKey: 'YOUR_STATS_KEY',
  // enableLogs: false, // optional; defaults to kDebugMode
);
```

`init` writes config to native storage, posts device hello on a native thread,
and attaches foreground FCM listeners (opened / foreground delivered via
MethodChannel → native HTTP).

Hosts that show a local notification (Android foreground) should report open
themselves when the user taps it:

```dart
unawaited(Pusher.receipt(nid: nid, status: .opened));
```

## Background delivered

| Platform | How |
| --- | --- |
| Android | Plugin `PusherMessagingReceiver` (C2DM) — no Dart handler required |
| iOS | Host Notification Service Extension calls `PusherStats.handleNotification` |

### iOS App Group + NSE

The plugin always uses App Group id:

```text
group.<mainBundleId>
```

Example: host bundle `com.example.app` → `group.com.example.app`.

You must create that App Group and enable it on **both** Runner and the
Notification Service Extension entitlements. Do not invent a different group
name — the plugin will not read a custom id.

Then:

1. Add **`PusherStats`** to the extension target. It has no Flutter dependency,
   so archive does not collide with Runner’s `pusher.framework`.
2. Push payload must include `mutable-content: 1` and `data.nid`.

```ruby
# ios/Podfile — ImageNotification (NSE) only
pod 'PusherStats', :path => File.join('.symlinks', 'plugins', 'pusher', 'ios')
```

```swift
import PusherStats

// inside didReceive(_:withContentHandler:)
PusherStats.handleNotification(request.content.userInfo) {
  contentHandler(bestAttemptContent)
}
```

## Methods

| Method | Role |
| --- | --- |
| `init` | Native config + hello + attach |
| `clientId` / `getClientId` | Stable install/client id |
| `syncToken` | Hello with FCM token |
| `hello` / `receipt` / `attach` | Public if needed alone |
| `onBackgroundMessage` | Optional Dart fallback only |

```dart
final clientId = await Pusher.getClientId();
unawaited(Pusher.syncToken(token: token));
```

## Device Payloads

Sample JSON payloads collected from the client and sent to `stats.pusher.tr`:

### 1. Device Registration (`POST /<pid>/hi`)

```json
{
  "clientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "platform": "ios",
  "locale": "tr_TR",
  "isEmulator": false,
  "debugMode": false,
  "appVersionCode": "100",
  "sdkVersion": "0.0.1",
  "token": "fcm_token_optional",
  "osVersion": "18.0",
  "appVersion": "1.0.0",
  "brand": "Apple",
  "model": "iPhone 15 Pro"
}
```

### 2. Notification Receipt (`POST /<pid>/n/<nid>`)

```json
{
  "clientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "platform": "ios",
  "status": 1,
  "locale": "tr_TR",
  "isEmulator": false,
  "debugMode": false,
  "appVersionCode": "100",
  "sdkVersion": "0.0.1",
  "osVersion": "18.0",
  "appVersion": "1.0.0",
  "brand": "Apple",
  "model": "iPhone 15 Pro"
}
```
*`status`: `1` = delivered, `2` = opened.*

## Signing

HMAC-SHA256 over:

```text
METHOD
path+query
unixSeconds
body
```

Headers: `x-timestamp`, `x-signature`. Sign path **without** `/v1`.
