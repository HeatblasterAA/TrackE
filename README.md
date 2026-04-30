# TrackE

SMS-powered expense tracker built with Flutter + Firebase.

Status: MVP Setup Complete → Feature Development Starting

---

## Overview

TrackE automatically captures UPI / bank debit transactions from SMS and converts them into structured expense records.

Primary goals:

- Automatic expense capture (minimal manual entry)
- Date range expense summaries
- Transaction history + filters
- Cloud sync across devices
- Android first, iOS-ready backend design

---

## Tech Stack

### Frontend
- Flutter
- Riverpod
- Hive (local storage)
- flutter_secure_storage
- intl
- permission_handler

### Backend
- Firebase Auth
- Cloud Firestore
- Cloud Functions
- Firebase Crashlytics
- Firebase Analytics (disabled initially)
- Firebase Cloud Messaging (later)

### Architecture
- Monorepo
- Feature-first modular structure
- Local-first with cloud sync
- On-device parsing
- Cloud validation fallback

---

## Project Structure

```text
TrackE/
├── docs/
├── mobile/
│   └── app/
├── backend/
├── shared/
├── .env.example
├── .gitignore
└── README.md
```

Flutter app:

```text
mobile/app/lib/
├── main.dart
├── app.dart
├── firebase_options.dart
├── core/
├── features/
├── models/
├── repositories/
├── providers/
└── widgets/
```

---

## Setup Completed (Day 1)

### Environment
Completed:

- Flutter SDK installed
- Android Studio configured
- Emulator configured
- Java 17 configured
- Gradle configured
- Android SDK Platform installed
- Android NDK repaired/reinstalled
- CocoaPods installed
- Firebase CLI installed
- FlutterFire CLI installed

### Flutter
Completed:

- Flutter app scaffold created
- package renamed:

```text
com.example.app → com.amandev.tracke
```

- App name:

```text
TrackE
```

- Riverpod wired into root app
- Base scaffold created
- Default counter app removed

### Firebase
Completed:

- Firebase project created:

```text
tracke-app-d0fcf
```

- Android app registered:

```text
com.amandev.tracke
```

- google-services connected
- firebase_options.dart generated
- Firebase initialized in app

### Git
Completed:

- Repository initialized
- GitHub remote connected
- Initial commit pushed

Repo:

```text
https://github.com/HeatblasterAA/TrackE
```

---

## Problems Faced + Resolved

1. Gradle hanging on first build  
Resolved by cleaning caches.

2. Corrupted Android NDK install  
Resolved by deleting + reinstalling NDK.

3. Deprecated telephony package  
Removed.

4. Firebase permission/project setup issues  
Resolved via Firebase Console creation.

5. Android package rename crash  
Resolved by aligning native Android package paths.

6. Flutter hot reload stale state  
Resolved with Hot Restart.

---

## MVP Scope

V1:

- Phone auth
- Onboarding
- SMS permission flow
- Native Android SMS ingestion bridge
- Parser engine
- Dedup engine
- Transaction storage
- Transaction list
- Dashboard summary
- Settings

Not in MVP:

- Budgeting
- AI insights
- Bank statement import
- iOS ingestion
- OCR receipt scan

---

## Next Development Order

1. Splash / boot flow
2. Auth
3. Onboarding
4. SMS permission flow
5. Native Android SMS bridge
6. Parser engine
7. Dedup engine
8. Transaction storage
9. Dashboard
10. Settings

---

## Notes

Core principle:

> Local-first → Sync-second → Privacy-first

Store parsed data, not raw SMS wherever possible.

Fallbacks:

- permission denied → manual mode
- parser fail → unknown transaction state
- sync fail → queue locally
- duplicate uncertain → pending review

---

## Changelog

### Day 1
- Project initialized
- Flutter setup completed
- Firebase integrated
- GitHub repo created
- Base architecture scaffold created