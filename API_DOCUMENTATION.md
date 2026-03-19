# PPulse HRMS - API Documentation

> Functional API endpoints required for the PPulse HRMS backend.

---

## Overview

| Item             | Value                          |
|------------------|--------------------------------|
| Base URL         | `https://api.ppulse.com/v1`    |
| Auth             | Bearer Token (JWT)             |
| Content-Type     | `application/json`             |
| File Uploads     | `multipart/form-data`          |
| Roles            | `employee`, `manager`, `hr`    |

### Common Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Pagination (for list endpoints)

```
?page=1&limit=20&sort=created_at&order=desc
```

---

## 1. Authentication

### 1.1 POST `/auth/login`

Authenticate user and receive JWT tokens.

**Request:**
```json
{
  "username": "string",
  "password": "string",
  "device_id": "string",
  "fcm_token": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "integer",
  "user": {
    "id": "uuid",
    "employee_id": "string",
    "name": "string",
    "email": "string",
    "role": "employee | manager | hr",
    "designation": "string",
    "department": "string",
    "avatar_url": "string | null"
  }
}
```

---

### 1.2 POST `/auth/refresh`

Refresh an expired access token.

**Request:**
```json
{
  "refresh_token": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "integer"
}
```

---

### 1.3 POST `/auth/logout`

Invalidate tokens and unregister FCM token.

**Request:**
```json
{
  "fcm_token": "string"
}
```

---

### 1.4 POST `/auth/change-password`

**Request:**
```json
{
  "current_password": "string",
  "new_password": "string"
}
```

---

## 2. User & Profile

### 2.1 GET `/users/me`

Get authenticated user's full profile.

**Response:**
```json
{
  "id": "uuid",
  "employee_id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "employee | manager | hr",
  "designation": "string",
  "department": "string",
  "date_of_joining": "date",
  "reporting_manager": {
    "id": "uuid",
    "name": "string",
    "employee_id": "string"
  },
  "avatar_url": "string | null",
  "created_at": "datetime"
}
```

---

### 2.2 PUT `/users/me`

Update profile details.

**Request:**
```json
{
  "name": "string",
  "phone": "string"
}
```

---

### 2.3 POST `/users/me/avatar`

Upload profile picture. **Content-Type: multipart/form-data**

**Request:**
```
file: <image_file>
```

**Response:**
```json
{
  "avatar_url": "string"
}
```

---

## 3. Attendance

### 3.1 POST `/attendance/punch-in`

Clock in for the day.

**Request:**
```json
{
  "latitude": "double",
  "longitude": "double",
  "method": "biometric | face | password"
}
```

**Response:**
```json
{
  "id": "uuid",
  "employee_id": "string",
  "punch_in": "datetime",
  "punch_out": "datetime | null",
  "status": "checked_in",
  "method": "string"
}
```

---

### 3.2 POST `/attendance/punch-out`

Clock out for the day.

**Request:**
```json
{
  "latitude": "double",
  "longitude": "double"
}
```

**Response:**
```json
{
  "id": "uuid",
  "punch_in": "datetime",
  "punch_out": "datetime",
  "total_hours": "string",
  "status": "checked_out"
}
```

---

### 3.3 GET `/attendance/today`

Get today's punch status.

**Response:**
```json
{
  "id": "uuid | null",
  "punch_in": "datetime | null",
  "punch_out": "datetime | null",
  "status": "checked_in | not_clocked_in | checked_out",
  "total_hours": "string",
  "method": "string"
}
```

---

### 3.4 GET `/attendance/monthly?month={int}&year={int}`

Get monthly attendance summary + daily breakdown.

**Response:**
```json
{
  "summary": {
    "working_days": "integer",
    "present": "integer",
    "absent": "integer",
    "leave": "integer",
    "holidays": "integer",
    "half_days": "integer",
    "on_duty": "integer"
  },
  "daily": [
    {
      "date": "date",
      "status": "present | absent | leave | weekend | holiday | half_day | on_duty",
      "punch_in": "time | null",
      "punch_out": "time | null",
      "total_hours": "string | null"
    }
  ]
}
```

