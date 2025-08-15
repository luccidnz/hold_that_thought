# Product Roadmap: Hold That Thought

This document outlines the planned features and development priorities for the "Hold That Thought" application, categorized into phases.

---

## P0: MVP & Core Functionality

*Goal: A demoable, single-user application that works offline and fulfills the basic promise of capturing thoughts.*

- **[P0-AUTH] User Authentication:** Set up Firebase Authentication with a basic email/password provider. Create simple sign-up and login screens.
- **[P0-CAPTURE-UI] Core Capture UI:** Implement the main screen with a text input field and a record button.
- **[P0-LOCAL-DB] Local Persistence:** Set up the Isar database to save, update, and delete thoughts on the local device.
- **[P0-LIST-VIEW] Thought List:** Create a screen that displays a list of all saved thoughts from the local database.
- **[P0-AUDIO-RECORD] Basic Audio Recording:** Implement audio recording using the `record` package and save the recording to a local file.

---

## P1: "Pro Tier" & Cloud Features

*Goal: Implement the core cloud-based features that would differentiate a "Pro" user from a "Free" user.*

- **[P1-CLOUD-SYNC] Firestore Sync:** Integrate Cloud Firestore to enable real-time synchronization of thoughts between multiple devices for a logged-in user.
- **[P1-AUDIO-UPLOAD] Audio File Upload:** On thought creation, upload the saved audio file to Firebase Storage.
- **[P1-TRANSCRIPTION] Automated Transcription:** Create the Firebase Cloud Function that is triggered by audio uploads, calls the Google Speech-to-Text API, and saves the transcript back to the corresponding thought in Firestore.
- **[P1-CATEGORIZATION] Basic Categorization:** Allow users to manually add string-based tags or categories to their thoughts.

---

## P2: Nice-to-Haves & Advanced Features

*Goal: Flesh out the application with features that enhance the user experience and add value.*

- **[P2-REMINDERS] Natural Language Reminders:** Implement a feature to parse temporal phrases (e.g., "tomorrow at 5pm") from thoughts and set a local notification.
- **[P2-EXPORT] Export Functionality:** Allow users to export single thoughts or their entire collection as plain text or Markdown.
- **[P2-PREROLL] Audio Pre-roll Buffer:** Implement the 10-second pre-roll audio buffer as described in the README. This is a complex feature and is deferred until the core functionality is stable.
- **[P2-AI-CATEGORY] AI-Powered Categorization:** Use a service like Vertex AI (as hinted in the README) to suggest or automatically assign categories to thoughts based on their content.
- **[P2-SETTINGS] Settings Screen:** Build a settings screen for managing account, subscription, and app preferences.

---

## Risks & Unknowns

- **Cloud Costs:** The usage of Firebase Storage, Functions, and Google Speech-to-Text can incur significant costs, especially with long audio files. Cost estimation and monitoring will be critical.
- **Transcription Accuracy:** The accuracy of the Speech-to-Text API may vary based on audio quality, accents, and background noise.
- **Audio Buffer Complexity:** Implementing the pre-roll audio buffer (`audio_engine.dart`) requires careful state management and handling of audio data streams, which can be complex to debug.
- **Platform-Specific Integration:** Features like background recording or notifications may require significant platform-specific code for Android and iOS.
