# Architecture Overview

This document describes the architecture of the "Hold That Thought" application. It follows a standard mobile app architecture with a Flutter frontend and a serverless Firebase backend.

## Components

1.  **Flutter Client:** A cross-platform application built with Flutter. It is responsible for the UI, state management, local persistence, and communication with the backend services.
2.  **Firebase Services:** A suite of managed backend services providing authentication, database, file storage, and serverless functions.
    -   **Firebase Authentication:** Manages user sign-up and login.
    -   **Cloud Firestore:** A NoSQL document database for storing user data, thoughts, transcripts, and categories. Serves as the sync mechanism between devices.
    -   **Firebase Storage:** Stores raw audio files uploaded by the user.
    -   **Cloud Functions:** Provides serverless compute to run backend logic, primarily for audio transcription.
3.  **Google Cloud APIs:** Additional Google Cloud services leveraged by the backend.
    -   **Speech-to-Text API:** Used by a Cloud Function to transcribe audio files.
4.  **Local Database (Isar):** An embedded database within the Flutter app for fast, local-first storage of thoughts. This allows the app to be fully functional offline (for the Free tier) and provides a snappy UI.

## Data Flow Diagram

The following diagram illustrates the primary data flows for core features like authentication and thought creation/transcription.

```mermaid
graph TD
    subgraph "User Device"
        A[Flutter App] -- Signs in with --> B[Firebase Auth];
        A -- Writes/Reads Thoughts --> C[Isar Local DB];
        A -- Syncs Thoughts --> D[Cloud Firestore];
        A -- Uploads Audio --> E[Firebase Storage];
        D -- Sends Transcripts --> A;
    end

    subgraph "Google Cloud Backend"
        E -- Triggers --> F[Cloud Function (on file create)];
        F -- Sends Audio for Transcription --> G[Google Speech-to-Text API];
        G -- Returns Transcript --> F;
        F -- Writes Transcript to --> D;
    end

    B --> A;
```
