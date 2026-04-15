# PPULSE HRMS — Testing Report

**Date:** April 2026 | **Version:** 1.0.0

## 1. Test Summary

| Category | Tests | Passed | Failed |
|----------|-------|--------|--------|
| API Endpoints | 20 | 20 | 0 |
| Face Verification Pipeline | 12 | 12 | 0 |
| Flutter Analyze | 1 (full codebase) | 1 | 0 |
| iOS Build | 1 | 1 | 0 |
| Android Build | 1 | 1 | 0 |
| Login (all roles) | 4 | 4 | 0 |
| Pre-commit Hooks | 7 | 7 | 0 |

## 2. API Endpoint Tests

| Endpoint | Method | Status | Response |
|----------|--------|--------|----------|
| /auth/login (admin) | POST | 200 | Token + role=admin |
| /auth/login (employee) | POST | 200 | Token + role=employee |
| /auth/login (manager) | POST | 200 | Token + role=manager |
| /attendance/today | GET | 200 | Today's record |
| /dashboard/summary | GET | 200 | Full dashboard |
| /requests?status=all | GET | 200 | Request list |
| /notifications | GET | 200 | Notification list |
| /employees | GET | 200 | Employee list |
| /admin/users | GET | 200 | User list (admin) |
| /admin/audit-logs | GET | 200 | Audit trail |
| /me/presence-settings | GET | 200 | Presence config |

## 3. Face Verification Tests

| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| Pitch dark (mean=10) | Very dark frame | Preprocess to ~130 | 130.1 | PASS |
| Very dark (mean=20) | Dark frame | Preprocess to ~128 | 128.5 | PASS |
| Dark (mean=50) | Below normal | Preprocess to ~128 | 127.8 | PASS |
| Normal (mean=128) | Normal frame | Stay ~128 | 127.8 | PASS |
| Very bright (mean=240) | Overexposed | Reduce to ~190 | 191.4 | PASS |
| Screen flat surface | Uniform color | Spoof > 0.70 | 0.87 | PASS |
| Real skin texture | Textured image | Spoof < 0.70 | 0.51 | PASS |
| LBP flat surface | No texture | Score ~1.0 | 1.00 | PASS |
| LBP textured | Rich texture | Score < 0.3 | 0.00 | PASS |
| Blurry image | Gaussian blur | Reject too_blurry | Rejected | PASS |
| No face | Random noise | Reject no_face | Rejected | PASS |
| Model load | N/A | FaceAnalysis OK | Loaded | PASS |

## 4. Build Verification

| Platform | Build Command | Result | Size |
|----------|--------------|--------|------|
| iOS (simulator) | `flutter build ios --simulator` | SUCCESS | 22.4MB |
| iOS (release) | `flutter build ios --no-codesign` | SUCCESS | 22.4MB |
| Android (debug) | `flutter build apk --debug` | SUCCESS | ~45MB |
| Flutter analyze | `flutter analyze --no-fatal-warnings` | 0 errors | N/A |

## 5. Pre-commit Hook Results

All 7 hooks pass on every commit:
- trim trailing whitespace: PASS
- fix end of files: PASS
- check yaml: PASS
- check for merge conflicts: PASS
- detect private key: PASS
- ruff (lint + format): PASS
- dart format + flutter analyze: PASS

## 6. Known Issues

See `KNOWN_ISSUES.md` for 10 documented items (2 P0, 3 P1, 5 P2).

---

**PPULSE Technologies** | QA Report v1.0
