# PPulse HRMS - Full Stack Flow Analysis Report

> End-to-end tracing of every feature: Frontend (Flutter/Dart) -> Backend (Django REST) -> Database (SQLite/PostgreSQL)

---

## Table of Contents

1. [Authentication & Login](#1-authentication--login)
2. [Dashboard](#2-dashboard)
3. [Attendance Management](#3-attendance-management)
4. [Leave Management](#4-leave-management)
5. [Claims Management](#5-claims-management)
6. [Ticket Management](#6-ticket-management)
7. [Shift Request](#7-shift-request)
8. [Work Type Request](#8-work-type-request)
9. [Asset Request](#9-asset-request)
10. [Request Listing & Actions](#10-request-listing--actions)
11. [Payslip Management](#11-payslip-management)
12. [Employee Directory](#12-employee-directory)
13. [Notifications](#13-notifications)
14. [Profile & Settings](#14-profile--settings)
15. [Org Chart](#15-org-chart)
16. [Manager/HR Analytics](#16-managerhr-analytics)
17. [SSO Authentication](#17-sso-authentication-microsoft--google)

---

## 1. Authentication & Login

### Flow Diagram
```
[SplashScreen] -> checks SharedPreferences for auth_token
    |-- Token exists -> [ShellScreen] (main app)
    |-- No token    -> [LoginScreen]
```

### Step-by-Step Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/splash/splash_screen.dart` | `SplashScreen` | Checks if `auth_token` exists in SharedPreferences |
| 2 | **Frontend** | `lib/screens/auth/login_screen.dart` | `LoginScreen` | Shows login form (username + password) |
| 3 | **Frontend** | `lib/screens/auth/login_screen.dart` | `_login()` | Calls `http.post()` to `/v1/auth/login` with `{username, password}` |
| 4 | **Backend** | `ppulse_backend/api/urls.py` | URL: `auth/login` | Routes to `AuthView` |
| 5 | **Backend** | `ppulse_backend/api/views.py` | `AuthView.post()` | Validates via `LoginSerializer`, authenticates user |
| 6 | **Backend** | `ppulse_backend/api/serializers.py` | `LoginSerializer` | Validates `username` and `password` fields |
| 7 | **Database** | Table: `horilla_auth_horillauser` | Query: `User.objects.get(username=username)` | Looks up user by username |
| 8 | **Database** | Table: `employee_employee` | Query: `Employee.objects.get(employee_user_id_id=user.id)` | Gets employee record linked to user |
| 9 | **Database** | Table: `employee_employeeworkinformation` | Query: `EmployeeWorkInformation.objects.get(employee_id_id=employee.id)` | Gets work info (department, designation, manager) |
| 10 | **Backend** | `ppulse_backend/api/views.py` | `AuthView.post()` | Generates JWT tokens (access + refresh), determines role (employee/manager/hr) |
| 11 | **Frontend** | `lib/screens/auth/login_screen.dart` | `_login()` | Stores tokens & user data in SharedPreferences |
| 12 | **Frontend** | `lib/providers/app_provider.dart` | `AppProvider` | Updates state: `isLoggedIn=true`, sets user info |
| 13 | **Frontend** | `lib/screens/shell_screen.dart` | `ShellScreen` | Navigates to main app shell with bottom navigation |

### API Contract

**Request:**
```json
POST /v1/auth/login
{
  "username": "john.doe",
  "password": "secret123"
}
```

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": 1,
    "username": "john.doe",
    "email": "john@company.com",
    "name": "John Doe",
    "employee_id": 42,
    "designation": "Software Engineer",
    "department": "Engineering",
    "role": "employee"
  }
}
```

### Database Tables Involved
| Table | Purpose |
|-------|---------|
| `horilla_auth_horillauser` | Authenticate credentials (username, password hash) |
| `employee_employee` | Get employee profile (name, badge_id, email) |
| `employee_employeeworkinformation` | Get designation, department, reporting manager |
| `base_department` | Resolve department name |
| `base_jobposition` | Resolve job position name |
| `device_token` | Store FCM token for push notifications (if provided) |

---

## 2. Dashboard

### Flow Diagram
```
[ShellScreen] -> Bottom Nav Tab 0 -> [DashboardScreen]
    |-> API: /dashboard/summary
    |-> API: /dashboard/announcements
    |-> Quick Actions -> [ApplyLeaveScreen], [SubmitClaimScreen], etc.
```

### Step-by-Step Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/shell_screen.dart` | `ShellScreen` | Shows `DashboardScreen` as first tab |
| 2 | **Frontend** | `lib/screens/dashboard/dashboard_screen.dart` | `DashboardScreen.initState()` | Calls `_loadDashboard()` |
| 3 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getDashboardSummary()` | `GET /v1/dashboard/summary` |
| 4 | **Backend** | `ppulse_backend/api/urls.py` | URL: `dashboard/summary` | Routes to `DashboardSummaryView` |
| 5 | **Backend** | `ppulse_backend/api/views.py` | `DashboardSummaryView.get()` | Aggregates data from multiple tables |
| 6 | **Database** | `attendance_attendance` | Today's attendance record | Check-in status, worked hours |
| 7 | **Database** | `leave_availableleave` | Leave balances for employee | Available days per leave type |
| 8 | **Database** | `leave_leaverequest` | Recent/pending leave requests | Status, dates |
| 9 | **Database** | `base_announcement` | Active announcements | Where `is_active=True` and `expire_date >= today` |
| 10 | **Frontend** | `lib/screens/dashboard/dashboard_screen.dart` | `_buildDashboard()` | Renders attendance card, leave balance, quick actions, announcements |

### Quick Actions Available
| Action | Screen Navigated To | API Called |
|--------|-------------------|------------|
| Apply Leave | `ApplyLeaveScreen` | `POST /v1/leaves/apply` |
| Submit Claim | `SubmitClaimScreen` | `POST /v1/claims/submit` |
| Raise Ticket | `RaiseTicketScreen` | `POST /v1/tickets/raise` |
| Shift Change | `ShiftChangeScreen` | `POST /v1/shifts/request` |
| Work Type | `WorkTypeRequestScreen` | `POST /v1/work-type/request` |
| Regularize Attendance | `AttendanceRequestScreen` | `POST /v1/attendance/regularize` |
| Directory (Manager/HR) | `DirectoryScreen` | `GET /v1/employees` |
| Analytics (Manager/HR) | `AnalyticsScreen` | `GET /v1/dashboard/analytics` |
| Org Chart (Manager/HR) | `OrgChartScreen` | `GET /v1/org-chart` |

### Database Tables Involved
| Table | Purpose |
|-------|---------|
| `attendance_attendance` | Today's check-in/out status |
| `leave_availableleave` | Leave balance per type |
| `leave_leaverequest` | Pending/recent leave requests |
| `base_announcement` | Company announcements |
| `employee_employeeworkinformation` | Role determination (manager check) |

---

## 3. Attendance Management

### Flow Diagram
```
[ShellScreen] -> Bottom Nav Tab 2 -> [AttendanceScreen]
    |-> GET /attendance/monthly -> Calendar view
    |-> POST /attendance/punch-in -> Clock in
    |-> POST /attendance/punch-out -> Clock out
    |-> POST /attendance/regularize -> Request correction
```

### Punch-In Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/attendance/attendance_screen.dart` | `AttendanceScreen` | User taps "Punch In" button |
| 2 | **Frontend** | `lib/screens/home/face_verification_dialog.dart` | `FaceVerificationDialog` | Optional biometric verification |
| 3 | **Frontend** | `lib/providers/app_provider.dart` | `AppProvider.punchIn()` | Calls `ApiService.punchIn()` |
| 4 | **Frontend** | `lib/services/api_service.dart` | `ApiService.punchIn()` | `POST /v1/attendance/punch-in` with `{latitude, longitude, method}` |
| 5 | **Backend** | `ppulse_backend/api/urls.py` | URL: `attendance/punch-in` | Routes to `AttendancePunchInView` |
| 6 | **Backend** | `ppulse_backend/api/views.py` | `AttendancePunchInView.post()` | Validates via `PunchInSerializer` |
| 7 | **Database** | `attendance_attendance` | `INSERT` | Creates new attendance record with `attendance_clock_in`, `attendance_date` |
| 8 | **Database** | `employee_employeeworkinformation` | `SELECT` | Gets employee's assigned shift for expected times |
| 9 | **Frontend** | `lib/providers/app_provider.dart` | Updates `isPunchedIn=true` | UI updates to show punch-out button |
| 10 | **Frontend** | `lib/services/notification_service.dart` | `showPunchIn()` | Shows local notification confirming punch-in |

### Monthly Attendance View Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/attendance/attendance_screen.dart` | `_loadAttendanceData()` | Calls on screen load and month navigation |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getAttendanceSummary()` | `GET /v1/attendance/monthly?month=3&year=2026` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `AttendanceMonthlyView.get()` | Queries attendance for employee for given month |
| 4 | **Database** | `attendance_attendance` | `SELECT WHERE employee_id_id=X AND month=Y AND year=Z` | All attendance records for the month |
| 5 | **Database** | `leave_leaverequest` | `SELECT WHERE employee_id_id=X AND status='approved'` | Approved leaves overlapping the month |
| 6 | **Frontend** | `lib/screens/attendance/attendance_screen.dart` | Calendar widget | Renders calendar with color-coded days (present/absent/leave/holiday) |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `attendance_attendance` | `attendance_date`, `attendance_clock_in`, `attendance_clock_out`, `attendance_worked_hour`, `is_holiday`, `shift_id_id`, `work_type_id_id` | Core attendance record |
| `employee_employeeworkinformation` | `shift_id_id`, `work_type_id_id` | Employee's assigned shift & work type |
| `base_employeeshift` | `employee_shift`, `full_time` | Shift name & timing |
| `leave_leaverequest` | `start_date`, `end_date`, `status` | Check if day was on approved leave |

---

## 4. Leave Management

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Leave" -> [ApplyLeaveScreen]
    |-> GET /leave-types -> Load leave types dropdown
    |-> GET /leaves/balance -> Show remaining days
    |-> POST /leaves/apply -> Submit leave request
```

### Apply Leave Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/apply_leave_screen.dart` | `ApplyLeaveScreen.initState()` | Fetches leave types and balance |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getLeaveTypes()` | `GET /v1/leave-types` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `LeaveTypesListView.get()` | Returns all leave types |
| 4 | **Database** | `leave_leavetype` | `SELECT *` | All leave types (Casual, Sick, Earned, etc.) |
| 5 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getLeaveBalance()` | `GET /v1/leaves/balance` |
| 6 | **Backend** | `ppulse_backend/api/views.py` | `LeaveBalanceView.get()` | Returns balance per leave type |
| 7 | **Database** | `leave_availableleave` | `SELECT WHERE employee_id_id=X` | Available days, carryforward, total |
| 8 | **Frontend** | `lib/screens/requests/apply_leave_screen.dart` | User fills form | Selects leave type, dates, breakdown, description |
| 9 | **Frontend** | `lib/services/api_service.dart` | `ApiService.applyLeave(data)` | `POST /v1/leaves/apply` |
| 10 | **Backend** | `ppulse_backend/api/views.py` | `LeaveApplyView.post()` | Validates via `LeaveApplySerializer` |
| 11 | **Backend** | `ppulse_backend/api/serializers.py` | `LeaveApplySerializer` | Validates: `leave_type`, `start_date`, `end_date`, `start_breakdown`, `end_breakdown`, `description` |
| 12 | **Database** | `leave_leaverequest` | `INSERT` | Creates leave request with `status='requested'` |
| 13 | **Database** | `leave_availableleave` | `UPDATE` | Deducts requested days from available balance |
| 14 | **Backend** | `ppulse_backend/api/views.py` | `notify_managers_of_request()` | Creates notification for reporting manager |
| 15 | **Database** | `notifications_notification` | `INSERT` | Notification record for manager |
| 16 | **Frontend** | `lib/services/notification_service.dart` | `showRequestApplied('Leave')` | Shows success notification |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `leave_leavetype` | `id`, `name`, `color` | Leave type options |
| `leave_availableleave` | `available_days`, `carryforward_days`, `total_leave_days`, `employee_id_id`, `leave_type_id_id` | Balance check & deduction |
| `leave_leaverequest` | `start_date`, `end_date`, `start_date_breakdown`, `end_date_breakdown`, `requested_days`, `status`, `description`, `employee_id_id`, `leave_type_id_id` | The leave request record |
| `employee_employeeworkinformation` | `reporting_manager_id_id` | Find manager for notification |
| `notifications_notification` | `verb`, `description`, `recipient_id`, `unread` | Manager notification |

---

## 5. Claims Management

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Claims" -> [SubmitClaimScreen]
    |-> POST /claims/submit -> Submit claim
[RequestsScreen] -> Filter "Claims" -> GET /requests?type=Claims
```

### Submit Claim Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/submit_claim_screen.dart` | `SubmitClaimScreen` | Shows claim form |
| 2 | **Frontend** | User fills form | Fields: title, claim_type, description, date, images | Multi-image upload support |
| 3 | **Frontend** | `lib/services/api_service.dart` | `ApiService.submitClaim(data)` | `POST /v1/claims/submit` |
| 4 | **Backend** | `ppulse_backend/api/views.py` | `ClaimSubmitView.post()` | Validates via `ClaimSubmitSerializer` |
| 5 | **Database** | `helpdesk_ticket` | `INSERT` | Creates a ticket with claim details (`title`, `description`, `priority`) |
| 6 | **Database** | `helpdesk_claimrequest` | `INSERT` | Creates claim request linked to the ticket (`ticket_id_id`, `employee_id_id`) |
| 7 | **Backend** | `ppulse_backend/api/views.py` | `notify_managers_of_request()` | Notifies reporting manager |
| 8 | **Database** | `notifications_notification` | `INSERT` | Notification for manager |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `helpdesk_ticket` | `title`, `description`, `priority`, `status`, `employee_id_id` | Base ticket for the claim |
| `helpdesk_claimrequest` | `employee_id_id`, `ticket_id_id`, `is_approved`, `is_rejected` | Claim approval tracking |
| `notifications_notification` | `verb`, `recipient_id` | Manager notification |

---

## 6. Ticket Management

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Tickets" -> [RaiseTicketScreen]
    |-> POST /tickets/raise -> Raise ticket
[RequestsScreen] -> Filter "Tickets" -> GET /requests?type=Tickets
```

### Raise Ticket Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/raise_ticket_screen.dart` | `RaiseTicketScreen` | Shows ticket form |
| 2 | **Frontend** | User fills form | Fields: title, description, priority (low/medium/high) | |
| 3 | **Frontend** | `lib/services/api_service.dart` | `ApiService.raiseTicket(data)` | `POST /v1/tickets/raise` |
| 4 | **Backend** | `ppulse_backend/api/views.py` | `TicketRaiseView.post()` | Validates via `TicketRaiseSerializer` |
| 5 | **Database** | `helpdesk_ticket` | `INSERT` | Creates ticket with `status='open'` |
| 6 | **Backend** | `ppulse_backend/api/views.py` | `notify_managers_of_request()` | Notifies manager |
| 7 | **Database** | `notifications_notification` | `INSERT` | Manager notification |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `helpdesk_ticket` | `title`, `description`, `priority`, `status`, `created_date`, `employee_id_id` | The ticket record |
| `helpdesk_tickettype` | `id`, `title` | Ticket category (optional) |
| `notifications_notification` | `verb`, `recipient_id` | Manager notification |

---

## 7. Shift Request

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Shift" -> [ShiftChangeScreen]
    |-> GET /shifts -> Load available shifts
    |-> POST /shifts/request -> Submit shift change request
```

### Shift Change Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/shift_change_screen.dart` | `ShiftChangeScreen.initState()` | Calls `ApiService.getShifts()` |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getShifts()` | `GET /v1/shifts` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `ShiftsListView.get()` | Returns all shifts |
| 4 | **Database** | `base_employeeshift` | `SELECT *` | All available shifts |
| 5 | **Frontend** | User fills form | Fields: requested shift, date/date range, description | |
| 6 | **Frontend** | `lib/services/api_service.dart` | `ApiService.post('/shifts/request', data)` | `POST /v1/shifts/request` |
| 7 | **Backend** | `ppulse_backend/api/views.py` | `ShiftRequestView.post()` | Validates via `ShiftRequestCreateSerializer` |
| 8 | **Database** | `base_shiftrequest` | `INSERT` | Creates shift request (`shift_id_id`, `requested_date`, `requested_till`, `employee_id_id`) |
| 9 | **Database** | `notifications_notification` | `INSERT` | Notification for manager |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `base_employeeshift` | `id`, `employee_shift`, `full_time` | Available shift options |
| `base_shiftrequest` | `shift_id_id`, `requested_date`, `requested_till`, `description`, `approved`, `canceled`, `employee_id_id` | The shift change request |
| `employee_employeeworkinformation` | `reporting_manager_id_id` | Find manager |
| `notifications_notification` | `verb`, `recipient_id` | Manager notification |

---

## 8. Work Type Request

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Work Type" -> [WorkTypeRequestScreen]
    |-> GET /work-types -> Load available work types
    |-> POST /work-type/request -> Submit request
```

### Work Type Request Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/work_type_request_screen.dart` | `WorkTypeRequestScreen.initState()` | Calls `ApiService.getWorkTypes()` |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getWorkTypes()` | `GET /v1/work-types` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `WorkTypesListView.get()` | Returns all work types |
| 4 | **Database** | `base_worktype` | `SELECT *` | All work types (WFH, On-site, Hybrid, etc.) |
| 5 | **Frontend** | User fills form | Fields: work type, date/range, description | |
| 6 | **Frontend** | `lib/services/api_service.dart` | `ApiService.post('/work-type/request', data)` | `POST /v1/work-type/request` |
| 7 | **Backend** | `ppulse_backend/api/views.py` | `WorkTypeRequestView.post()` | Validates via `WorkTypeRequestCreateSerializer` |
| 8 | **Database** | `base_worktyperequest` | `INSERT` | Creates work type request |
| 9 | **Database** | `notifications_notification` | `INSERT` | Notification for manager |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `base_worktype` | `id`, `work_type` | Available work type options |
| `base_worktyperequest` | `work_type_id_id`, `requested_date`, `requested_till`, `description`, `approved`, `canceled`, `employee_id_id` | The work type request |
| `notifications_notification` | `verb`, `recipient_id` | Manager notification |

---

## 9. Asset Request

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Asset" -> [AssetRequestScreen]
    |-> POST /assets/request -> Submit asset request
```

### Asset Request Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/asset_request_screen.dart` | `AssetRequestScreen` | Shows asset request form |
| 2 | **Frontend** | User fills form | Fields: asset category, description | |
| 3 | **Frontend** | `lib/services/api_service.dart` | `ApiService.requestAsset(data)` | `POST /v1/assets/request` |
| 4 | **Backend** | `ppulse_backend/api/views.py` | `AssetRequestView.post()` | Validates via `AssetRequestCreateSerializer` |
| 5 | **Database** | `asset_assetrequest` | `INSERT` | Creates asset request with `asset_request_status='Requested'` |
| 6 | **Database** | `notifications_notification` | `INSERT` | Notification for manager |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `asset_assetrequest` | `asset_category_id_id`, `description`, `asset_request_date`, `asset_request_status`, `requested_employee_id_id` | The asset request |
| `notifications_notification` | `verb`, `recipient_id` | Manager notification |

---

## 10. Request Listing & Actions

### Flow Diagram
```
[ShellScreen] -> Bottom Nav Tab 1 -> [RequestsScreen]
    |-> Tabs: Requested | Approvals | Assigned | My Requests
    |-> GET /requests?role=self&type=X&status=Y -> List requests
    |-> Tap request -> [RequestDetailScreen]
        |-> GET /requests/{id} -> Full details
        |-> PUT /requests/{id}/accept -> Approve (manager)
        |-> PUT /requests/{id}/reject -> Reject (manager)
        |-> DELETE /requests/{id}/cancel -> Cancel (employee)
```

### List Requests Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/requests_screen.dart` | `RequestsScreen` | Shows tabs based on user role |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getRequests(type, status, role)` | `GET /v1/requests?role=self&type=Leave&status=Pending` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `RequestsListView.get()` | Filters by role, type, status |
| 4 | **Backend** | `ppulse_backend/api/views.py` | Queries multiple tables | Unions results from all 7 request types |
| 5 | **Database** | Multiple tables queried based on `type` filter | See table below |
| 6 | **Frontend** | `lib/screens/requests/requests_screen.dart` | Renders request cards | Shows type, status chip, date, description |

### Request Type to Database Table Mapping

| Filter Type | Database Table | Status Field |
|-------------|---------------|--------------|
| Leave | `leave_leaverequest` | `status` ('requested'/'approved'/'rejected') |
| Claims | `helpdesk_claimrequest` + `helpdesk_ticket` | `is_approved` / `is_rejected` |
| Tickets | `helpdesk_ticket` | `status` ('open'/'closed') |
| Shift Requests | `base_shiftrequest` | `approved` / `canceled` booleans |
| Work Type Requests | `base_worktyperequest` | `approved` / `canceled` booleans |
| Attendance Requests | `attendance_permission_request` | `status` |
| Asset Requests | `asset_assetrequest` | `asset_request_status` |

### Accept/Reject Flow (Manager)

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/requests/request_detail_screen.dart` | Manager taps "Accept" or "Reject" | |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.acceptRequest(id)` or `ApiService.rejectRequest(id, reason)` | `PUT /v1/requests/{id}/accept` or `PUT /v1/requests/{id}/reject` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `RequestAcceptView.put()` or `RequestRejectView.put()` | Determines request type, updates status |
| 4 | **Database** | Respective table | `UPDATE status` | Updates to approved/rejected |
| 5 | **Database** | `notifications_notification` | `INSERT` | Notification for the requesting employee |

---

## 11. Payslip Management

### Flow Diagram
```
[ShellScreen] -> Bottom Nav Tab 3 -> [PayslipScreen]
    |-> GET /payslips/list?year=2026 -> List all payslips
    |-> GET /payslips?month=3&year=2026 -> Specific payslip
    |-> GET /payslips/{id}/pdf -> Download PDF
```

### View Payslip Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/payslip/payslip_screen.dart` | `PayslipScreen.initState()` | Loads payslip list for current year |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getPayslipsList(year)` | `GET /v1/payslips/list?year=2026` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `PayslipsListView.get()` | Queries payslips for employee + year |
| 4 | **Database** | `payroll_payslip` | `SELECT WHERE employee_id_id=X AND year=Y` | All payslips for the year |
| 5 | **Frontend** | User selects month | Taps on specific payslip | |
| 6 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getPayslip(month, year)` | `GET /v1/payslips?month=3&year=2026` |
| 7 | **Backend** | `ppulse_backend/api/views.py` | `PayslipsView.get()` | Returns detailed payslip breakdown |
| 8 | **Database** | `payroll_payslip` | `SELECT WHERE employee_id_id=X AND month=Y AND year=Z` | Gross, net, basic, deduction amounts |
| 9 | **Frontend** | `lib/screens/payslip/payslip_screen.dart` | Renders payslip details | Shows earnings breakdown, deductions, net pay |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `payroll_payslip` | `start_date`, `end_date`, `gross_pay`, `net_pay`, `basic_pay`, `deduction`, `status`, `employee_id_id` | Payslip data |

---

## 12. Employee Directory

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Directory" -> [DirectoryScreen]
    |-> GET /employees?search=X&department=Y -> Search employees
    |-> Tap employee -> [EmployeeProfileView]
        |-> GET /employees/{id} -> Full details
```

### Directory Search Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/directory/directory_screen.dart` | `DirectoryScreen` | Shows search bar + employee list |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getEmployees(search, department)` | `GET /v1/employees?search=john&department=Engineering` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `EmployeesListView.get()` | Filters employees by search term and department |
| 4 | **Database** | `employee_employee` | `SELECT` with filters | Matches name, email, badge_id |
| 5 | **Database** | `employee_employeeworkinformation` | `JOIN` | Gets department, designation, manager |
| 6 | **Database** | `base_department` | `JOIN` | Department name |
| 7 | **Database** | `base_jobposition` | `JOIN` | Job position/designation |
| 8 | **Frontend** | `lib/screens/directory/directory_screen.dart` | Renders employee cards | Avatar, name, designation, department, email |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `employee_employee` | `employee_first_name`, `employee_last_name`, `email`, `badge_id`, `employee_profile` | Employee basic info |
| `employee_employeeworkinformation` | `department_id_id`, `job_position_id_id`, `reporting_manager_id_id`, `date_joining` | Work details |
| `base_department` | `department` | Department name |
| `base_jobposition` | `job_position` | Designation |

---

## 13. Notifications

### Flow Diagram
```
[ShellScreen] -> Polls every 10 seconds
    |-> GET /notifications -> Fetch new notifications
    |-> Shows local push notification for new ones
    |-> PUT /notifications/{id}/read -> Mark as read
    |-> PUT /notifications/read-all -> Mark all as read
```

### Notification Polling Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/shell_screen.dart` | `_checkForNewNotifications()` | Timer fires every 10 seconds |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getNotifications()` | `GET /v1/notifications` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `NotificationsView.get()` | Returns user's notifications |
| 4 | **Database** | `notifications_notification` | `SELECT WHERE recipient_id=X ORDER BY timestamp DESC` | All notifications for user |
| 5 | **Frontend** | `lib/screens/shell_screen.dart` | Compares with seen set | Identifies new unseen notifications |
| 6 | **Frontend** | `lib/services/notification_service.dart` | `NotificationService.show()` | Shows local push notification |
| 7 | **Frontend** | User taps notification | `onNotificationTap` callback | Navigates to Requests tab |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `notifications_notification` | `id`, `verb` (title), `description` (body), `unread`, `timestamp`, `recipient_id` | All notification data |

---

## 14. Profile & Settings

### Flow Diagram
```
[ShellScreen] -> Bottom Nav Tab 4 -> [ProfileScreen]
    |-> GET /users/me -> Load profile
    |-> Tabs: Personal | Professional | Settings
    |-> POST /auth/change-password -> Change password
    |-> PUT /settings -> Update preferences
```

### Profile View Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/profile/profile_screen.dart` | `ProfileScreen.initState()` | Calls `ApiService.getCurrentUser()` |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getCurrentUser()` | `GET /v1/users/me` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `UserMeView.get()` | Returns full user profile |
| 4 | **Database** | `horilla_auth_horillauser` | `SELECT` | User account data |
| 5 | **Database** | `employee_employee` | `SELECT` | Personal info (DOB, gender, address, etc.) |
| 6 | **Database** | `employee_employeeworkinformation` | `SELECT` | Professional info (department, designation, joining date) |
| 7 | **Database** | `user_settings` | `SELECT` | Theme, notification preferences, language |
| 8 | **Frontend** | `lib/screens/profile/profile_screen.dart` | Renders 3 tabs | Personal info, professional info, settings toggles |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `horilla_auth_horillauser` | `username`, `email`, `first_name`, `last_name` | Account info |
| `employee_employee` | `dob`, `gender`, `phone`, `address`, `emergency_contact`, etc. | Personal details |
| `employee_employeeworkinformation` | `department_id_id`, `job_position_id_id`, `date_joining`, `basic_salary` | Professional details |
| `user_settings` | `theme`, `notifications_enabled`, `biometric_enabled`, `language` | User preferences |

---

## 15. Org Chart

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Org Chart" -> [OrgChartScreen]
    |-> GET /org-chart -> Load hierarchy
```

### Org Chart Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/dashboard/org_chart_screen.dart` | `OrgChartScreen.initState()` | Calls `ApiService.get('/org-chart')` |
| 2 | **Backend** | `ppulse_backend/api/views.py` | `OrgChartView.get()` | Builds hierarchical tree from employee data |
| 3 | **Database** | `employee_employee` | `SELECT *` | All employees |
| 4 | **Database** | `employee_employeeworkinformation` | `SELECT *` | `reporting_manager_id_id` defines parent-child relationships |
| 5 | **Database** | `base_department` | `JOIN` | Department for each node |
| 6 | **Database** | `base_jobposition` | `JOIN` | Designation for each node |
| 7 | **Frontend** | `lib/screens/dashboard/org_chart_screen.dart` | Renders tree | Hierarchical organizational structure |

### Database Tables Involved
| Table | Fields Used | Purpose |
|-------|-------------|---------|
| `employee_employee` | `id`, `employee_first_name`, `employee_last_name`, `employee_profile` | Node identity |
| `employee_employeeworkinformation` | `reporting_manager_id_id`, `department_id_id`, `job_position_id_id` | Hierarchy + labels |
| `base_department` | `department` | Department label |
| `base_jobposition` | `job_position` | Designation label |

---

## 16. Manager/HR Analytics

### Flow Diagram
```
[DashboardScreen] -> Quick Action "Analytics" -> [AnalyticsScreen]
    |-> GET /dashboard/analytics -> Load org analytics
    |-> GET /dashboard/manager-stats -> Load manager stats
```

### Analytics Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/manager/analytics_screen.dart` | `AnalyticsScreen.initState()` | Calls analytics API |
| 2 | **Frontend** | `lib/services/api_service.dart` | `ApiService.getDashboardAnalytics()` | `GET /v1/dashboard/analytics` |
| 3 | **Backend** | `ppulse_backend/api/views.py` | `DashboardAnalyticsView.get()` | Aggregates org-wide data |
| 4 | **Database** | `employee_employee` | Total employee count, active/inactive | |
| 5 | **Database** | `attendance_attendance` | Attendance rates, late arrivals, WFH % | |
| 6 | **Database** | `leave_leaverequest` | Leave utilization across departments | |
| 7 | **Database** | `helpdesk_ticket` | Open tickets count | |
| 8 | **Database** | `base_department` | Department-wise breakdown | |
| 9 | **Frontend** | `lib/screens/manager/analytics_screen.dart` | Renders charts | Uses `fl_chart` for bar/pie/line charts |

### Manager Stats (Additional Endpoint)

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/dashboard/dashboard_screen.dart` | Manager section | Shows pending approvals count |
| 2 | **Backend** | `ppulse_backend/api/views.py` | `ManagerStatsView.get()` | Counts pending requests for manager's team |
| 3 | **Database** | Multiple request tables | `COUNT WHERE status='requested'` | Pending leaves, claims, tickets, etc. |

### Database Tables Involved
| Table | Purpose |
|-------|---------|
| `employee_employee` | Headcount, department distribution |
| `attendance_attendance` | Attendance metrics |
| `leave_leaverequest` | Leave utilization |
| `leave_availableleave` | Leave balance summaries |
| `helpdesk_ticket` | Open ticket metrics |
| `base_department` | Department grouping |

---

## 17. SSO Authentication (Microsoft & Google)

### Flow Diagram
```
[LoginScreen] -> Tap "Sign in with Microsoft"
    |-> POST /auth/microsoft/login (with redirect_uri)
    |-> Backend redirects to Microsoft OAuth
    |-> User authenticates at Microsoft
    |-> Microsoft redirects to /auth/microsoft/callback
    |-> Backend exchanges code for user info
    |-> Backend creates/matches user
    |-> Redirects to app with tokens: ppulse://auth-callback?access_token=X&refresh_token=Y
```

### Microsoft SSO Flow

| Step | Layer | File | Function/Class | Details |
|------|-------|------|----------------|---------|
| 1 | **Frontend** | `lib/screens/auth/login_screen.dart` | `_handleMicrosoftSSO()` | Opens browser with `redirect_uri=ppulse://auth-callback` |
| 2 | **Backend** | `ppulse_backend/api/sso_views.py` | `MicrosoftLoginView.get()` | Builds Microsoft OAuth2 authorization URL |
| 3 | **External** | Microsoft Identity Platform | User authenticates | Returns authorization code |
| 4 | **Backend** | `ppulse_backend/api/sso_views.py` | `MicrosoftCallbackView.get()` | Exchanges code for access token via Microsoft Graph API |
| 5 | **Backend** | `ppulse_backend/api/sso_views.py` | `MicrosoftCallbackView.get()` | Gets user profile from Microsoft Graph |
| 6 | **Database** | `horilla_auth_horillauser` | `get_or_create(email=ms_email)` | Creates user if not exists |
| 7 | **Database** | `employee_employee` | `get_or_create(employee_user_id_id=user.id)` | Creates employee if not exists |
| 8 | **Backend** | `ppulse_backend/api/sso_views.py` | Generates JWT tokens | Creates access + refresh tokens |
| 9 | **Frontend** | Deep link handler | `ppulse://auth-callback?access_token=X&refresh_token=Y` | App receives tokens via deep link |

---

## Complete Database Schema Summary

### All 19 Tables

| # | Table Name | Model Class | Primary Purpose |
|---|-----------|-------------|-----------------|
| 1 | `horilla_auth_horillauser` | `User` | User authentication & account |
| 2 | `employee_employee` | `Employee` | Employee personal information |
| 3 | `employee_employeeworkinformation` | `EmployeeWorkInformation` | Work details, department, manager |
| 4 | `base_department` | `Department` | Department master data |
| 5 | `base_jobposition` | `JobPosition` | Job position/designation master |
| 6 | `base_employeeshift` | `Shift` | Shift definitions |
| 7 | `base_worktype` | `WorkType` | Work type definitions (WFH, On-site) |
| 8 | `attendance_attendance` | `Attendance` | Daily attendance records |
| 9 | `attendance_permission_request` | `AttendanceRequest` | Attendance correction requests |
| 10 | `leave_leavetype` | `LeaveType` | Leave type master data |
| 11 | `leave_availableleave` | `AvailableLeave` | Leave balance per employee |
| 12 | `leave_leaverequest` | `LeaveRequest` | Leave applications |
| 13 | `helpdesk_ticket` | `Ticket` | Support tickets & claim tickets |
| 14 | `helpdesk_tickettype` | `TicketType` | Ticket categories |
| 15 | `helpdesk_claimrequest` | `ClaimRequest` | Expense claims |
| 16 | `base_shiftrequest` | `ShiftRequest` | Shift change requests |
| 17 | `base_worktyperequest` | `WorkTypeRequest` | Work type change requests |
| 18 | `asset_assetrequest` | `AssetRequest` | Asset allocation requests |
| 19 | `payroll_payslip` | `Payslip` | Monthly payslips |
| 20 | `notifications_notification` | `Notification` | In-app notifications |
| 21 | `base_announcement` | `Announcement` | Company announcements |
| 22 | `device_token` | `DeviceToken` | FCM push notification tokens |
| 23 | `user_settings` | `UserSettings` | User preferences |

---

## Role-Based Access Matrix

| Feature | Employee | Manager | HR |
|---------|----------|---------|-----|
| Dashboard | Own data | Own + team stats | Org-wide stats |
| Attendance (view) | Own | Own + team | All employees |
| Attendance (punch) | Yes | Yes | Yes |
| Leave (apply) | Yes | Yes | Yes |
| Leave (approve) | No | Team only | All |
| Claims (submit) | Yes | Yes | Yes |
| Claims (approve) | No | Team only | All |
| Tickets (raise) | Yes | Yes | Yes |
| Tickets (close) | No | Team only | All |
| Requests (view) | Own | Own + team | All |
| Requests (approve) | No | Team only | All |
| Payslips | Own | Own | All |
| Directory | View only | View + profiles | Full access |
| Analytics | No | Team analytics | Org analytics |
| Org Chart | View | View | View + edit |
| Settings | Own | Own | Own |

### How Roles Are Determined
```
if user.is_staff == True:
    role = "hr"
elif EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).exists():
    role = "manager"
else:
    role = "employee"
```

---

## Token Refresh Flow (Background)

```
[Any API Call] -> 401 Unauthorized
    |-> ApiService._tryRefreshToken()
        |-> POST /v1/auth/refresh {refresh_token: "..."}
        |-> Backend: RefreshTokenView validates refresh token
        |-> Returns new access_token
        |-> Stores new token in SharedPreferences
        |-> Retries original request with new token
    |-> If refresh also fails -> Logout user -> LoginScreen
```

---

*Generated on 2026-04-02 | PPulse HRMS Full Stack Analysis*
