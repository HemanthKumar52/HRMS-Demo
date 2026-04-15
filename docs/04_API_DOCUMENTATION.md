# PPULSE HRMS — API Documentation

**Base URL:** `http://localhost:8000/v1`
**Auth:** Bearer JWT token in Authorization header
**Format:** JSON request/response

---

## Authentication

### POST /auth/login
Login and receive JWT tokens.

**Request:**
```json
{ "username": "admin", "password": "admin23" }
```
**Response 200:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": 1, "name": "Admin User", "email": "admin@ppulse.com",
    "role": "admin", "badge_id": "ADM001",
    "department": "Engineering", "designation": "System Administrator",
    "avatar_url": null
  }
}
```
**Error 403:** `{"error": {"code": "ACCOUNT_LOCKED", "message": "Too many failed attempts..."}}`

### POST /auth/refresh
```json
{ "refresh": "eyJ..." }
```
**Response 200:** `{"access": "eyJ..."}`

### POST /auth/logout
```json
{ "refresh": "eyJ..." }
```

### POST /auth/change-password
```json
{ "old_password": "old", "new_password": "new" }
```

### POST /auth/forgot-password
```json
{ "email": "user@company.com" }
```

---

## User Profile

### GET /users/me
Returns current user's profile with employee details.

### POST /users/me/avatar
Multipart form upload of profile photo.

---

## Attendance

### POST /attendance/face-punch-in
Face-verified check-in with GPS and multi-frame liveness.

**Request:**
```json
{
  "image": "<base64>",
  "extra_frames": ["<base64>", "<base64>"],
  "latitude": 12.9716,
  "longitude": 77.5946,
  "location_name": "Bangalore, KA",
  "source": "mobile",
  "device_info": "iPhone 15 Pro"
}
```
**Response 200:** `{"status": "punched_in", "attendance_id": 142}`
**Error 403:** `{"error": {"code": "FACE_MISMATCH", "message": "..."}}`

Possible error codes: `LOCATION_REQUIRED`, `GEOFENCE_OFFICE`, `WFH_OUT_OF_ZONE`, `FACE_MISMATCH`, `FACE_VERIFICATION_FAILED`, `BIOMETRIC_PUNCH_ACTIVE`, `ALREADY_PUNCHED_IN`

### POST /attendance/punch-out
```json
{ "latitude": 12.97, "longitude": 77.59, "location_name": "Bangalore" }
```

### GET /attendance/today
Returns today's punch record.

### GET /attendance/monthly?month=4&year=2026
Returns monthly attendance log with daily records.

### GET /attendance/team
Manager only. Returns team attendance with per-employee details.

### POST /attendance/regularize
```json
{ "attendance_date": "2026-04-10", "clock_in": "09:00", "clock_out": "18:00", "reason": "Missed punch" }
```

---

## Leave Management

### GET /leaves/balance
Returns leave balances by type.

### POST /leaves/apply
```json
{
  "leave_type_id": 1, "start_date": "2026-04-20",
  "end_date": "2026-04-21", "description": "Family event"
}
```

---

## Requests

### GET /requests?role=self&status=all&type=all
List requests with filters. `role`: self|manager. `type`: leave|claim|ticket|shift|work_type|attendance|asset.

### GET /requests/{id}
Request detail with full metadata.

### POST /requests/{id}/accept
Manager approves. Body: `{"comment": "Approved"}`

### POST /requests/{id}/reject
Manager rejects. Body: `{"comment": "Insufficient leave balance"}`

### POST /requests/{id}/cancel
Employee cancels own request.

---

## Payslips

### GET /payslips
List available payslips.

### GET /payslips/list
Detailed payslip list with earnings/deductions.

### GET /payslips/{id}/pdf
Download payslip as PDF.

---

## Notifications

### GET /notifications
Returns notifications with unread count.

### POST /notifications/{id}/read
Mark single notification as read.

### POST /notifications/read-all
Mark all as read.

---

## Admin (Super Admin Only)

### GET /admin/command-center
Org-wide dashboard: headcount, compliance %, pending approvals, alerts.

### GET /admin/audit-logs?limit=50&offset=0&action=request_approved
Paginated audit trail with action filter.

### GET /admin/users?search=rahul&role=employee
List users with search and role filter.

### POST /admin/users/{id}/{action}
Actions: enable, disable, promote, reset-password, force-logout.

### GET /admin/geofences | POST /admin/geofences
CRUD for office geofences.

### GET /admin/holidays | POST /admin/holidays
CRUD for company holidays.

---

**78 endpoints total.** Full OpenAPI spec available on request.
