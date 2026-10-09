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
