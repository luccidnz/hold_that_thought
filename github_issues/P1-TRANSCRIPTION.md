---
title: "[P1] Implement Automated Audio Transcription"
labels: P1, feature, backend, cloud-function
---

## Description

Create the serverless backend function that automatically transcribes uploaded audio files. This is the core "Pro" feature of the application.

## Acceptance Criteria

- [ ] **Cloud Function:**
    - [ ] Create a new Firebase Cloud Function that is triggered by the `onFinalize` event on the Firebase Storage bucket for audio files.
    - [ ] The function should receive the file path of the uploaded audio.
    - [ ] The function should call the Google Cloud Speech-to-Text API with the audio file.
    - [ ] The audio must be configured for the correct encoding and sample rate that the client app is recording in (e.g., WAV, 16000Hz).
    - [ ] **Error Handling:** The function must gracefully handle errors from the Speech-to-Text API.
- [ ] **Database Update:**
    - [ ] Upon receiving a successful transcription, the function should find the corresponding "Thought" document in Cloud Firestore.
    - [ ] It should update the `transcript` field of the document with the transcribed text.
    - [ ] It should update a `status` field to indicate that transcription is complete (e.g., from `processing` to `completed`).
- [ ] **Client App:**
    - [ ] The Flutter app should listen to real-time updates on the "Thought" document.
    - [ ] When the `transcript` field is populated, the UI should update automatically to display the text.
