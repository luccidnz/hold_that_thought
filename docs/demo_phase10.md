# Phase 10 Demo Script

## Introduction

This demo script walks through the main features of Phase 10 of the Hold That Thought app, including:
- Multi-device Sign-In with Supabase Auth
- Smarter Recall (RAG) with Related, Summarize, and Daily Digest
- Android Foreground Recording
- End-to-End Encryption (E2EE)

## 1. Initial Setup and Onboarding

1. Clean install of the app
2. Show the initial onboarding screen
3. Navigate to the capture page
4. Record a simple thought: "I need to remember to buy groceries later today, including milk, eggs, and bread."
5. Show the thought in the list view
6. Demonstrate basic playback and sharing

## 2. Smarter Recall (RAG)

1. Navigate to Settings
2. Enable the "Smarter Recall (RAG)" feature flag
3. Return to the capture page
4. Record several related thoughts:
   - "I should try that new recipe for chicken parmesan this weekend."
   - "The farmer's market on 5th Street has great fresh vegetables."
   - "I need to check if we have olive oil and garlic before cooking dinner."
   - "The recipe book from Aunt Martha has that great pasta sauce recipe."
5. Navigate to the list view
6. Select one of the food-related thoughts
7. Show the "Related Thoughts" panel with semantically similar thoughts
8. Select multiple thoughts and use the "Summarize" feature
9. Show the generated summary with key points
10. Return to the home screen
11. Show the "Daily Digest" card with summarized insights from today's thoughts

## 3. Android Foreground Recording

1. Navigate to the capture page
2. Explain that Android 13/14 requires notification permissions for background recording
3. Start recording a thought
4. Press the home button to send the app to the background
5. Show the persistent notification in the notification shade
6. Demonstrate that recording continues in the background
7. Lock the screen and continue talking for 30 seconds
8. Unlock the screen and pull down the notification shade
9. Use the notification controls to stop the recording
10. Return to the app and show that the thought was properly saved with the lock screen recording
11. Play back the recording to verify quality

## 4. End-to-End Encryption (E2EE)

1. Navigate to Settings
2. Enable the "End-to-End Encryption" feature flag
3. Set up a passphrase when prompted
4. Explain that the passphrase is never sent to the server and cannot be recovered
5. Return to the capture page
6. Record a new thought: "This is a secret thought that will be encrypted."
7. Navigate to the list view
8. Show the encryption badge on the new thought
9. Close and reopen the app
10. Show the unlock prompt and enter the passphrase
11. Demonstrate that the encrypted thought can now be viewed
12. Open Supabase Storage to show the encrypted .enc files

## 5. Multi-Device Sign-In (if time permits)

1. Navigate to Settings
2. Enable the "Multi-Device Sign-In" feature flag
3. Tap on "Manage Account"
4. Sign in with email and password (or create a new account)
5. Record a new thought
6. Show that the thought is synced to the cloud

### Multi-Device Demo (requires two devices)

1. On Device A, sign in with the same account
2. Record a thought on Device A
3. On Device B, show that the thought appears in the list
4. Demonstrate bidirectional sync by making changes on both devices

### Migration Demo

1. On a device with existing anonymous thoughts
2. Navigate to Settings > Account
3. Sign in with an account
4. Tap on "Migrate Anonymous Data to Account"
5. Show the migration progress
6. Navigate to the list page and show that all thoughts are now associated with the account

## 6. Verification Checklist

1. All features work with flags OFF (legacy mode)
2. RAG provides meaningful related thoughts and summaries
3. Android foreground recording works during lock screen
4. E2EE properly encrypts files and requires passphrase to decrypt
5. Auth enables cross-device sync with proper namespacing
6. All tests pass and CI workflows complete successfully
