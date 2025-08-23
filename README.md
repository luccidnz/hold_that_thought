[![Flutter CI](https://github.com/<org>/<repo>/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/<org>/<repo>/actions/workflows/flutter_ci.yml)

# Hold That Thought

Hold That Thought is a Flutter application designed to help users capture and organise
their fleeting ideas. With a single tap, it records voice input, prepends up to
10 seconds of pre‑roll audio, transcribes the speech to text and automatically
categorises the thought. Users can also type their thoughts directly. The app
supports a Free tier for local storage and a Pro subscription unlocking
cloud synchronisation, unlimited history, extended transcription, custom
categories, background catching and more.

## Features

* **One‑tap capture** – record voice or type a thought instantly.
* **10‑second pre‑roll** – capture speech up to 10 seconds before tapping.
* **Automatic transcription** – Google STT turns audio into text.
* **Thought categorisation** – AI assigns categories or user‑defined labels.
* **Free vs Pro tiers** – choose between local‑only storage and full cloud sync
  with advanced features.
* **Local Storage (Hive)** - Notes are persisted locally using Hive, ensuring that data survives app restarts.
* **Search & Filters** - The home screen provides a powerful search bar and tag-based filtering to quickly find notes. Pinned notes are always displayed at the top.
* **Quick Capture** - A floating action button on the home screen opens a modal bottom sheet to quickly capture a new thought with a title, body, and pin status.
* **Reminders & exports** – set reminders from temporal phrases and export
  thoughts in plain text or markdown.

## Getting Started

1. **Clone the repository** and run `flutter pub get` to install dependencies.
2. **Configure Firebase** by running `flutterfire configure` and selecting the
   appropriate project. This will generate `lib/firebase_options.dart`.
3. **Enable Google Cloud APIs** for Speech‑to‑Text v2 and Vertex AI in the same
   project.
4. **Deploy Cloud Functions** from the `functions/` directory (`firebase deploy --only functions`).
5. **Run the app** on web for quick iteration:

   ```sh
   flutter run -d chrome --web-renderer canvaskit
   ```

6. **Build an Android APK** without the Android NDK:

   ```sh
   flutter build apk --release
   ```

## Directory Structure

```
hold_that_thought/
├── android/                # Android project (created manually)
├── ios/                    # iOS project (created manually)
├── web/                    # Web assets (index.html, manifest, icons)
├── lib/
│   ├── main.dart           # Entry point with router and state providers
│   └── audio/
│       └── audio_engine.dart # Dart‑only ring buffer and WAV writer
├── functions/              # Cloud Functions (transcription, categorisation)
├── scripts/
│   └── cleanup_ci.sh       # Script to clean caches for low‑disk CI
├── .github/
│   └── workflows/
│       └── build.yml       # CI workflow building web and Android APK
├── pubspec.yaml            # Dependencies and project metadata
├── analysis_options.yaml   # Static analysis configuration
└── README.md               # This file
```

## Routing

The app uses `go_router` for navigation. The defined routes are:
- `/` - The home/capture page.
- `/settings` - The settings page.
- `/note/:id` - The detail page for a note.
- `/create` - The page for creating a new note.

Web deep links are supported. For example, you can navigate directly to `/note/123` in a web build. 404 errors are handled and will display a "Not Found" page.

Native deep links (e.g., `myapp://...`) are a TODO. For implementation details, see [docs/deeplinks-native.md](docs/deeplinks-native.md). For a detailed breakdown of the tasks required, see [NATIVE_DEEPLINKS_ISSUE.md](NATIVE_DEEPLINKS_ISSUE.md).

### Navigation Service

To facilitate testing and decouple components from the `go_router` package, the app uses a `NavigationService` abstraction. This service is defined in `lib/routing/navigation_service.dart` and provides a simple `go(String location)` method.

Components that need to navigate should use this service via the `navigationServiceProvider`. This allows for easy mocking in tests.

## Theme & Settings

The app supports dynamic theming with light/dark/system modes and a selection of accent colors. These settings are persisted across app restarts using `shared_preferences`.

The settings can be changed on the `/settings` page.

*(Note: Screenshots of the settings screen in light and dark mode with different accent colors will be added later, as I cannot generate them in this environment.)*

### Storage Location
- **Web:** `shared_preferences` are stored in the browser's `localStorage`. To reset, clear the site data in your browser's developer tools.
- **Mobile (Android/iOS):** `shared_preferences` are stored in the app's sandboxed data directory. To reset, clear the app data or uninstall and reinstall the app.

## Localization

The app supports internationalization (i18n) and is localized for English (en) and Māori (mi).

### Adding/Editing Strings

All user-facing strings are located in the `.arb` (Application Resource Bundle) files in `lib/l10n/`.

- `app_en.arb`: English strings
- `app_mi.arb`: Māori strings

To add or edit a string, modify these files. Each entry must have a unique key and be present in all `.arb` files.

### Generating Localizations

After editing the `.arb` files, you must run the following command to update the `AppLocalizations.dart` class that the app uses to access the strings:

```sh
flutter gen-l10n
```

### Language Selector

The user can change the language from the Settings screen. The options are System, English, and Māori. The selected locale is persisted across app restarts.

## Dev Quickstart

For a quick start on the web, run the following command:
```sh
flutter run -d chrome -t lib/main_dev.dart
```
The app uses path URLs (no hash).

### Flavors

The app has three flavors: `dev`, `staging`, and `prod`. To run a specific flavor, use the `-t` flag with the `flutter run` command:

- **Development:** `flutter run -d chrome -t lib/main_dev.dart`
- **Staging:** `flutter run -d chrome -t lib/main_staging.dart`
- **Production:** `flutter run -d chrome -t lib/main_prod.dart`

## Testing

To run the tests, use the following command:
```sh
flutter test
```
The router tests are located in `test/routing/app_router_test.dart`.

## Low‑Disk CI

The `scripts/cleanup_ci.sh` script removes Gradle caches, Flutter build directories
and other temporary files. It is invoked in the CI workflow to free up disk
space. See `.github/workflows/build.yml` for details.

## Licence

This project is provided for demonstration purposes under the MIT licence.

## Coverage Badge

Current overall test coverage: **57.2%** (see `docs/COVERAGE_SUMMARY.md`).
