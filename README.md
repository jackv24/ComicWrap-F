# ComicWrap F

A rebuild of [ComicWrap](https://github.com/jackv24/ComicWrap) in Flutter. **WIP!**

This is super not ready for active use, you've been warned!

# Building and Running

**WIP!**

There are a few parts to the whole system:
- A Flutter App (for Android or iOS)
- Firebase project for the Database, Functions and Auth
- A Node.js service for scraping comic websites (which runs on Google App Engine)

## Prerequisites

- Firebase project created (for development - can use free tier with [emulators](https://firebase.google.com/docs/emulator-suite) for functions)
- Flutter App
  - [Flutter SDK](https://flutter.dev/docs/get-started/install)
  - [Android Studio](https://developer.android.com/studio/install) (or [VS Code with dev tools](https://flutter.dev/docs/development/tools/vs-code))
  - (for iOS dev) macOS with XCode
- Node.js & npm

## Setup

### Flutter

- Create a Firebase project
  - (Android) download and copy `google-services.json` to `android/app/`
  - (iOS) download and copy `GoogleService-Info.plist` to `ios/`
