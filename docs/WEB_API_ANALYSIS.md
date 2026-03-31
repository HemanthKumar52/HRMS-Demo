# PPulse HRMS Web Application - DRF API Analysis

> Generated: 2026-03-31 | Source: `/ppulse-web/` (Horilla HRMS)

---

## Executive Summary

**YES - The web application has a comprehensive Django REST Framework (DRF) API layer.**

| Metric | Value |
|--------|-------|
| DRF Imports | 91 files |
| API Modules | 9 (auth, base, employee, attendance, leave, payroll, asset, biometric, notifications) |
| APIView Classes | 40+ |
| Serializer Classes | 50+ |
| Total API Endpoints | **158+** |
| ViewSet Classes | 4 (payroll module) |
| Authentication | JWT (SimpleJWT, 30-day tokens) |
| Documentation | Swagger/OpenAPI via drf-yasg |
| Pagination | PageNumberPagination (20/page) |
| Filtering | DjangoFilterBackend |
| CORS | django-cors-headers |

---

## DRF Configuration

**File:** `ppulse-web/horilla/settings/base.py`

```python
INSTALLED_APPS = [
    "rest_framework",              # DRF core
    "rest_framework_simplejwt",    # JWT authentication
    "rest_framework.authtoken",    # Token authentication
    "drf_yasg",                    # Swagger docs
    "corsheaders",                 # CORS support
    "django_filters",              # API filtering
]

REST_FRAMEWORK = {
    "DEFAULT_FILTER_BACKENDS": ["django_filters.rest_framework.DjangoFilterBackend"],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "PAGE_SIZE": 20,
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(days=30),
}
```

**requirements.txt packages:**
- `djangorestframework`
- `djangorestframework-simplejwt`
- `drf-yasg`
- `django-filter`
- `django-cors-headers`

---

## API Directory Structure

```
ppulse-web/horilla_api/
├── urls.py                       # Root API routing
├── apps.py                       # Auto-registers at /api/
├── api_views/                    # View classes (8 modules)
│   ├── auth/views.py
│   ├── base/views.py
│   ├── employee/views.py
│   ├── attendance/views.py
│   ├── leave/views.py
│   ├── payroll/views.py
│   ├── asset/views.py
│   └── notifications/views.py
├── api_serializers/              # Serializers (8 modules)
│   ├── auth/serializers.py
│   ├── base/serializers.py
│   ├── employee/serializers.py
│   ├── attendance/serializers.py
│   ├── leave/serializers.py
│   ├── payroll/serializers.py
│   ├── asset/serializers.py
│   └── notifications/serializers.py
├── api_urls/                     # URL patterns (9 modules)
│   ├── auth/urls.py
│   ├── base/urls.py
│   ├── employee/urls.py
│   ├── attendance/urls.py
│   ├── leave/urls.py
│   ├── payroll/urls.py
│   ├── asset/urls.py
│   ├── biometric/urls.py
│   └── notifications/urls.py
├── api_decorators/               # Custom permission decorators
├── api_filters/                  # DRF filter backends
└── api_methods/                  # Utility methods
```

---

## Complete API Endpoints

### AUTH (`/api/auth/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| POST | `login/` | LoginAPIView | JWT login, returns access + refresh tokens |

### EMPLOYEE (`/api/employee/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET | `employees/<pk>/` | EmployeeAPIView | Get employee detail |
| POST | `employees/<pk>/` | EmployeeAPIView | Create employee |
| PUT | `employees/<pk>/` | EmployeeAPIView | Update employee |
| DELETE | `employees/<pk>/` | EmployeeAPIView | Delete employee |
| GET | `list/employees/` | EmployeeListAPIView | List all employees (paginated, searchable) |
| GET | `employee-type/` | EmployeeTypeAPIView | List employee types |
| GET/POST | `employee-work-information/` | EmployeeWorkInformationAPIView | Work info CRUD |
| GET/PUT | `employee-work-information/<pk>/` | EmployeeWorkInformationAPIView | Work info detail |
| GET/POST | `employee-bank-details/<pk>/` | EmployeeBankDetailsAPIView | Bank details CRUD |
| GET/POST | `disciplinary-action/` | DisciplinaryActionAPIView | Disciplinary actions |
| GET/POST | `policies/` | PolicyAPIView | Policy management |
| GET/POST | `document-request/` | DocumentRequestAPIView | Document requests |
| GET/POST | `documents/` | DocumentAPIView | Document management |
| PUT | `employee-archive/<id>/<is_active>/` | EmployeeArchiveView | Archive/restore |
| POST | `employee-bulk-update/` | EmployeeBulkUpdateView | Bulk update |
| GET | `employee-work-info-export/` | EmployeeWorkInfoExportView | Export to Excel |
| POST | `employee-work-info-import/` | EmployeeWorkInfoImportView | Import from Excel |
| GET | `employee-selector/` | EmployeeSelectorView | Employee dropdown data |
| GET | `manager-check/` | ReportingManagerCheck | Check if user is manager |

