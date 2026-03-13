# PPulse HRMS - Sitemap

## Authentication Flow

- **Splash Screen** → Login Screen (after 3s)
- **Login Screen** → Shell Screen (role-based dashboard)

Demo credentials:
- `employee / 12345`
- `manager / 12345`
- `hr / 12345`

---

# Shell Screen (Main App)

The **Shell Screen acts as the root container** of the application.

### Global Navigation (AppBar)

| Action | Destination |
|--------|-------------|
| Notifications Bell | Dynamic Island Notification Overlay |
| Profile Avatar | Profile Sheet (Modal) |

---

# Profile Sheet

| Option | Screen |
|------|------|
| Profile | Profile Screen |
| Directory | Company Directory |
| Settings | Settings Screen |
| Logout | Returns to Login Screen |

---

# Unified Dashboard (Single View)

> One adaptive dashboard used for **Employee, Manager, and HR roles**.

Widgets appear **based on the logged-in role**.

### Personal Widgets (All Roles)

- Attendance Punch Timer
- Leave Balance
- Recent Requests
- Work Summary

### Manager Widgets

- Pending Approvals
- Team Attendance Summary
- Team Performance

### HR Widgets

- Company Attendance Rate
- Claims Overview
- Employee Statistics
- Leave Analytics

---

# Bottom Navigation

| Tab | Screen | Description |
|-----|--------|-------------|
| 0 | **Dashboard** | Unified role-based dashboard |
| 1 | **Requests** | Leave and request management |
| 2 | **Attendance** | Attendance logs and analytics |
| 3 | **Payroll** | Salary slips and payment history |

---

# Requests Module

| Screen | Description |
|------|-------------|
| Apply Leave Screen | Submit leave applications |
| Leave Screen | View leave history |
| Request Detail Screen (`/request-detail`) | Detailed request timeline |
| Apply Request Screen | Generic form for multiple request types |

### Request Types

- Claim
- Ticket
- Shift Change
- Work Type
- Attendance Request

---

# Attendance Module

| Screen | Description |
|------|-------------|
| Attendance Dashboard | Attendance summary |
| Attendance Logs | Daily punch history |
| Face Verification Dialog | Triggered on punch-in |

---

# Payroll Module

| Screen | Description |
|------|-------------|
| Payslip Screen | View monthly salary slips |
| Payslip Detail | Detailed payslip breakdown |

---

# Manager Features

Manager tools are integrated into the system.

| Feature | Screen |
|------|------|
| Team Directory | Browse team members |
| Employee Profile | View employee details |
| Approvals | Approve or reject requests |
| Team Analytics | Team performance insights |

---

# HR Features

| Feature | Screen |
|------|------|
| HR Dashboard | Company-wide HR metrics |
| Employee Directory | Organization employee list |
| Attendance Dashboard | Company attendance analytics |
| Claims Overview | Claims processing and tracking |

---

# Navigation Flow Diagram

```
Splash Screen
│
▼
Login Screen
│
▼
┌──────────────────────────────────────────┐
│            Shell Screen                  │
│                                          │
│  ┌─ AppBar ────────────────────────────┐ │
│  │  Notifications    Profile Avatar    │ │
│  │                      │              │ │
│  │                  Profile Sheet      │ │
│  │                  ├─ Profile         │ │
│  │                  ├─ Directory       │ │
│  │                  ├─ Settings        │ │
│  │                  └─ Logout → Login  │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─ Bottom Navigation ─────────────────┐ │
│  │                                     │ │
│  │  Dashboard (Role Adaptive)          │ │
│  │                                     │ │
│  │  Requests ───────────────────────┐  │ │
│  │  ├─ Apply Leave                  │  │ │
│  │  ├─ Leave History                │  │ │
│  │  │  └─ Request Detail            │  │ │
│  │  └─ Apply Request (5 Types)      │  │ │
│  │                                     │ │
│  │  Attendance ──────────────────────┐ │ │
│  │  ├─ Attendance Logs              │  │ │
│  │  └─ Face Verification            │  │ │
│  │                                     │ │
│  │  Payroll ─────────────────────────┐ │ │
│  │  └─ Payslip                      │  │ │
│  │                                     │ │
│  └─────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

---

# Screen Summary

| # | Screen | Roles | Navigation |
|---|--------|-------|------------|
| 1 | Splash | All | Entry |
| 2 | Login | All | pushReplacement |
| 3 | Dashboard | All | Tab 0 |
| 4 | Requests | All | Tab 1 |
| 5 | Apply Leave | All | push |
| 6 | Leave Screen | All | push |
| 7 | Request Detail | All | pushNamed |
| 8 | Apply Request | All | push |
| 9 | Attendance Dashboard | All | Tab 2 |
| 10 | Attendance Logs | All | push |
| 11 | Payslip | All | Tab 3 |
| 12 | Payslip Detail | All | push |
| 13 | Team Directory | Manager | push |
| 14 | Employee Profile | Manager | push |
| 15 | Approvals | Manager | push |
| 16 | Team Analytics | Manager | push |
| 17 | HR Dashboard | HR | push |
| 18 | Employee Directory | HR | push |
| 19 | Attendance Analytics | HR | push |
| 20 | Claims Overview | HR | push |
| 21 | Profile | All | push |
| 22 | Settings | All | push |

**Total: 22 structured screens across 3 roles**
