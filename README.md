# ComicWrap F

A rebuild of [ComicWrap](https://github.com/jackv24/ComicWrap) in Flutter. **WIP!**

This is super not ready for active use, you've been warned!

# Building and Running

**WIP!**

There are a few parts to the whole system:
- A Flutter App (for Android or iOS)
- An Appwrite instance for backend services
- A Node.js service for scraping comic websites

## Prerequisites

- An Appwrite instance ([can run locally for development](https://appwrite.io/docs/installation))
- Flutter App
  - [Flutter SDK](https://flutter.dev/docs/get-started/install)
  - [Android Studio](https://developer.android.com/studio/install) (or [VS Code with dev tools](https://flutter.dev/docs/development/tools/vs-code))
  - (for iOS dev) macOS with XCode
- Node.js & npm (for web scraper development)

## Setup

1. Make a project in your Appwrite instance
2. WIP

### Flutter

1. Run `flutter pub get`
2. Generate environment config:
```
flutter pub run environment_config:generate \
  --apiEndpoint="[API ENDPOINT]" \
  --apiProjectId="[PROJECT ID]" \
  --apiComicsCollectionId="[COMICS COLLECTION ID]" \
  --apiUsersCollectionId="[USERS COLLECTION ID]"
```