### ATTENDANCE (`/api/attendance/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| POST | `clock-in/` | ClockInAPIView | Employee clock in |
| POST | `clock-out/` | ClockOutAPIView | Employee clock out |
| GET/POST | `attendance/` | AttendanceView | Attendance records CRUD |
| GET/PUT/DELETE | `attendance/<pk>` | AttendanceView | Single attendance |
| GET | `attendance/list/<type>` | AttendanceView | Filter by type (ot/validated) |
| PUT | `attendance-validate/<pk>` | ValidateAttendanceView | Mark as validated |
| GET/POST | `attendance-request/` | AttendanceRequestView | Attendance requests |
| PUT | `attendance-request-approve/<pk>` | AttendanceRequestApproveView | Approve request |
| PUT | `attendance-request-cancel/<pk>` | AttendanceRequestCancelView | Cancel request |
| PUT | `overtime-approve/<pk>` | OvertimeApproveView | Approve overtime |
| GET | `attendance-hour-account/` | AttendanceOverTimeView | Overtime accounts |
| GET | `late-come-early-out-view/` | LateComeEarlyOutView | Late/early records |
| GET | `attendance-activity/` | AttendanceActivityView | Activity logs |
| GET | `today-attendance/` | TodayAttendance | Today's summary |
| GET | `my-attendance/` | UserAttendanceView | Own attendance |
| GET | `my-attendance-detailed/<id>/` | UserAttendanceDetailedView | Detailed view |
| GET | `offline-employees/count/` | OfflineEmployeesCountView | Offline count |
| GET | `offline-employees/list/` | OfflineEmployeesListView | Offline list |
| POST | `offline-employee-mail-send` | OfflineEmployeeMailsend | Send reminder |

### LEAVE (`/api/leave/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET | `available-leave/` | EmployeeAvailableLeaveGetAPIView | Leave balance |
| GET/POST | `user-request/` | EmployeeLeaveRequestGetCreateAPIView | My leave requests |
| GET/PUT/DELETE | `user-request/<pk>/` | EmployeeLeaveRequestUpdateDeleteAPIView | Single request |
| GET/POST | `leave-type/` | LeaveTypeGetCreateAPIView | Leave types |
| GET/PUT/DELETE | `leave-type/<pk>/` | LeaveTypeGetUpdateDeleteAPIView | Single type |
| GET/POST | `allocation-request/` | LeaveAllocationRequestGetCreateAPIView | Allocation requests |
| GET/PUT/DELETE | `allocation-request/<pk>/` | LeaveAllocationRequestGetUpdateDeleteAPIView | Single allocation |
| GET/POST | `assign-leave/` | AssignLeaveGetCreateAPIView | Assign leaves |
| GET/POST | `request/` | LeaveRequestGetCreateAPIView | All leave requests |
| GET/POST | `company-leave/` | CompanyLeaveGetCreateAPIView | Company leaves |
| GET/POST | `holiday/` | HolidayGetCreateAPIView | Holidays |
| PUT | `approve/<pk>/` | LeaveRequestApproveAPIView | Approve |
| PUT | `reject/<pk>/` | LeaveRequestRejectAPIView | Reject |
| PUT | `cancel/<pk>/` | LeaveRequestCancelAPIView | Cancel |
| PUT | `allocation-approve/<pk>/` | LeaveAllocationApproveAPIView | Approve allocation |
| PUT | `allocation-reject/<pk>/` | LeaveAllocationRequestRejectAPIView | Reject allocation |
| POST | `request-bulk-action/` | LeaveRequestBulkApproveDeleteAPIview | Bulk actions |
| GET | `status/` | LeaveRequestedApprovedCountAPIView | Status counts |