---

### 3.5 GET `/attendance/weekly?week_start={date}`

Get weekly attendance breakdown for charts.

**Response:**
```json
{
  "weeks": [
    {
      "week": "string",
      "present": "integer",
      "absent": "integer",
      "leave": "integer"
    }
  ],
  "daily_hours": [
    { "day": "string", "hours": "double" }
  ],
  "punch_times": [
    { "day": "string", "punch_in": "double", "punch_out": "double" }
  ]
}
```

---

### 3.6 GET `/attendance/team?month={int}&year={int}` — Manager/HR only

Get team attendance overview.

**Response:**
```json
{
  "total_employees": "integer",
  "present_today": "integer",
  "absent_today": "integer",
  "on_leave_today": "integer",
  "team_members": [
    {
      "employee_id": "string",
      "name": "string",
      "status": "present | absent | leave",
      "punch_in": "time | null"
    }
  ]
}
```

---

## 4. Leave Management

### 4.1 GET `/leaves/balance`

Get current leave balance.

**Response:**
```json
{
  "balances": [
    {
      "type": "casual | sick | earned | comp_off | maternity | paternity | bereavement",
      "label": "string",
      "total": "integer",
      "used": "integer",
      "remaining": "integer"
    }
  ],
  "total_remaining": "integer"
}
```

---

### 4.2 POST `/leaves/apply` — multipart/form-data

Submit a leave application.

**Request:**
```json
{
  "leave_type": "casual | sick | earned | comp_off | maternity | paternity | bereavement",
  "start_date": "date",
  "start_breakdown": "full_day | first_half | second_half",
  "end_date": "date",
  "end_breakdown": "full_day | first_half | second_half",
  "description": "string",
  "attachment": "file | null"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Leave",
  "title": "string",
  "status": "Pending",
  "applied_date": "datetime",
  "start_date": "date",
  "end_date": "date",
  "description": "string"
}
```

---

## 5. Claims

### 5.1 POST `/claims/submit` — multipart/form-data

Submit an expense claim.

**Request:**
```json
{
  "title": "string",
  "claim_type": "travel | food_beverage | client_entertainment | office_supplies | medical | other",
  "amount": "double",
  "date": "date",
  "description": "string",
  "images": ["file"]
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Claims",
  "title": "string",
  "status": "Pending",
  "amount": "double",
  "applied_date": "datetime",
  "image_urls": ["string"]
}
```

---

## 6. Tickets

### 6.1 POST `/tickets/raise` — multipart/form-data

Raise a support/HR ticket.

**Request:**
```json
{
  "title": "string",
  "description": "string",
  "ticket_type": "it_support | hr_query | facilities | finance | general",
  "priority": "low | medium | high | critical",
  "assign_department": "it | hr | facilities | finance | admin",
  "cc_emails": ["string"],
  "attachments": ["file | null"]
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Tickets",
  "title": "string",
  "status": "Pending",
  "priority": "string",
  "assigned_department": "string",
  "applied_date": "datetime"
}
```

---

## 7. Shift Requests

### 7.1 POST `/shifts/request`

Request a shift change.

**Request:**
```json
{
  "requesting_shift": "morning | general | afternoon | night",
  "requested_date": "date",
  "requested_till": "date",
  "description": "string",
  "is_permanent": "boolean"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Shift Requests",
  "title": "string",
  "status": "Pending",
  "shift_details": {
    "name": "string",
    "timing": "string"
  },
  "from_date": "date",
  "to_date": "date",
  "is_permanent": "boolean",
  "applied_date": "datetime"
}
```

---

## 8. Work Type Requests

### 8.1 POST `/work-type/request`

Request a work type change.

