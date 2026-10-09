## 0.9.0

- Sends `sdk_version` on hello and receipt bodies (static; bump with package version).
- Sends optional `brand` and `model` from `device_helpers` on hello and receipts.

## 0.8.0

- Replaces int receipt statuses with `PusherNotificationStatus`
  (`delivered` / `opened`). Use `Pusher.receipt(nid:, status: .opened)`.
- Non-error logs follow `kDebugMode`; pass `enableLogs: false` on `init` to
  silence them. Errors always log (Dart + Android + iOS).

## 0.7.0

- Persists device fields from hello and sends them on every receipt
  (`is_emulator`, `debug_mode`, `app_version_code`).
- Treats API `{status:false}` as failure even when HTTP is 200.

## 0.6.0

- Adds `Pusher` debug logs on Dart / Android / iOS (filter: `adb logcat -s Pusher`).

## 0.5.0

- Splits iOS into `pusher/core` (no Flutter; for NSE) and `pusher/flutter`
  (MethodChannel plugin for Runner).
- SPM products: `pusher` + `pusher-core`.

## 0.3.0

- Recreates the project as a standard Flutter plugin (`flutter create --template=plugin`).
- Adds Swift Package Manager support (`ios/pusher/Package.swift`).
- Keeps CocoaPods via `ios/pusher.podspec`.
- Android package `com.pusher.sdk`; Dart package name `pusher`.
- Updates minimum Flutter version to 3.44.