### PAYROLL (`/api/payroll/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET/POST | `contract/` | ContractView | Contracts CRUD |
| GET/PUT/DELETE | `contract/<id>` | ContractView | Single contract |
| GET | `payslip/` | PayslipView | List payslips |
| GET | `payslip/<id>` | PayslipView | Single payslip |
| GET | `payslip-download/<id>` | PayslipDownloadView | Download PDF |
| POST | `payslip-send-mail/` | PayslipSendMailView | Email payslip |
| GET/POST | `loan-account/` | LoanAccountView | Loan accounts |
| GET/PUT/DELETE | `loan-account/<pk>` | LoanAccountView | Single loan |
| GET/POST | `reimbusement/` | ReimbursementView | Reimbursements |
| PUT | `reimbusement-approve-reject/<pk>` | ReimbusementApproveRejectView | Approve/reject |
| GET/POST | `tax-bracket/` | TaxBracketView | Tax brackets |
| GET/POST | `allowance` | AllowanceView | Allowances |
| GET/POST | `deduction` | DeductionView | Deductions |

**Payroll Periods (ViewSet with Router):**

| Method | Endpoint | Action | Purpose |
|--------|----------|--------|---------|
| GET | `periods/` | list | List payroll periods |
| POST | `periods/` | create | Create period |
| GET | `periods/<id>/` | retrieve | Get period detail |
| PUT | `periods/<id>/` | update | Update period |
| DELETE | `periods/<id>/` | destroy | Delete period |
| POST | `periods/<id>/transition-status/` | @action | Workflow status transition |
| GET | `periods/<id>/workflow-history/` | @action | Get workflow history |
| POST | `periods/<id>/add-comment/` | @action | Add comment |
| GET | `payroll-data/` | list | List payroll data |
| GET | `employees/` | list | Employees for payroll |
| GET | `dashboard/` | list | Dashboard data |

### ASSET (`/api/asset/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET/POST | `assets/` | AssetAPIView | Assets CRUD |
| GET/PUT/DELETE | `assets/<pk>` | AssetAPIView | Single asset |
| GET/POST | `asset-categories/` | AssetCategoryAPIView | Categories |
| GET/POST | `asset-lots/` | AssetLotAPIView | Asset lots |
| GET/POST | `asset-allocations/` | AssetAllocationAPIView | Allocations |
| GET/POST | `asset-requests/` | AssetRequestAPIView | Asset requests |
| PUT | `asset-return/<pk>` | AssetReturnAPIView | Return asset |
| PUT | `asset-approve/<pk>` | AssetApproveAPIView | Approve request |
| PUT | `asset-reject/<pk>` | AssetRejectAPIView | Reject request |

### BASE (`/api/base/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET/POST | `companies/` | CompanyView | Companies |
| GET/POST | `departments/` | DepartmentView | Departments |
| GET/POST | `job-positions/` | JobPositionView | Job positions |
| GET/POST | `job-roles/` | JobRoleView | Job roles |
| GET/POST | `worktypes/` | WorkTypeView | Work types |
| GET/POST | `employee-shift/` | EmployeeShiftView | Shifts |
| GET/POST | `employee-shift-schedules/` | EmployeeShiftScheduleView | Schedules |
| GET/POST | `rotating-worktypes/` | RotatingWorkTypeView | Rotating work types |
| GET/POST | `rotating-worktype-assigns/` | RotatingWorkTypeAssignView | Assignments |
| GET/POST | `rotating-shifts/` | RotatingShiftView | Rotating shifts |
| GET/POST | `rotating-shift-assigns/` | RotatingShiftAssignView | Shift assignments |
| GET/POST | `shift-requests/` | ShiftRequestView | Shift requests |
| GET/POST | `worktype-requests/` | WorkTypeRequestView | Work type requests |
| PUT | `shift-request-approve/<pk>` | ShiftRequestApproveView | Approve shift |
| PUT | `shift-request-cancel/<pk>` | ShiftRequestCancelView | Cancel shift |
| PUT | `worktype-requests-approve/<pk>/` | WorkRequestApproveView | Approve work type |
| PUT | `worktype-requests-cancel/<pk>/` | WorkTypeRequestCancelView | Cancel work type |

### NOTIFICATIONS (`/api/notifications/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET | `notifications/list/<type>` | NotificationView | List (all/unread) |
| POST | `notifications/<id>/` | NotificationReadDelView | Mark as read |
| DELETE | `notifications/<id>/` | NotificationReadDelView | Delete notification |
| POST | `notifications/bulk-read/` | NotificationBulkReadDelView | Mark all read |
| DELETE | `notifications/bulk-delete/` | NotificationBulkReadDelView | Delete all |

### BIOMETRIC (`/api/biometric/`)

| Method | Endpoint | View | Purpose |
|--------|----------|------|---------|
| GET | `health/` | BiometricHealthCheckView | Health check |
| POST | `sync-attendance/` | BiometricSyncAttendanceView | Sync attendance |
| POST | `sync-users/` | BiometricSyncUsersView | Sync users |
| POST | `register-device/` | BiometricDeviceRegisterView | Register device |