**Request:**
```json
{
  "work_type": "wfh | wfo | hybrid | remote",
  "requested_date": "date",
  "requested_till": "date",
  "description": "string",
  "is_permanent": "boolean"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Work Type Requests",
  "title": "string",
  "status": "Pending",
  "work_type": "string",
  "from_date": "date",
  "to_date": "date",
  "is_permanent": "boolean",
  "applied_date": "datetime"
}
```

---

## 9. Attendance Requests

### 9.1 POST `/attendance/regularize` — multipart/form-data

Submit attendance regularization request.

**Request:**
```json
{
  "attendance_date": "date",
  "shift": "morning | general | afternoon | night",
  "attendance_status": "present | absent | half_day | on_duty",
  "expected_check_in": "time",
  "expected_check_out": "time",
  "actual_check_in": "time",
  "actual_check_out": "time",
  "work_type": "wfh | wfo | hybrid | remote",
  "worked_hours": "string",
  "reason": "string",
  "description": "string",
  "attachment": "file | null"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Attendance Requests",
  "title": "string",
  "status": "Pending",
  "attendance_date": "date",
  "applied_date": "datetime"
}
```

---

## 10. Asset Requests

### 10.1 POST `/assets/request`

Request an asset allocation.

**Request:**
```json
{
  "asset_category": "laptop | monitor | keyboard_mouse | headset | mobile_phone | id_card | access_card | furniture | other",
  "description": "string"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "Asset Requests",
  "title": "string",
  "status": "Pending",
  "asset_category": "string",
  "applied_date": "datetime"
}
```

---

## 11. Request Management

### 11.1 GET `/requests?role={string}&status={string}&type={string}&page={int}&limit={int}`

List requests (own or employee requests for approval).

**Query Params:**

| Param  | Type   | Values |
|--------|--------|--------|
| role   | string | `approver` (employee requests for Manager/HR) or `self` (own requests) |
| status | string | `all`, `pending`, `accepted`, `rejected` |
| type   | string | `all`, `Leave`, `Claims`, `Tickets`, `Shift Requests`, `Work Type Requests`, `Attendance Requests`, `Asset Requests` |
| page   | int    | Page number |
| limit  | int    | Items per page |

**Response:**
```json
{
  "total": "integer",
  "page": "integer",
  "limit": "integer",
  "requests": [
    {
      "id": "uuid",
      "request_id": "string",
      "type": "string",
      "title": "string",
      "status": "Pending | Accepted | Rejected",
      "icon_name": "string",
      "color_hex": "string",
      "employee": {
        "id": "uuid",
        "name": "string",
        "employee_id": "string",
        "avatar_url": "string | null"
      },
      "subtitle": "string",
      "applied_date": "datetime",
      "description": "string"
    }
  ]
}
```

---

### 11.2 GET `/requests/{id}`

Get full request details with approval timeline.

**Response:**
```json
{
  "id": "uuid",
  "request_id": "string",
  "type": "string",
  "title": "string",
  "status": "Pending | Accepted | Rejected",
  "icon_name": "string",
  "color_hex": "string",
  "employee": {
    "id": "uuid",
    "name": "string",
    "employee_id": "string"
  },
  "subtitle": "string",
  "applied_date": "datetime",
  "description": "string",
  "rejection_reason": "string | null",
  "timeline": [
    {
      "step": "string",
      "date": "string",
      "time": "string",
      "done": "boolean",
      "reason": "string | null"
    }
  ],
  "metadata": "object (type-specific fields)"
}
```

---

### 11.3 PUT `/requests/{id}/accept` — Manager/HR only

Accept a pending request.

**Request:**
```json
{
  "comment": "string | null"
}
```

**Response:**
```json
{
  "id": "uuid",
  "request_id": "string",
  "status": "Accepted",
  "accepted_by": {
    "id": "uuid",
    "name": "string"
  },
  "accepted_at": "datetime",
  "timeline": ["TimelineStep"]
}
```

