# PPulse HRMS - Mobile App API to Database Mapping

**Database:** PostgreSQL  
**DB Name:** `kaaspro_hrms_local` | **Host:** `localhost` | **Port:** `5432` | **User:** `postgres` | **Password:** `admin`

---

## Authentication

| App Action | API Endpoint | Method | DB Table | Operation |
|---|---|---|---|---|
| Login | `/v1/auth/login` | POST | `horilla_auth_horillauser` | READ - validates username & hashed password |
| Token Refresh | `/v1/auth/refresh` | POST | `horilla_auth_horillauser` | READ - validates refresh token against user |
| Logout | `/v1/auth/logout` | POST | — | Blacklists JWT token (in-memory) |
| Change Password | `/v1/auth/change-password` | POST | `horilla_auth_horillauser` | UPDATE - updates password hash |

---

## User Profile

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Get Profile | `/v1/users/me` | GET | `horilla_auth_horillauser` → `employee_employee` → `employee_employeeworkinformation` → `base_department` → `base_jobposition` → `base_employeeshift` → `base_worktype` | READ - joins user, employee, work info, dept, position, shift, work type |
| Upload Avatar | `/v1/users/me/avatar` | POST | `employee_employee` | UPDATE - saves avatar file path |

---

## Attendance

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Punch In | `/v1/attendance/punch-in` | POST | `attendance_attendance` | CREATE - new row with check_in time |
| Punch Out | `/v1/attendance/punch-out` | POST | `attendance_attendance` | UPDATE - sets check_out time on today's record |
| Today's Status | `/v1/attendance/today` | GET | `attendance_attendance` | READ - filter by employee + today's date |
| Monthly Summary | `/v1/attendance/monthly` | GET | `attendance_attendance` | READ - filter by employee + month/year |
| Weekly Summary | `/v1/attendance/weekly` | GET | `attendance_attendance` | READ - filter by employee + current week |
| Team Attendance | `/v1/attendance/team` | GET | `attendance_attendance` + `employee_employeeworkinformation` | READ - joins attendance with team members via reporting_manager |
| Attendance Regularize | `/v1/attendance/regularize` | POST | `attendance_permission_request` + `notifications_notification` | CREATE - new attendance request + notification to manager |

---

## Leave Management

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Get Leave Balance | `/v1/leaves/balance` | GET | `leave_availableleave` + `leave_leavetype` | READ - joins available leaves with leave types for employee |
| Apply Leave | `/v1/leaves/apply` | POST | `leave_leaverequest` + `leave_availableleave` + `notifications_notification` | CREATE - new leave request, UPDATE - deducts from available balance, CREATE - notification to manager |

---

## Claims & Tickets

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Submit Claim | `/v1/claims/submit` | POST | `helpdesk_claimrequest` + `notifications_notification` | CREATE - new claim record + notification |
| Raise Ticket | `/v1/tickets/raise` | POST | `helpdesk_ticket` + `notifications_notification` | CREATE - new ticket record + notification |

---

## Shift & Work Type Requests

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Shift Change Request | `/v1/shifts/request` | POST | `base_shiftrequest` + `notifications_notification` | CREATE - new shift request + notification |
| Work Type Request | `/v1/work-type/request` | POST | `base_worktyperequest` + `notifications_notification` | CREATE - new work type request + notification |

---

## Asset Requests

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Asset Request | `/v1/assets/request` | POST | `asset_assetrequest` + `notifications_notification` | CREATE - new asset request + notification |

---

## Requests Management (All Types)

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| List All Requests | `/v1/requests` | GET | `leave_leaverequest` + `helpdesk_claimrequest` + `helpdesk_ticket` + `base_shiftrequest` + `base_worktyperequest` + `attendance_permission_request` + `asset_assetrequest` | READ - queries all 7 request tables, merges & sorts by date |
| Request Detail | `/v1/requests/<id>` | GET | Same as above (finds by ID across all tables) | READ |
| Accept Request | `/v1/requests/<id>/accept` | PUT | Matching request table + `notifications_notification` | UPDATE - sets status to 'approved' + CREATE notification to employee |
| Reject Request | `/v1/requests/<id>/reject` | PUT | Matching request table + `notifications_notification` | UPDATE - sets status to 'rejected' + CREATE notification to employee |
| Cancel Request | `/v1/requests/<id>/cancel` | PUT | Matching request table | UPDATE - sets status to 'cancelled' |

---

