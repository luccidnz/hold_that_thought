# Native Deep Links

This document outlines the setup for native deep links on Android and iOS.

**Status:** Implemented (Code-side). Native project files need to be updated manually as this environment cannot generate them.

**Scheme:** `myapp://note/<id>`
**Web URL:** `/note/<id>`

---

## Android Setup

1.  Generate the Android project if it doesn't exist: `flutter create .`
2.  Open `android/app/src/main/AndroidManifest.xml`.
3.  Inside the main `<activity>` tag (the one with `.MainActivity`), paste the contents of [`deeplinks-android.md`](deeplinks-android.md).

## iOS Setup

1.  Generate the iOS project if it doesn't exist: `flutter create .`
2.  Open `ios/Runner/Info.plist`.
3.  Paste the contents of [`deeplinks-ios.md`](deeplinks-ios.md) inside the top-level `<dict>` tag.

## macOS Setup (Optional)

For macOS, you can add a similar entry to the `macos/Runner/Info.plist` file.

## Testing

### Android Emulator
From your terminal, you can simulate a deep link click with the Android Debug Bridge (`adb`):
```sh
adb shell am start -a android.intent.action.VIEW -d "myapp://note/123" com.example.hold_that_thought
```
(Replace `com.example.hold_that_thought` with the actual package name).

### iOS Simulator
From your terminal, you can use `xcrun` to simulate a deep link:
```sh
xcrun simctl openurl booted "myapp://note/123"
```
