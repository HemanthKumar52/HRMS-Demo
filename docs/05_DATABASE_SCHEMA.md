# PPULSE HRMS — Database Schema Documentation

**Engine:** PostgreSQL 16
**Models:** 38 tables
**ORM:** Django 6.0

---

## Core Tables

### auth_user (Custom User Model)
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| username | VARCHAR(150) | Unique, indexed |
| password | VARCHAR(128) | PBKDF2-SHA256 hash |
| email | VARCHAR(254) | |
| is_superuser | BOOLEAN | Admin flag |
| is_staff | BOOLEAN | HR flag |
| is_active | BOOLEAN | Account enabled |
| token_version | INTEGER | For forced JWT invalidation |
| failed_login_count | INTEGER | Lockout counter |
| locked_until | DATETIME | Lockout expiry |

### api_employee
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| employee_user_id_id | BigInteger | FK → auth_user |
| employee_first_name | TEXT | |
| employee_last_name | TEXT | |
| email | TEXT | |
| phone | TEXT | |
| badge_id | TEXT | e.g. EMP002 |
| gender | TEXT | |
| is_active | BOOLEAN | |

### api_employeeworkinformation
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| employee_id_id | BigInteger | FK → api_employee |
| department_id_id | BigInteger | FK → api_department |
| job_position_id | BigInteger | FK → job_position |
| reporting_manager_id_id | BigInteger | FK → api_employee (self-ref) |
| work_type | TEXT | office/remote/hybrid |
| shift_id | BigInteger | FK → shift |
| date_joining | DATE | |

### api_attendance
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| employee_id_id | BigInteger | FK → api_employee, indexed |
| attendance_date | DATE | Indexed with employee_id |
| attendance_clock_in | TIME | |
| attendance_clock_out | TIME | |
| at_work_second | INTEGER | Computed duration |
| punch_in_lat | FLOAT | GPS latitude |
| punch_in_lng | FLOAT | GPS longitude |
| punch_in_location | VARCHAR(255) | Reverse-geocoded name |
| punch_in_source | VARCHAR(20) | mobile/biometric |
| punch_out_lat | FLOAT | |
| punch_out_lng | FLOAT | |
| punch_out_location | VARCHAR(255) | |
| punch_out_source | VARCHAR(20) | |
| device_info | TEXT | |

### employee_face_data
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| employee_id_id | BigInteger | Unique FK → api_employee |
| embedding | BYTEA | 2048 bytes (512 x float32) |
| embedding_dim | INTEGER | 512 |
| num_samples | INTEGER | Count of averaged images |
| source_files | TEXT | Comma-separated paths |
| created_at | DATETIME | |
| updated_at | DATETIME | |

### api_auditlog
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| action | VARCHAR(100) | e.g. request_approved, face_punch_in_succeeded |
| actor_id | BigInteger | FK → auth_user |
| actor_name | VARCHAR(200) | Denormalized for read speed |
| actor_role | VARCHAR(20) | admin/hr/employee |
| target_type | VARCHAR(100) | Model name |
| target_id | BigInteger | |
| target_name | VARCHAR(200) | |
| payload | JSONB | Arbitrary metadata |
| ip_address | VARCHAR(45) | IPv4/IPv6 |
| user_agent | TEXT | |
| created_at | DATETIME | Indexed |

---

## Request Tables

All request types share a similar structure:

### api_leaverequest
| Column | Type | Notes |
|--------|------|-------|
| id | BigAutoField | PK |
| employee_id_id | BigInteger | FK → api_employee |
| leave_type_id_id | BigInteger | FK → api_leavetype |
| start_date | DATE | |
| end_date | DATE | |
| description | TEXT | |
| status | TEXT | requested/approved/rejected/cancelled |
| created_at | DATETIME | |
| attachment | TEXT | File path |

Similar tables: `api_claimrequest`, `api_ticket`, `api_shiftrequest`, `api_worktyperequest`, `api_attendancerequest`, `api_assetrequest`

---

## Configuration Tables

| Table | Purpose |
|-------|---------|
| api_department | Departments (Engineering, HR, Finance, etc.) |
| api_leavetype | Leave types (Casual, Sick, Earned, LOP) |
| api_availableleave | Per-employee leave balances |
| api_geofence | Office geofence coordinates + radius |
| api_holiday | Company holidays |
| api_emailtemplate | Notification email templates |
| api_webhook | External webhook integrations |
| api_allowedip | IP allowlist for API access |
| api_loginrecord | Login history for security audit |
| api_retentionpolicy | GDPR data retention rules |
| api_userconsent | GDPR consent tracking |

---

## Entity Relationship Summary

```
User ←1:1→ Employee ←1:N→ Attendance
                     ←1:1→ EmployeeFaceData
                     ←1:N→ LeaveRequest
                     ←1:N→ ClaimRequest
                     ←1:N→ Ticket
                     ←1:N→ ShiftRequest
                     ←1:N→ WorkTypeRequest
                     ←1:N→ AttendanceRequest
                     ←1:N→ AssetRequest
                     ←1:N→ Notification
                     ←1:N→ Payslip

EmployeeWorkInformation.reporting_manager → Employee (org hierarchy)
Department ←1:N→ EmployeeWorkInformation
```

---

**38 tables total** | PostgreSQL 16 | Django ORM with managed migrations
