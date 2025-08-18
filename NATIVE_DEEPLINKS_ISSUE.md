# Enable native deep links (Android/iOS) once platform folders exist

We support web deep links (`/note/:id`) already. This tracks adding **native** deep links with the custom scheme `myapp://note/<id>`.

## Why
- Open specific notes from notifications, widgets, or external apps.
- Parity with web routing.

## Platforms & Tasks
### Android
- [ ] Add `<intent-filter>` in `android/app/src/main/AndroidManifest.xml`:
  - `android.intent.action.VIEW`
  - `android.intent.category.DEFAULT`
  - `android.intent.category.BROWSABLE`
  - `<data android:scheme="myapp" android:host="note" />` (or use `android:host="open"` and `pathPrefix="/note"`—choose final format)
- [ ] Validate with `adb shell am start -a android.intent.action.VIEW -d "myapp://note/123" <package>`

### iOS
- [ ] In `ios/Runner/Info.plist`, add URL Types with `CFBundleURLSchemes` = `myapp`.
- [ ] (If needed) Handle in `AppDelegate` / `SceneDelegate` to forward to router.
- [ ] Test via Notes > Run: `xcrun simctl openurl booted "myapp://note/123"`

### Router wiring
- [ ] Ensure incoming URLs parse to `/note/:id` via `go_router` `RouteInformationProvider`.
- [ ] If note ID is invalid, redirect to 404 (already implemented).

## Pre-reqs
- [ ] Generate platform folders (if missing): `flutter create .`
- [ ] Confirm flavors/bundle IDs if we have them before adding URL schemes.

## Acceptance criteria
- Launching `myapp://note/<id>` opens the app to the note detail on Android and iOS.
- Invalid IDs land on the NotFound page.
- README updated with a short “Native deep links” section referencing `docs/deeplinks-native.md`.

## References
- docs/deeplinks-native.md
- go_router deep linking docs