---

### 11.4 PUT `/requests/{id}/reject` — Manager/HR only

Reject a pending request with reason.

**Request:**
```json
{
  "rejection_reason": "string (required)"
}
```

**Response:**
```json
{
  "id": "uuid",
  "request_id": "string",
  "status": "Rejected",
  "rejected_by": {
    "id": "uuid",
    "name": "string"
  },
  "rejected_at": "datetime",
  "rejection_reason": "string",
  "timeline": ["TimelineStep"]
}
```

---

### 11.5 DELETE `/requests/{id}` — Owner only

Cancel own pending request.

**Response:**
```json
{
  "message": "string",
  "request_id": "string"
}
```

---

## 12. Payslip & Salary

### 12.1 GET `/payslips?month={int}&year={int}`

Get payslip for a specific month.

**Response:**
```json
{
  "id": "uuid",
  "month": "integer",
  "year": "integer",
  "month_label": "string",
  "gross_salary": "double",
  "net_pay": "double",
  "total_deductions": "double",
  "earnings": {
    "basic": "double",
    "hra": "double",
    "da": "double",
    "special_allowance": "double",
    "other_allowance": "double"
  },
  "deductions": {
    "provident_fund": "double",
    "esi": "double",
    "professional_tax": "double",
    "income_tax": "double"
  },
  "paid_on": "datetime",
  "pdf_url": "string"
}
```

---

### 12.2 GET `/payslips/{id}/pdf`

Download payslip as PDF binary.

