# PPULSE HRMS — Product Overview

## What is PPULSE?

PPULSE is a mobile-first Human Resource Management System that enables organizations to manage attendance, leave, expenses, and payroll from any smartphone. It replaces physical biometric devices with AI-powered face verification and provides real-time workforce visibility to managers and administrators.

## Key Differentiators

| Feature | Traditional HRMS | PPULSE |
|---------|-----------------|--------|
| Attendance | Physical biometric device | Face verification from any phone |
| Anti-Spoofing | None | Multi-frame liveness (LBP + movement) |
| Manager View | End-of-day reports | Real-time check-in with location |
| Platform | Web only | Native iOS + Android |
| Security | Basic password | JWT + token versioning + lockout |

## Feature Matrix

### Employee Self-Service
- Face-verified punch-in/out with GPS
- Leave application with balance tracking
- Expense claim submission
- Helpdesk ticket creation
- Shift and work type change requests
- Monthly payslip viewing
- Push notifications

### Manager Tools
- Team attendance dashboard (real-time)
- Per-employee check-in time, location, work type
- Request approval queue (leave, claims, tickets, shifts, assets)
- Team analytics and performance metrics
- Org chart navigation

### Admin Control
- Command center with org-wide metrics
- User management (enable/disable/promote/force-logout)
- Audit log with CSV export
- Geofence and holiday management
- Database backup
- GDPR compliance tools
- IP allowlisting

## User Roles

| Role | Access Level | How Determined |
|------|-------------|----------------|
| Super Admin | Full system access + admin panel | `is_superuser = True` |
| HR | Employee features + manager tools | `is_staff = True` |
| Manager | Employee features + team oversight | Has direct reports in EmployeeWorkInformation |
| Employee | Self-service features only | Default role |

## Supported Platforms

- iOS 16+ (with native SwiftUI components)
- Android 8.0+ (API 26+)
- Web (responsive dashboard)

## Demo Credentials

| Role | Username | Password |
|------|----------|----------|
| Super Admin | admin | admin23 |
| Manager | vikram | vikram23 |
| Employee | rahul | rahul23 |

---

**PPULSE Technologies** | Confidential
