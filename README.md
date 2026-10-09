# pusher

Flutter plugin for [stats.pusher.tr](https://stats.pusher.tr).

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

Stats host is fixed to `https://stats.pusher.tr` (not overridable).

## Quick start

```dart
import 'package:pusher/pusher.dart';

await Pusher.init(
  projectId: 'YOUR_PROJECT_ID',
  statsKey: 'YOUR_STATS_KEY',
);
```

`init` writes config to native storage, posts device hello on a native thread,
and attaches foreground FCM listeners (opened / foreground delivered via
MethodChannel → native HTTP).

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

1. Add **`pusher/core`** (not full `pusher`) to the extension target — core has
   no Flutter dependency. Runner already gets `pusher/flutter` via Flutter tooling.
2. Push payload must include `mutable-content: 1` and `data.nid`.

```ruby
# ios/Podfile — ImageNotification (NSE) only
pod 'pusher/core', :path => File.join('.symlinks', 'plugins', 'pusher', 'ios')
```

```swift
import pusher

// inside didReceive(_:withContentHandler:)
PusherStats.handleNotification(request.content.userInfo)
```

## Methods

| Method | Role |
| --- | --- |
| `init` | Native config + hello + attach |
| `syncToken` | Hello with FCM token |
| `hello` / `receipt` / `attach` | Public if needed alone |
| `onBackgroundMessage` | Optional Dart fallback only |

```dart
unawaited(Pusher.syncToken(token: token));
```

## Signing

HMAC-SHA256 over:

```text
METHOD
path+query
unixSeconds
body
```

Headers: `x-timestamp`, `x-signature`. Sign path **without** `/v1`.
