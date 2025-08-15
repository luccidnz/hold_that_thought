---
title: "[P0] Implement User Authentication"
labels: P0, feature, auth
---

## Description

Set up the foundational user authentication flow using Firebase Authentication. This is a P0 blocker for any feature requiring user-specific data.

## Acceptance Criteria

- [ ] Add `firebase_auth` dependency if not already present.
- [ ] Configure Firebase Authentication for Email/Password sign-in in the Firebase Console.
- [ ] Create a simple "Login" screen with email and password fields and a "Sign In" button.
- [ ] Create a simple "Sign Up" screen with email and password fields and a "Create Account" button.
- [ ] Implement the logic to call the respective Firebase Auth methods for sign-in and sign-up.
- [ ] Create a basic "Auth Gate" widget that listens to the user's authentication state and shows either the main app content or the Login screen.
- [ ] Add a "Log Out" button somewhere in the main app UI.
