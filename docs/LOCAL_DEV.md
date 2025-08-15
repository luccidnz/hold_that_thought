# Local Development Setup for "Hold That Thought"

This guide provides the exact steps to set up the "Hold That Thought" project for local development, from cloning the repository to running the application.

## 1. Prerequisites

You will need the following tools installed on your system. It is highly recommended to use a version manager like `asdf`, `nvm`, or `fvm` to manage tool versions.

- **Node.js:** Version 20 (specified in `functions/package.json`)
- **Flutter SDK:** A version compatible with `>=3.3.0 <4.0.0` (e.g., `3.19.6`).
- **Firebase CLI:** For deploying cloud functions and configuring the project.
  - Install via npm: `npm install -g firebase-tools`
- **FlutterFire CLI:** For configuring Firebase in the Flutter app.
  - Install via dart: `dart pub global activate flutterfire_cli`

The `.tool-versions` file in the root of this repository can be used with `asdf` to automatically switch to the correct Node.js and Flutter versions.

```sh
# After installing asdf and its plugins for nodejs & flutter
asdf install
```

## 2. Firebase Project Setup

This project is tightly integrated with Firebase. You must have a Firebase project to run the application.

1.  **Create a Firebase Project:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  **Upgrade to Blaze Plan:** Cloud Functions with Google Cloud APIs (like Speech-to-Text) require the "Blaze (pay as you go)" plan.
3.  **Enable APIs:** In your Google Cloud Console for the same project, ensure the following APIs are enabled:
    - **Cloud Speech-to-Text API**
    - **Vertex AI API** (as mentioned in the original README for future AI features)
4.  **Enable Authentication:** In the Firebase Console, go to **Authentication** -> **Sign-in method** and enable at least one provider (e.g., Email/Password, Google).

## 3. Frontend Setup (Flutter)

1.  **Install Dependencies:**
    - `flutter pub get`

2.  **Generate Hive Adapters:**
    - The project uses Hive for local storage, which requires code generation. Run the following command from the root directory:
    - `flutter pub run build_runner build --delete-conflicting-outputs`
    - This command generates the `thought.g.dart` file necessary for Hive to serialize the `Thought` model. You will need to re-run this command any time you change a model with Hive annotations.

3.  **Configure Firebase (Optional for MVP):**
    - For the offline-first MVP, Firebase is not strictly required. However, to prepare for future cloud sync features:
    - Run `flutterfire configure` and select your Firebase project. This will generate `lib/firebase_options.dart`.

4.  **Run the App:**
    - You can run the app on a simulator, emulator, or a physical device.
    - `flutter run`

## 4. Backend Setup (Firebase Cloud Functions)

1.  **Navigate to Functions Directory:**
    - `cd functions`

2.  **Install Dependencies:**
    - Run `npm install`.
    - This will install all necessary Node.js packages and generate the `package-lock.json` file, which should be committed.

3.  **Deploy Functions:**
    - Before the app can use backend services like transcription, you must deploy the functions.
    - `firebase deploy --only functions`

## 5. Running the Full Application

Once both frontend and backend dependencies are installed and the functions are deployed, you can run the Flutter app on any target (web, Android, iOS). The app will automatically connect to your configured Firebase project.
