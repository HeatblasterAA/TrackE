# TrackE

SMS-powered automatic expense tracker built with Flutter + Firebase.

Status: MVP Complete (Private Beta Ready)

---

## Overview

TrackE automatically detects spending transactions from financial SMS, parses them into structured records, stores locally, syncs to cloud, and builds spending insights.

Core flow:

Auth → OTP → Onboarding → SMS Permission → Native SMS Read → Parse → Categorize → Dedup → Hive Store → Firestore Sync → Hydration → Dashboard → Insights

Principles:

Local-first → Sync-second → Privacy-first

Raw SMS is read transiently for parsing.  
Only structured transaction metadata is persisted.

---

## Stack

### Mobile
- Flutter
- Riverpod
- Hive
- flutter_secure_storage
- permission_handler
- intl

### Firebase
- Firebase Auth (Phone OTP)
- Cloud Firestore
- Firebase Crashlytics
- Firebase Analytics (installed, unused)
- Firebase Messaging (planned)

### Native Android
- Kotlin
- MethodChannel bridge
- SMS Inbox reader
- native sender filtering

### Background
- WorkManager periodic scan

---

## Architecture

Android SMS Inbox  
→ Kotlin Native Filter  
→ Flutter Bridge  
→ TransactionParser  
→ SHA256 Dedup  
→ Hive Local Store  
→ Firestore Sync  
→ Cross-device Hydration  
→ Dashboard / Insights UI

---

## Authentication

Implemented:
- Firebase phone auth
- OTP verify screen
- persistent login
- logout
- India (+91)
- Saudi (+966)
- E.164 normalization
- production-ready OTP flow

Flow:

Launch → Splash → Auth → OTP → Onboarding → Permission → Dashboard

Returning:

Launch → Splash → Dashboard

---

## SMS Ingestion

Implemented:
- READ_SMS permission
- RECEIVE_SMS permission
- Kotlin platform bridge
- native sender filtering
- first full scan
- incremental watermark scan
- 2-minute overlap safety window
- background scan infra
- real-device validated

Bridge:

Flutter ↔ Kotlin MethodChannel (`tracke/sms`)

---

## Parser v1

Supports:
- UPI debit
- bank debit
- card spend
- INR
- SAR
- merchant extraction
- payee extraction
- provider extraction
- bank detection
- mode detection
- category tagging
- false-positive rejection

Rejects:
- OTP
- login alerts
- credits
- loan spam
- approval spam
- verification messages

Structured model:

- id
- amount
- currency
- type
- mode
- displayName
- payeeName
- provider
- bank
- category
- timestamp

---

## Dedup

Fingerprint:

sender + body + timestamp → SHA256

Flow:

Parse → Hash → Exists → Insert only if new

Prevents:
- duplicate imports
- repeat scan duplication
- cloud duplication

---

## Persistence

### Local
- Hive

### Cloud
- Firestore `users/{uid}/transactions/{txnId}`

Rules:
- user isolated
- auth gated
- cross-device sync
- hydration on login

Validated on real device.

---

## Dashboard

Implemented:

### Summary
- selected spend
- today spend
- top category
- transaction count

### Date Filters
- Today
- Week
- Month
- Custom range
- All time

### Category Filters
- dynamic chips
- All + detected categories

### Transactions
- formatted amount
- native currency symbol
- merchant / payee
- bank
- mode
- date
- category badge

### Detail Sheet
Tap transaction →
- amount
- merchant
- category
- mode
- bank
- provider
- date/time

### Actions
- refresh scan
- rebuild history
- logout

### Empty States
- no transactions
- no filtered results
- reset filters CTA

---

## Insights

Implemented:
- total spend
- transaction count
- top categories
- biggest spend
- average spend

---

## Currency

Hybrid model:

Each transaction stores native currency.

Supported:
- INR
- SAR

No forced conversion.  
Display remains source currency.

---

## Privacy

Built into onboarding:

- OTP ignored
- personal SMS ignored
- non-financial SMS ignored
- raw SMS not stored
- only parsed transaction metadata persisted

---

## Reliability

Crash monitoring:
- global uncaught exceptions
- scan failures
- cloud sync failures
- raw / parsed / inserted logging

Powered by Firebase Crashlytics.

---

## Repo Structure

```text
mobile/app/lib/
├── core/
│   ├── services/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── dashboard/
│   ├── insights/
│   ├── parser/
│   └── splash/
├── models/
├── repositories/
└── providers/
```

---

## Current State

Implemented:
- Auth ✅
- OTP Verify ✅
- Onboarding ✅
- Permission flow ✅
- Native SMS bridge ✅
- Parser v1 ✅
- Categorization ✅
- Dedup ✅
- Hive persistence ✅
- Firestore sync ✅
- Cross-device hydration ✅
- Incremental scan ✅
- Background scan infra ✅
- Crashlytics wiring ✅
- Dashboard ✅
- Insights ✅

Status:

Private beta ready.

---

## Next

Post-beta:
- parser expansion
- smarter categorization
- merchant learning
- recurring subscriptions
- budgeting
- exports
- iOS exploration