---

## Authentication & Permissions

### JWT Authentication Flow
```
1. POST /api/auth/login/  { "username": "x", "password": "y" }
2. Response: { "access_token": "eyJ...", "refresh_token": "eyJ..." }
3. All subsequent requests: Authorization: Bearer <access_token>
4. Token lifetime: 30 days
```

### Permission Decorators
| Decorator | Purpose |
|-----------|---------|
| `@permission_required(perm)` | Check Django permission |
| `@manager_permission_required(perm)` | Check manager-level access |
| `@manager_or_owner_permission_required(model, perm)` | Manager OR owner of record |
| `@check_approval_status(model, perm)` | Verify not already approved |

### Custom Permission Classes
- `ManagerPermission(BasePermission)` - Manager-level access check
- `IsAuthenticated` - Default on all endpoints

---

## Mobile App vs Web API Comparison

### What Our Mobile Backend Uses vs What's Already Available

| Mobile Backend (`ppulse_backend/`) | Web DRF API (`horilla_api/`) | Can Use Web API? |
|-----------------------------------|------------------------------|------------------|
| `POST /v1/auth/login` | `POST /api/auth/login/` | YES - identical |
| `POST /v1/attendance/punch-in` | `POST /api/attendance/clock-in/` | YES |
| `POST /v1/attendance/punch-out` | `POST /api/attendance/clock-out/` | YES |
| `GET /v1/attendance/monthly` | `GET /api/attendance/my-attendance/` | YES |
| `GET /v1/attendance/today` | `GET /api/attendance/today-attendance/` | YES |
| `GET /v1/leaves/balance` | `GET /api/leave/available-leave/` | YES |
| `POST /v1/leaves/apply` | `POST /api/leave/user-request/` | YES |
| `GET /v1/employees` | `GET /api/employee/list/employees/` | YES |
| `GET /v1/payslips` | `GET /api/payroll/payslip/` | YES |
| `GET /v1/notifications` | `GET /api/notifications/notifications/list/all` | YES |
| `GET /v1/departments` | `GET /api/base/departments/` | YES |
| `POST /v1/shifts/request` | `POST /api/base/shift-requests/` | YES |
| `POST /v1/work-type/request` | `POST /api/base/worktype-requests/` | YES |
| `POST /v1/assets/request` | `POST /api/asset/asset-requests/` | YES |
| `GET /v1/dashboard/summary` | No direct equivalent | NO - custom view |
| `POST /v1/claims/submit` | No direct equivalent | NO - custom view |
| `POST /v1/tickets/raise` | No direct equivalent | NO - custom view |

### Key Insight

**The mobile app could potentially use the existing Horilla DRF API directly** instead of the custom `ppulse_backend/` Django app. The web API has 158+ endpoints covering far more functionality than our 35 mobile endpoints. The main gaps are:
1. Dashboard summary (combined endpoint) - would need to aggregate from multiple web endpoints
2. Claims submission - not in web API
3. Ticket creation - not in web API

### Recommendation

If you want to unify the mobile and web backends:
1. Point the mobile app's `ApiService` to the web app's `/api/` endpoints
2. Create 2-3 custom views for the missing dashboard/claims/tickets endpoints
3. Remove the separate `ppulse_backend/` entirely

---

## Swagger Documentation

The web app includes `drf-yasg` for auto-generated Swagger documentation:

```python
SWAGGER_SETTINGS = {
    "SECURITY_DEFINITIONS": {
        "Bearer": {
            "type": "apiKey",
            "name": "Authorization",
            "in": "header",
        },
        "Basic": {"type": "basic"},
    },
}
```

Access Swagger UI at: `http://localhost:8000/api/docs/` (when web app is running)

---

## DRF Best Practices Used

| Practice | Status |
|----------|--------|
| Separation of concerns (views/serializers/urls) | YES |
| JWT Authentication | YES |
| Permission classes | YES |
| Pagination | YES (20/page) |
| Filtering (DjangoFilterBackend) | YES |
| API Documentation (Swagger) | YES |
| Serializer validation | YES |
| ViewSet + Router (payroll) | YES |
| Custom decorators | YES |
| Atomic transactions (payroll) | YES |
| CORS headers | YES |
| Error handling with status codes | YES |

## Not Implemented

| Feature | Status |
|---------|--------|
| API versioning | NOT IMPLEMENTED |
| Rate limiting / throttling | NOT IMPLEMENTED |
| Response caching | NOT IMPLEMENTED |
| Nested serializers | MINIMAL |
| Hypermedia (HATEOAS) | NOT IMPLEMENTED |