**Response:**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="payslip_{month}_{year}.pdf"
```

---

### 12.3 GET `/payslips/list?year={int}`

List all available payslips for a year.

**Response:**
```json
{
  "year": "integer",
  "payslips": [
    {
      "month": "integer",
      "label": "string",
      "net_pay": "double",
      "status": "paid | processing | pending"
    }
  ]
}
```

---

## 13. Notifications

### 13.1 GET `/notifications?page={int}&limit={int}`

List all notifications.

**Response:**
```json
{
  "unread_count": "integer",
  "notifications": [
    {
      "id": "uuid",
      "title": "string",
      "body": "string",
      "type": "string",
      "category": "alerts | updates | announcements",
      "read": "boolean",
      "payload": "object",
      "created_at": "datetime"
    }
  ]
}
```

---

### 13.2 PUT `/notifications/{id}/read`

Mark a single notification as read.

---

### 13.3 PUT `/notifications/read-all`

Mark all notifications as read.

---

### 13.4 POST `/notifications/register-device`

Register FCM token for push notifications.

**Request:**
```json
{
  "fcm_token": "string",
  "platform": "android | ios",
  "device_id": "string"
}
```

---

## 14. Employee Directory

### 14.1 GET `/employees?search={string}&department={string}&page={int}&limit={int}`

Search/list employees.

**Response:**
```json
{
  "total": "integer",
  "employees": [
    {
      "id": "uuid",
      "employee_id": "string",
      "name": "string",
      "designation": "string",
      "department": "string",
      "email": "string",
      "phone": "string",
      "avatar_url": "string | null"
    }
  ]
}
```

---

### 14.2 GET `/employees/{id}`

Get specific employee profile.

**Response:**
```json
{
  "id": "uuid",
  "employee_id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "designation": "string",
  "department": "string",
  "date_of_joining": "date",
  "reporting_manager": {
    "id": "uuid",
    "name": "string"
  },
  "avatar_url": "string | null"
}
```

---

## 15. Dashboard

### 15.1 GET `/dashboard/summary`

Get dashboard data for the current user. Response varies by role.

**Response (Employee):**
```json
{
  "attendance": {
    "status": "checked_in | not_clocked_in | checked_out",
    "punch_in": "time | null",
    "punch_out": "time | null",
    "total_hours": "string"
  },
  "leave_balance": {
    "total_remaining": "integer",
    "attendance_percentage": "double"
  },
  "leave_summary": {
    "casual": { "used": "integer", "total": "integer" },
    "sick": { "used": "integer", "total": "integer" },
    "earned": { "used": "integer", "total": "integer" }
  },
  "recent_activity": [
    {
      "icon": "string",
      "color": "string",
      "title": "string",
      "subtitle": "string",
      "time": "string"
    }
  ]
}
```

**Response (Manager/HR — additional fields):**
```json
{
  "team_attendance": {
    "present": "integer",
    "absent": "integer",
    "on_leave": "integer",
    "total": "integer"
  },
  "pending_approvals": "integer",
  "performance_metrics": {
    "team_productivity": "double",
    "avg_attendance": "double",
    "open_tickets": "integer"
  }
}
```

---

### 15.2 GET `/dashboard/announcements`

Get company announcements for dashboard.

**Response:**
```json
{
  "announcements": [
    {
      "id": "uuid",
      "title": "string",
      "subtitle": "string",
      "icon": "string",
      "created_at": "datetime"
    }
  ]
}
```

---

### 15.3 GET `/dashboard/analytics` — HR only

Get HR-specific analytics.

**Response:**
```json
{
  "total_employees": "integer",
  "new_joiners_this_month": "integer",
  "attrition_rate": "double",
  "department_breakdown": [
    { "department": "string", "count": "integer" }
  ],
  "leave_analytics": {
    "most_used_type": "string",
    "avg_leaves_per_employee": "double"
  }
}
```

---

## 16. Settings

### 16.1 GET `/settings`

Get user preferences.

**Response:**
```json
{
  "theme": "light | dark | system",
  "notifications_enabled": "boolean",
  "biometric_enabled": "boolean",
  "language": "string"
}
```

---

### 16.2 PUT `/settings`

Update user preferences.

**Request:**
```json
{
  "theme": "light | dark | system",
  "notifications_enabled": "boolean",
  "biometric_enabled": "boolean",
  "language": "string"
}
```

---

## Enums & Constants Reference

| Category           | Values |
|--------------------|--------|
| User Roles         | `employee`, `manager`, `hr` |
| Request Statuses   | `Pending`, `Accepted`, `Rejected` |
| Request Types      | `Leave`, `Claims`, `Tickets`, `Shift Requests`, `Work Type Requests`, `Attendance Requests`, `Asset Requests` |
| Leave Types        | `casual`, `sick`, `earned`, `comp_off`, `maternity`, `paternity`, `bereavement` |
| Claim Types        | `travel`, `food_beverage`, `client_entertainment`, `office_supplies`, `medical`, `other` |
| Ticket Types       | `it_support`, `hr_query`, `facilities`, `finance`, `general` |
| Ticket Priority    | `low`, `medium`, `high`, `critical` |
| Shift Types        | `morning`, `general`, `afternoon`, `night` |
| Work Types         | `wfh`, `wfo`, `hybrid`, `remote` |
| Attendance Status  | `present`, `absent`, `half_day`, `on_duty`, `weekend`, `holiday` |
| Asset Categories   | `laptop`, `monitor`, `keyboard_mouse`, `headset`, `mobile_phone`, `id_card`, `access_card`, `furniture`, `other` |
| Notification Categories | `alerts`, `updates`, `announcements` |

---

## Error Response Format

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": [
      { "field": "string", "message": "string" }
    ]
  }
}
```

### HTTP Status Codes

| Code | Meaning               |
|------|-----------------------|
| 200  | OK                    |
| 201  | Created               |
| 400  | Bad Request           |
| 401  | Unauthorized          |
| 403  | Forbidden             |
| 404  | Not Found             |
| 409  | Conflict              |
| 422  | Unprocessable Entity  |
| 429  | Too Many Requests     |
| 500  | Internal Server Error |

### Error Codes

