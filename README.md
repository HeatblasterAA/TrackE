# TrackE

SMS-powered expense tracker built with Flutter + Firebase.

Status: Core MVP Backbone Complete

## Overview

TrackE automatically reads financial SMS, parses debit transactions, deduplicates them, stores locally, and syncs across devices.

Core flow:

Auth → Permission → Native SMS Read → Parse → Dedup → Hive Store → Firestore Sync → Cross-device Hydration → Dashboard

## Stack

### Mobile
- Flutter
- Riverpod
- Hive
- flutter_secure_storage
- permission_handler
- intl

### Backend
- Firebase Auth (Phone OTP)
- Cloud Firestore
- Crashlytics (installed)
- Analytics (disabled)
- FCM (planned)

### Native Android
- Kotlin MethodChannel
- SMS Inbox Reader
- Native sender filtering

## Architecture

Android SMS Inbox → Kotlin Native Filter → Flutter Bridge → TransactionParser → SHA256 Dedup → Hive Local Store → Firestore Sync → Device Hydration → Dashboard UI

Principles:

Local-first → Sync-second → Privacy-first

Raw SMS is read transiently; parsed structured data is stored.

## Current Features

### Auth
- Firebase phone auth
- OTP verify flow
- persistent login
- logout
- India (+91) / Saudi (+966)
- E.164 normalization

### App Flow
Launch → Splash → Auth → OTP → Onboarding → Permission → Dashboard

Returning:

Launch → Dashboard

### SMS Ingestion
- READ_SMS permission flow
- Kotlin platform channel bridge
- 90-day SMS fetch
- native financial sender filtering
- real device validated

### Parser v1
Supports:
- UPI debit
- bank debit
- card spend
- INR + SAR
- merchant extraction
- payee extraction
- provider extraction
- bank detection
- mode detection
- category tagging
- false-positive rejection

Structured model:

id, amount, type, mode, displayName, payeeName, provider, bank, category, timestamp

### Dedup
Fingerprint:

sender + body + timestamp → SHA256

Flow:

Parse → Hash → Exists? → Insert only if new

### Persistence
Local:
- Hive

Cloud:
- Firestore `users/{uid}/transactions/{txnId}`

Rules:
- user-isolated auth-based access

Cross-device sync:
- login on new device → hydrate from Firestore → dashboard populated
- Validated.

### Dashboard v1
- total spend card
- recent transaction feed
- refresh import
- clear local
- logout
- auto import on boot

## Repo Structure

```
mobile/app/lib/
├── core/
│   ├── services/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── dashboard/
│   ├── parser/
│   └── splash/
├── models/
├── repositories/
└── providers/
```

## MVP Remaining
- incremental scan (lastScanAt)
- background auto import (WorkManager / BroadcastReceiver)
- production OTP
- settings page polish
- better dashboard UX

## Current State

Implemented:
- Auth ✅
- Onboarding ✅
- Permission flow ✅
- Native SMS bridge ✅
- Parser v1 ✅
- Dedup ✅
- Hive persistence ✅
- Firestore sync ✅
- Cross-device persistence ✅
- Dashboard v1 ✅

Next:
- Incremental scan → Background import