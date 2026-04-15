# PPULSE HRMS — Submission Package Structure

## Folder Layout

```
PPULSE_HRMS_Submission/
│
├── docs/
│   ├── 01_MASTER_TECHNICAL_DOCUMENT.md    — Complete DPR (all sections)
│   ├── 02_PRODUCT_OVERVIEW.md             — Features, roles, differentiators
│   ├── 03_ARCHITECTURE_DOCUMENT.md        — System design, data flow
│   ├── 04_API_DOCUMENTATION.md            — 78 endpoints with examples
│   ├── 05_DATABASE_SCHEMA.md              — 38 tables with relationships
│   ├── 06_SECURITY_DOCUMENT.md            — Auth, face security, GDPR
│   ├── 07_SETUP_GUIDE.md                  — Development setup
│   ├── 08_DEPLOYMENT_GUIDE.md             — Production deployment
│   ├── 09_TESTING_REPORT.md               — Test results
│   ├── 10_PERFORMANCE_REPORT.md           — Benchmarks, scalability
│   ├── 11_DEMO_VIDEO_SCRIPT.md            — 2:40 walkthrough script
│   └── 12_SUBMISSION_PACKAGE_STRUCTURE.md — This file
│
├── Source_Code/
│   ├── lib/                    — Flutter app (79 files, 32K LOC)
│   ├── ppulse_backend/         — Django API (32 files, 17K LOC)
│   ├── ios/                    — iOS native + SwiftUI views
│   ├── android/                — Android configuration
│   └── pubspec.yaml            — Flutter dependencies
│
├── Build_Files/
│   ├── app-release.apk         — Android release build
│   ├── PPULSE.ipa              — iOS archive (requires signing)
│   └── BUILD_INSTRUCTIONS.md   — How to generate builds
│
├── Demo/
│   ├── screenshots/            — App screenshots (iOS + Android)
│   ├── demo_video.mp4          — 2-3 minute walkthrough
│   └── CREDENTIALS.md          — Login credentials for testing
│
├── README.md                   — Project overview + setup
├── KNOWN_ISSUES.md             — Documented issues with priority
└── CHANGELOG.md                — Version history
```

## What Goes Where

### docs/
All technical documentation, independently printable as PDFs. Each document is self-contained.

### Source_Code/
Complete source code. Clone the git repository for full history.

### Build_Files/
Pre-built binaries ready to install:
- **APK:** Install directly on Android device via `adb install app-release.apk`
- **IPA:** Requires Apple Developer account for signing. Use Xcode Organizer.

### Demo/
Visual assets for stakeholder review:
- Screenshots of key screens (login, dashboard, face verify, admin panel)
- Video walkthrough following the demo script
- Credentials file for hands-on testing

## How to Generate Builds

```bash
# Android APK
flutter build apk --release --dart-define=API_HOST=api.ppulse.com

# iOS IPA
flutter build ipa --release

# Both outputs appear in build/ directory
```

## Credentials to Provide

| Role | Username | Password |
|------|----------|----------|
| Super Admin | admin | admin23 |
| Manager (Sales) | vikram | vikram23 |
| Manager (Legal) | suresh | suresh23 |
| Employee | rahul | rahul23 |

API Base URL: `http://<server>:8000/v1`

---

**PPULSE Technologies** | Submission Package v1.0