| Code                  | Description                            |
|-----------------------|----------------------------------------|
| `AUTH_INVALID`        | Invalid username or password            |
| `TOKEN_EXPIRED`       | JWT token has expired                   |
| `INSUFFICIENT_ROLE`   | User role cannot perform this action    |
| `VALIDATION_ERROR`    | Request body validation failed          |
| `LEAVE_INSUFFICIENT`  | Not enough leave balance                |
| `DATE_CONFLICT`       | Overlapping dates with existing request |
| `ALREADY_PUNCHED_IN`  | User has already clocked in today       |
| `NOT_PUNCHED_IN`      | Cannot punch out without punching in    |
| `REQUEST_NOT_PENDING` | Can only approve/reject pending requests|
| `SELF_APPROVAL`       | Cannot approve own requests             |

---

## API Endpoint Summary — Total: 40

| #  | Method | Endpoint                     | Auth | Roles       |
|----|--------|------------------------------|------|-------------|
| 1  | POST   | `/auth/login`                | No   | All         |
| 2  | POST   | `/auth/refresh`              | No   | All         |
| 3  | POST   | `/auth/logout`               | Yes  | All         |
| 4  | POST   | `/auth/change-password`      | Yes  | All         |
| 5  | GET    | `/users/me`                  | Yes  | All         |
| 6  | PUT    | `/users/me`                  | Yes  | All         |
| 7  | POST   | `/users/me/avatar`           | Yes  | All         |
| 8  | POST   | `/attendance/punch-in`       | Yes  | All         |
| 9  | POST   | `/attendance/punch-out`      | Yes  | All         |
| 10 | GET    | `/attendance/today`          | Yes  | All         |
| 11 | GET    | `/attendance/monthly`        | Yes  | All         |
| 12 | GET    | `/attendance/weekly`         | Yes  | All         |
| 13 | GET    | `/attendance/team`           | Yes  | Manager, HR |
| 14 | GET    | `/leaves/balance`            | Yes  | All         |
| 15 | POST   | `/leaves/apply`              | Yes  | All         |
| 16 | POST   | `/claims/submit`             | Yes  | All         |
| 17 | POST   | `/tickets/raise`             | Yes  | All         |
| 18 | POST   | `/shifts/request`            | Yes  | All         |
| 19 | POST   | `/work-type/request`         | Yes  | All         |
| 20 | POST   | `/attendance/regularize`     | Yes  | All         |
| 21 | POST   | `/assets/request`            | Yes  | All         |
| 22 | GET    | `/requests`                  | Yes  | All         |
| 23 | GET    | `/requests/{id}`             | Yes  | All         |
| 24 | PUT    | `/requests/{id}/accept`      | Yes  | Manager, HR |
| 25 | PUT    | `/requests/{id}/reject`      | Yes  | Manager, HR |
| 26 | DELETE | `/requests/{id}`             | Yes  | Owner       |
| 27 | GET    | `/payslips`                  | Yes  | All         |
| 28 | GET    | `/payslips/{id}/pdf`         | Yes  | All         |
| 29 | GET    | `/payslips/list`             | Yes  | All         |
| 30 | GET    | `/notifications`             | Yes  | All         |
| 31 | PUT    | `/notifications/{id}/read`   | Yes  | All         |
| 32 | PUT    | `/notifications/read-all`    | Yes  | All         |
| 33 | POST   | `/notifications/register-device` | Yes | All      |
| 34 | GET    | `/employees`                 | Yes  | All         |
| 35 | GET    | `/employees/{id}`            | Yes  | All         |
| 36 | GET    | `/dashboard/summary`         | Yes  | All         |
| 37 | GET    | `/dashboard/announcements`   | Yes  | All         |
| 38 | GET    | `/dashboard/analytics`       | Yes  | HR          |
| 39 | GET    | `/settings`                  | Yes  | All         |
| 40 | PUT    | `/settings`                  | Yes  | All         |

---

**Total API Endpoints Required: 40**

*PPulse HRMS v1.0*
