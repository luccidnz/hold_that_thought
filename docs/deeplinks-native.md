# Native Deep Links (TODO)

This document outlines the steps to implement native deep links for Android, iOS, macOS, and Windows once the platform-specific folders are available in the project.

## Android

To enable deep links on Android, you need to add an intent filter to the `android/app/src/main/AndroidManifest.xml` file.

Inside the `<activity>` tag for `MainActivity`, add the following `<intent-filter>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="myapp"
        android:host="note" />
</intent-filter>
```

**Example:**
A URL like `myapp://note/123` will open the app and navigate to the note with ID `123`.

## iOS

For iOS, you need to add a URL type to the `ios/Runner/Info.plist` file.

Add the following keys to the `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.example.holdThatThought</string> <!-- Replace with your bundle ID -->
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

You will also need to handle the URL in your `AppDelegate.swift` file. Here is a sample implementation for `application(_:open:options:)`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // You can handle the URL here if needed, but go_router should handle it automatically.
    return super.application(app, open: url, options: options)
  }
}
```

## macOS & Windows

Native deep linking on desktop platforms requires custom setup.

### macOS
For macOS, you will need to define a custom URL scheme in the `Info.plist` file, similar to iOS. Refer to the official Apple documentation for more details.

### Windows
For Windows, you will need to register a URI scheme with the OS. This typically involves modifying the Windows Registry. Refer to the official Microsoft documentation for more details.

---
*This document is a placeholder until the platform folders are available.*
