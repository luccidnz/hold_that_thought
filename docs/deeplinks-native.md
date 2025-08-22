# Native Deep Links

This document outlines the setup for native deep links on Android and iOS.

**Status:** Implemented (Code-side). Native project files need to be updated as below once available.

**Scheme:** `myapp://note/<id>`
**Web URL:** `/note/<id>`

---

## Android Setup

To enable deep links on Android, add the following `<intent-filter>` to `android/app/src/main/AndroidManifest.xml` inside the main `<activity>` tag.

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <!-- Custom scheme: myapp://note/<id> -->
  <data android:scheme="myapp" android:host="note"/>
</intent-filter>

<!--
  Optional: To accept https deep-links like https://holdthatthought.app/note/<id>,
  uncomment and configure the following filter. This requires hosting a
  Digital Asset Links JSON file on your domain.
-->
<!--
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="holdthatthought.app" android:pathPrefix="/note"/>
</intent-filter>
-->
```

## iOS Setup

For iOS, add the `CFBundleURLTypes` key to the `ios/Runner/Info.plist` file to register the custom URL scheme.

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>myapp</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

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