## Payslips

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Get Payslips | `/v1/payslips` | GET | `payroll_payslip` | READ - filter by employee + month/year |
| List All Payslips | `/v1/payslips/list` | GET | `payroll_payslip` | READ - all payslips for employee |
| Download PDF | `/v1/payslips/<id>/pdf` | GET | `payroll_payslip` + `employee_employee` + `employee_employeeworkinformation` | READ - generates PDF from payslip + employee data |

---

## Notifications

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Get Notifications | `/v1/notifications` | GET | `notifications_notification` | READ - filter by recipient user, ordered by timestamp desc |
| Mark as Read | `/v1/notifications/<id>/read` | PUT | `notifications_notification` | UPDATE - sets is_read = true |
| Mark All Read | `/v1/notifications/read-all` | PUT | `notifications_notification` | UPDATE - bulk sets is_read = true for all user's notifications |
| Register Device | `/v1/notifications/register-device` | POST | `device_token` | CREATE/UPDATE - stores FCM token for push notifications |

---

## Employees Directory

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| List Employees | `/v1/employees` | GET | `employee_employee` + `employee_employeeworkinformation` + `base_department` + `base_jobposition` | READ - joins employee with work info, dept, position |
| Employee Detail | `/v1/employees/<id>` | GET | Same as above | READ - single employee full details |

---

## Dashboard

| App Action | API Endpoint | Method | DB Table(s) | Operation |
|---|---|---|---|---|
| Dashboard Summary | `/v1/dashboard/summary` | GET | `attendance_attendance` + `leave_leaverequest` + `leave_availableleave` + all request tables | READ - aggregates today's attendance, pending requests, leave balance |
| Announcements | `/v1/dashboard/announcements` | GET | `base_announcement` | READ - active announcements |
| Analytics | `/v1/dashboard/analytics` | GET | `employee_employee` + `employee_employeeworkinformation` + `base_department` + `leave_availableleave` | READ - employee counts by dept, leave utilization |
| Manager Stats | `/v1/dashboard/manager-stats` | GET | `attendance_attendance` + `employee_employeeworkinformation` + `leave_availableleave` | READ - team attendance rate, avg hours, leave utilization |
| Org Chart | `/v1/org-chart` | GET | `employee_employee` + `employee_employeeworkinformation` | READ - recursive hierarchy via reporting_manager_id |

---

## Reference Data (Dropdowns)

| App Action | API Endpoint | Method | DB Table | Operation |
|---|---|---|---|---|
| Departments | `/v1/departments` | GET | `base_department` | READ |
| Shifts | `/v1/shifts` | GET | `base_employeeshift` | READ |
| Work Types | `/v1/work-types` | GET | `base_worktype` | READ |
| Leave Types | `/v1/leave-types` | GET | `leave_leavetype` | READ |

---

## Settings

| App Action | API Endpoint | Method | DB Table | Operation |
|---|---|---|---|---|
| Get/Update Settings | `/v1/settings` | GET/PUT | `user_settings` | READ/UPDATE - theme, language preferences |

---

## Complete Table Reference

| # | DB Table | Purpose |
|---|---|---|
| 1 | `horilla_auth_horillauser` | User accounts (login, password, roles) |
| 2 | `employee_employee` | Employee master data (name, phone, DOB, avatar) |
| 3 | `employee_employeeworkinformation` | Work details (dept, position, shift, manager, salary) |
| 4 | `base_department` | Department master |
| 5 | `base_jobposition` | Job position/designation master |
| 6 | `base_employeeshift` | Shift definitions |
| 7 | `base_worktype` | Work type definitions (WFH, Office, etc.) |
| 8 | `leave_leavetype` | Leave type definitions (Casual, Sick, etc.) |
| 9 | `leave_availableleave` | Employee leave balances per type |
| 10 | `leave_leaverequest` | Leave applications |
| 11 | `attendance_attendance` | Daily attendance records (check-in/out) |
| 12 | `attendance_permission_request` | Attendance regularization requests |
| 13 | `helpdesk_ticket` | Support tickets |
| 14 | `helpdesk_tickettype` | Ticket type definitions |
| 15 | `helpdesk_claimrequest` | Expense claim requests |
| 16 | `base_shiftrequest` | Shift change requests |
| 17 | `base_worktyperequest` | Work type change requests |
| 18 | `asset_assetrequest` | Asset requests |
| 19 | `payroll_payslip` | Monthly payslips |
| 20 | `notifications_notification` | In-app notifications |
| 21 | `base_announcement` | Company announcements |
| 22 | `device_token` | FCM device tokens for push notifications |
| 23 | `user_settings` | User preferences (theme, language) |
