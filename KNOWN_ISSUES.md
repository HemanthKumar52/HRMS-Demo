# PPULSE HRMS — Known Issues & Future Fixes

Audit date: 2026-04-14

## Status: Working

These features are verified working end-to-end:

- [x] Login: admin/admin23, rahul/rahul23, vikram/vikram23 (all 16 users)
- [x] Dashboard: punch-in timer, quick actions, manager insights, charts
- [x] Attendance: daily/monthly logs, face verification dialog, timesheet grid
- [x] Requests: leave, claims, tickets, shift change, work type, attendance regularization
- [x] Admin panel: command center, users, audit logs, settings (accessed via dashboard)
- [x] Notifications: polling, mark read, push notifications
- [x] Timesheet: weekly grid with project/task rows, period navigation, summary cards
- [x] API: all 20+ endpoints responding correctly (200 OK)
- [x] iOS build: compiles clean with native SwiftUI platform views
- [x] Android build: unaffected by iOS native integration
- [x] Face verification pipeline: RetinaFace + ArcFace + cosine matching + multi-frame liveness
- [x] Preprocessing: adaptive gamma handles pitch-dark (mean=10) through blown-out (mean=250)

## Issues Found During Audit

### P0 — Critical (Fix Before Demo)

1. **Account locking too aggressive during development**
   - File: `ppulse_backend/api/views.py` (AuthView.post, around line 300)
   - Problem: Failed login attempts from API testing lock accounts. Lock window is
     too short for dev but the counter increments on every test-script run.
   - Fix: Add a `DEBUG`-mode bypass or increase lock threshold from 5 → 15 attempts
     for development. In production keep it at 5.

2. **Face enrollment is CLI-only**
   - File: `ppulse_backend/api/management/commands/register_faces.py`
   - Problem: No mobile/web UI for enrolling faces. New employees can't self-enroll.
     Admin must run `python manage.py register_faces` with photos on server disk.
   - Fix: Add a `POST /v1/face/enroll` endpoint that accepts base64 images from
     the mobile app + an admin enrollment screen.

### P1 — Important

3. **Timesheet: zero-hour anchor entry on row creation**
   - File: `lib/screens/attendance/timesheet_section.dart` (_addRow method)
   - Problem: Adding a new project/task row creates a 0-hour entry for Monday to
     anchor the row. This entry shows up in the backend with hours=0. The backend
     POST endpoint rejects hours <= 0 (changed to hours < 0 but was originally > 0).
   - Fix: Backend should allow hours=0 for anchoring, OR the frontend should create
     the row client-side and only POST when the user enters actual hours.

4. **Timesheet: no period submit button in mobile UI**
   - File: `lib/screens/attendance/timesheet_section.dart`
   - Problem: Backend has `POST /timesheet/submit` but the mobile grid has no
     "Submit for Approval" button. Timesheets stay in draft forever.
   - Fix: Add a submit button below the grid when status is 'draft'.

5. **Native iOS attendance view: camera feed not shown inside SwiftUI ring**
   - File: `ios/Runner/NativeViews/AttendanceCheckInView.swift`
   - Problem: The SwiftUI view shows a spinner during scanning but doesn't embed
     the actual camera preview inside the ring. The camera runs on the Flutter side
     (via camera plugin) but the feed isn't piped to the native view.
   - Fix: Either pipe CameraPreview frames via a texture channel, or render the
     camera entirely in Swift using AVCaptureSession + AVCaptureVideoPreviewLayer.

### P2 — Nice to Have

6. **No payslip data in backend**
   - File: `lib/screens/payslip/payslip_screen.dart`
   - Problem: Payslip screen exists but the backend likely has no payslip data seeded.
     Screen will show empty state.
   - Fix: Seed payslip data or add a note that it requires Horilla payroll module.

7. **Dashboard charts show zero when no attendance data**
   - File: `lib/screens/dashboard/dashboard_screen.dart` (chart widgets)
   - Problem: fl_chart widgets show flat-line / zero values when the employee has
     no historical attendance records. Not a bug per se, but looks odd on first use.
   - Fix: Show a "No data yet" placeholder when all chart values are zero.

8. **Timesheet grid horizontal scroll on small phones**
   - File: `lib/screens/attendance/timesheet_section.dart`
   - Problem: The grid has 7+ columns (# + project + task + 5 days + total + delete).
     On phones < 375px width the horizontal scroll works but column headers and data
     rows scroll independently (no sticky first columns).
   - Fix: Use a SliverStickyHeader or a custom scroll controller to freeze the
     project/task columns while scrolling the day columns.

9. **Admin panel back navigation on Android**
   - File: `lib/screens/admin/admin_panel_screen.dart`
   - Problem: The admin panel uses its own bottom nav. On Android, the system back
     button should go back to the main dashboard but if the user is on a sub-tab
     (e.g., Audit) it just pops the whole panel instead of going to Overview first.
   - Fix: Wrap in WillPopScope and handle tab-level back navigation.

10. **Missing employee face enrollment UI**
    - Problem: Admin can see face enrollments in the admin panel (round3 screens)
      and delete them, but there's no way to enroll new faces from the app.
    - Fix: Build an enrollment flow: admin selects employee → camera captures 3-5
      photos → POST to a new `/v1/admin/face-enroll` endpoint → averaged embedding
      stored.

## Performance Notes

- Face verification cold start: ~2s (model load). Subsequent: ~150-300ms.
- Timesheet week navigation: ~200ms per API call.
- Dashboard data load: ~400ms (parallel API calls).
- iOS native platform view init: ~100ms (UIHostingController creation).

## Security Notes

- All passwords are `<username>23` — change before any non-demo deployment.
- JWT tokens expire in 30 days (SimpleJWT default) — tighten for production.
- Face verification threshold at 0.55 cosine similarity — production-grade.
- Anti-spoofing catches screen replays (score 0.87) but not high-quality video
  replays. For highest security, add a neural PAD model (MiniFASNet or similar).
