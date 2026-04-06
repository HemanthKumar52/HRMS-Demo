# PPulse HRMS - CRUD Actions Comparison: Web vs Mobile

> Generated: 2026-03-31 | Web: Horilla HRMS (Django + HTMX) | Mobile: Flutter + Django REST API

---

## Legend

| Symbol | Meaning |
|--------|---------|
| DONE | Fully implemented |
| PARTIAL | Basic implementation, missing features |
| STUB | API exists but returns mock/empty data |
| MISSING | Not implemented at all |
| N/A | Not applicable to this platform |

---

## 1. AUTHENTICATION

| Action | Web | Mobile | Mobile Status | Notes |
|--------|-----|--------|---------------|-------|
| Username/Password Login | POST `/accounts/login/` | POST `/v1/auth/login` | DONE | Mobile has animated login screen |
| Microsoft SSO | OAuth2 redirect flow | `/v1/auth/microsoft/login` | PARTIAL | Backend ready, deep link handler missing |
| Google SSO | OAuth2 redirect flow | `/v1/auth/google/login` | PARTIAL | Backend ready, hidden in UI |
| Logout | POST `/accounts/logout/` | POST `/v1/auth/logout` | DONE | |
| Change Password | POST `/change-password/` | POST `/v1/auth/change-password` | DONE | |
| Token Refresh | N/A (session-based) | POST `/v1/auth/refresh` | DONE | JWT auto-refresh |
| Session Validation | Cookie-based | GET `/v1/users/me` | DONE | Splash screen checks token |
| SSO Deep Link Callback | N/A | `ppulse://auth-callback` | MISSING | Need to register URL scheme in iOS/Android |

---


## 2. ATTENDANCE

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **Clock In** | POST `attendance-clock-in-out/` | POST `/v1/attendance/punch-in` | DONE | Pulse animation on clock icon | Dynamic Island notification |
| **Clock Out** | POST `attendance-clock-in-out/` | POST `/v1/attendance/punch-out` | DONE | Pulse animation | Dynamic Island notification |
| **View Today** | GET `attendance-today/` | GET `/v1/attendance/today` | DONE | HTMX swap | fadeIn + slideY |
| **View Monthly** | GET `attendance-view/` + filters | GET `/v1/attendance/monthly` | DONE | Skeleton loader | Staggered fadeIn |
| **View Weekly** | GET with date range filter | GET `/v1/attendance/weekly` | DONE | Chart.js bar animation | Static (no chart animation) |
| **Team Attendance** | GET `attendance-team/` | GET `/v1/attendance/team` | DONE | Table with HTMX | fadeIn list |
| **Create Attendance** | POST `attendance-create/` | N/A | MISSING | Modal form | - |
| **Update Attendance** | POST `attendance-update/<id>/` | N/A | MISSING | Inline HTMX edit | - |
| **Delete Attendance** | POST `attendance-delete/<id>/` | N/A | MISSING | SweetAlert confirm | - |
| **Bulk Delete** | POST `attendance-bulk-delete/` | N/A | MISSING | Multi-select + confirm | - |
| **Regularize** | POST regularization form | POST `/v1/attendance/regularize` | DONE | Modal form | Form + SnackBar |
| **Overtime Create** | POST `attendance-overtime-create/` | N/A | MISSING | Modal form | - |
| **Overtime Update** | POST `attendance-overtime-update/<id>/` | N/A | MISSING | Inline edit | - |
| **Overtime Delete** | POST `attendance-overtime-delete/<id>/` | N/A | MISSING | Confirm dialog | - |
| **Export Excel** | GET `attendance-info-export/` | N/A | MISSING | Download trigger | - |
| **Import Excel** | POST `attendance-info-import/` | N/A | MISSING | Upload modal | - |

---

## 3. LEAVE MANAGEMENT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **View Balance** | GET `leave-assign-view/` | GET `/v1/leaves/balance` | DONE | Table view | Counter roll-up (3.5s) |
| **Apply Leave** | POST `leave-request-create/` | POST `/v1/leaves/apply` | DONE | Modal + HTMX | Form + SnackBar |
| **View My Requests** | GET `user-request-view/` | GET `/v1/requests?type=Leave` | DONE | HTMX list | Staggered slideX |
| **View All Requests** (Manager) | GET `request-view/` | GET `/v1/requests` | DONE | Tab + filter | Tab + filter |
| **Update Leave Request** | POST `leave-request-update/<id>/` | N/A | MISSING | Modal form | - |
| **Delete Leave Request** | POST `leave-request-delete/<id>/` | N/A | MISSING | SweetAlert | - |
| **Bulk Delete Requests** | POST `leave-request-bulk-delete/` | N/A | MISSING | Multi-select | - |
| **Approve Leave** | POST approve endpoint | POST `/v1/requests/<id>/accept` | DONE | HTMX status swap | SnackBar |
| **Reject Leave** | POST reject endpoint | POST `/v1/requests/<id>/reject` | DONE | HTMX + reason field | SnackBar |
| **Cancel Leave** | POST cancel endpoint | POST `/v1/requests/<id>/cancel` | DONE | HTMX swap | SnackBar |
| **Leave Type CRUD** | Full CRUD `/leave-type-*` | N/A | MISSING | Admin panel | - |
| **Allocation Request** | POST `leave-allocation-request-create/` | N/A | MISSING | Modal form | - |
| **Restricted Days CRUD** | Full CRUD `/restrict-*` | N/A | MISSING | Admin panel | - |
| **Export Leave Data** | GET `leave-info-export/` | N/A | MISSING | Download | - |

---

## 4. PAYROLL / PAYSLIPS

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **View Payslips List** | GET payslip list view | GET `/v1/payslips/list` | DONE | Table view | Staggered fadeIn |
| **View Payslip Detail** | GET payslip detail | GET `/v1/payslips?month=&year=` | DONE | Modal detail | DoubleTween counter |
| **Download PDF** | GET payslip PDF | GET `/v1/payslips/<id>/pdf` | DONE | PDF viewer | PDF viewer |
| **Contract Create** | POST `contract-create/` | N/A | MISSING | Modal form | - |
| **Contract Update** | POST `contract-update/<id>/` | N/A | MISSING | Inline edit | - |
| **Contract Delete** | POST `contract-delete/<id>/` | N/A | MISSING | Confirm dialog | - |
| **Payslip Status Update** | POST `bulk-update-payslip-status/` | N/A | MISSING | Bulk action | - |
| **Payroll Period Create** | POST `periods/create/` | N/A | MISSING | Workflow form | - |
| **Submit to Finance** | POST `periods/<id>/submit/` | N/A | MISSING | Status transition | - |
| **Finance Review** | POST `periods/<id>/review/` | N/A | MISSING | Status transition | - |
| **CEO Approve/Reject** | POST `periods/<id>/approve|reject/` | N/A | MISSING | Status transition | - |
| **Export Excel** | GET export endpoint | N/A | MISSING | Download | - |

---

## 5. EMPLOYEE MANAGEMENT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **View Profile (Self)** | GET `employee-profile/` | GET `/v1/users/me` | DONE | Profile page | fadeIn sections |
| **Update Profile** | POST `self-info-update/` | N/A | MISSING | HTMX inline edit | - |
| **Upload Avatar** | POST avatar upload | POST `/v1/users/me/avatar` | DONE | Preview + upload | Image picker |
| **View Employee List** | GET `employee-view/` | GET `/v1/employees` | DONE | HTMX table | Staggered slideX |
| **View Employee Detail** | GET `employee-detail/<id>/` | GET `/v1/employees/<id>` | DONE | Modal detail | Profile view |
| **Create Employee** | POST `employee-create/` | N/A | MISSING | Multi-step form | - |
| **Update Employee** | POST `employee-update/<id>/` | N/A | MISSING | Modal form | - |
| **Delete Employee** | POST `employee-delete/<id>/` | N/A | MISSING | SweetAlert | - |
| **Bulk Delete** | POST `employee-bulk-delete/` | N/A | MISSING | Multi-select | - |
| **Bulk Update** | POST `save-employee-bulk-update/` | N/A | MISSING | Bulk form | - |
| **Personal Info Update** | POST `employee-create-update-personal-info/<id>/` | N/A | MISSING | Tab form | - |
| **Work Info Update** | POST `employee-update-work-info/<id>/` | N/A | MISSING | Tab form | - |
| **Bank Details Update** | POST `employee-update-bank-details/<id>/` | N/A | MISSING | Tab form | - |
| **Document CRUD** | Full CRUD `/document-*` | N/A | MISSING | Modal forms | - |
| **Employee Notes CRUD** | Full CRUD `/employee-note-*` | N/A | MISSING | Inline notes | - |
| **Export Excel** | GET `employee-info-export/` | N/A | MISSING | Download | - |

---

## 6. CLAIMS / EXPENSE

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Notes |
|--------|-------------|----------------|---------------|-------|
| **Submit Claim** | POST claim create | POST `/v1/claims/submit` | DONE | Mobile has image picker for receipts |
| **View Claims** | GET claims list | GET `/v1/requests?type=Claim` | STUB | Returns empty list |
| **Update Claim** | POST claim update | N/A | MISSING | |
| **Delete Claim** | POST claim delete | N/A | MISSING | |
| **Approve Claim** | POST approve | POST `/v1/requests/<id>/accept` | DONE | |
| **Reject Claim** | POST reject | POST `/v1/requests/<id>/reject` | DONE | |

---

## 7. TICKETS / SUPPORT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Notes |
|--------|-------------|----------------|---------------|-------|
| **Raise Ticket** | POST ticket create | POST `/v1/tickets/raise` | DONE | |
| **View Tickets** | GET tickets list | GET `/v1/requests?type=Ticket` | STUB | Returns empty list |
| **Update Ticket** | POST ticket update | N/A | MISSING | |
| **Delete Ticket** | POST ticket delete | N/A | MISSING | |
| **Assign Ticket** | POST ticket assign | N/A | MISSING | |
| **Close Ticket** | POST ticket close | N/A | MISSING | |

---

## 8. SHIFT MANAGEMENT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Notes |
|--------|-------------|----------------|---------------|-------|
| **Request Shift Change** | POST shift request | POST `/v1/shifts/request` | DONE | |
| **View Shifts** | GET shifts list | GET `/v1/shifts` | DONE | Reference data |
| **Approve Shift Request** | POST approve | POST `/v1/requests/<id>/accept` | DONE | |
| **Reject Shift Request** | POST reject | POST `/v1/requests/<id>/reject` | DONE | |
| **Create Shift** (Admin) | POST shift create | N/A | MISSING | |
| **Update Shift** (Admin) | POST shift update | N/A | MISSING | |
| **Delete Shift** (Admin) | POST shift delete | N/A | MISSING | |

---

## 9. WORK TYPE MANAGEMENT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Notes |
|--------|-------------|----------------|---------------|-------|
| **Request Work Type Change** | POST work type request | POST `/v1/work-type/request` | DONE | |
| **View Work Types** | GET work types | GET `/v1/work-types` | DONE | Reference data |
| **Approve/Reject** | POST approve/reject | POST `/v1/requests/<id>/accept|reject` | DONE | |
| **CRUD Work Types** (Admin) | Full CRUD | N/A | MISSING | |

---

## 10. ASSET MANAGEMENT

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **Request Asset** | POST asset request | POST `/v1/assets/request` | DONE | Modal form | Form + SnackBar |
| **Approve/Reject** | POST approve/reject | POST `/v1/requests/<id>/accept|reject` | DONE | HTMX swap | SnackBar |
| **Create Asset** (Admin) | POST `asset-creation/` | N/A | MISSING | Modal | - |
| **Update Asset** | POST `asset-update/<id>/` | N/A | MISSING | Inline edit | - |
| **Delete Asset** | POST `asset-delete/<id>/` | N/A | MISSING | SweetAlert | - |
| **Asset Category CRUD** | Full CRUD | N/A | MISSING | Modal | - |
| **Asset Batch CRUD** | Full CRUD | N/A | MISSING | Modal | - |
| **Asset Assignment** | POST assign | N/A | MISSING | Form | - |
| **Asset Return** | POST return | N/A | MISSING | Form | - |

---

## 11. RECRUITMENT (Web Only - Not in Mobile)

| Action | Web Endpoint | Mobile Status |
|--------|-------------|---------------|
| Create Recruitment | POST `recruitment-create/` | MISSING |
| Update Recruitment | POST `recruitment-update/<id>/` | MISSING |
| Delete Recruitment | POST `recruitment-delete/<id>/` | MISSING |
| Pipeline View | GET `pipeline/` | MISSING |
| Pipeline Drag & Drop | POST `candidate-sequence-update/` | MISSING |
| Create Candidate | POST `candidate-create/` | MISSING |
| Update Candidate | POST `candidate-update/<id>/` | MISSING |
| Stage Management | Full CRUD | MISSING |
| Schedule Interview | POST `candidate-schedule-date-update/` | MISSING |
| Notes/Remarks CRUD | Full CRUD | MISSING |

---

## 12. DASHBOARD & ANALYTICS

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Web Animation | Mobile Animation |
|--------|-------------|----------------|---------------|---------------|-----------------|
| **Summary** | GET dashboard | GET `/v1/dashboard/summary` | DONE | Chart.js animated | Counter roll-up |
| **Announcements** | GET announcements | GET `/v1/dashboard/announcements` | DONE | HTMX list | fadeIn list |
| **Analytics** | GET analytics | GET `/v1/dashboard/analytics` | DONE | Chart.js animated | Staggered fadeIn |
| **Attendance Chart** | Chart.js gradient | fl_chart | PARTIAL | Sweep + gradient fill | Static render |
| **Leave Chart** | Chart.js doughnut | fl_chart | PARTIAL | Radial sweep | Static render |
| **Department Chart** | Chart.js bar | fl_chart | PARTIAL | Bar grow animation | Static render |

---

## 13. NOTIFICATIONS

| Action | Web Endpoint | Mobile Endpoint | Mobile Status | Notes |
|--------|-------------|----------------|---------------|-------|
| **View Notifications** | GET notifications | GET `/v1/notifications` | DONE | |
| **Mark as Read** | POST mark read | POST `/v1/notifications/<id>/read` | DONE | |
| **Mark All Read** | POST mark all | POST `/v1/notifications/read-all` | DONE | |
| **Register Device** | N/A | POST `/v1/notifications/register-device` | DONE | Push notifications |
| **Local Notifications** | N/A | flutter_local_notifications | DONE | Mobile only |
| **Dynamic Island** | N/A | Custom widget | DONE | Mobile only |

---

## 14. SETTINGS

| Action | Web | Mobile | Mobile Status |
|--------|-----|--------|---------------|
| **Theme Settings** | System preference | GET/POST `/v1/settings` | DONE |
| **Notification Prefs** | Profile settings | Local toggle | DONE |
| **Language** | i18n system | N/A | MISSING |
| **Biometric Lock** | N/A | N/A | MISSING |

---

## Animation Comparison Summary

### Web Animations (Horilla)
| Type | Technology | Usage |
|------|-----------|-------|
| Page Load Entry | CSS `fadeInUp` (0.4s) | All pages |
| Sidebar Entry | CSS `fadeInRight` (0.6s) | Navigation |
| Content Swap | HTMX `innerHTML` swap | All dynamic content |
| Charts | Chart.js v3 animations | Dashboard, Analytics |
| Loading | Skeleton `.animated-background` | All list views |
| Button Ripple | CSS `ripple` keyframe (0.6s) | All buttons |
| Status Pulse | CSS `pulse` (2s infinite) | Active indicators |
| Clock Tick | CSS `clockTick` (2s infinite) | Attendance timer |
| Header Shine | CSS `headerShine` (10s infinite) | Header decoration |
| Notifications | SweetAlert2 animated | All CRUD confirmations |
| Glow Effect | CSS `glowPulse` (2s infinite) | Badge notifications |
| Drag & Drop | JS + CSS transitions | Recruitment pipeline |

### Mobile Animations (Flutter)
| Type | Technology | Usage |
|------|-----------|-------|
| Page Load Entry | flutter_animate fadeIn+slideY | Most screens |
| Counter Roll-Up | TweenAnimationBuilder | Dashboard, Stats |
| Background Orbs | AnimationController sin/cos | Login screen only |
| Tab Bounce | AnimationController TweenSequence | Bottom nav |
| Card Press | AnimationController scale | NeuCard widget |
| Shimmer Loading | flutter_animate shimmer | Login screen only |
| Page Transition | PageRouteBuilder FadeTransition | Splash, Login |
| Dynamic Island | AnimatedPositioned | Notifications |
| Status Containers | AnimatedContainer | Settings, Requests |

### Key Gaps (Web has, Mobile doesn't)

| Feature | Web Implementation | Priority |
|---------|-------------------|----------|
| Skeleton loaders on ALL screens | `.animated-background` class | HIGH |
| Chart entry animations | Chart.js built-in | HIGH |
| Radial sweep (pie/donut) | Chart.js animation | HIGH |
| Bar grow animation | Chart.js animation | HIGH |
| Button ripple effect | CSS keyframe | MEDIUM |
| Pulse/glow on active status | CSS keyframe | MEDIUM |
| Clock tick animation | CSS keyframe | MEDIUM |
| Drag & drop interactions | JS + CSS | LOW (mobile = swipe) |
| SweetAlert confirmations | SweetAlert2 | MEDIUM (use dialogs) |
| HTMX smooth content swap | HTMX library | N/A (use page transitions) |
| Header shine effect | CSS keyframe | LOW |
| Content fadeInRight | CSS keyframe | MEDIUM |

---

## Implementation Priority Matrix

### Phase 1 - Critical (Match Web Core UX)
1. Add skeleton loading to ALL screens (not just login)
2. Add chart entry animations (bar grow, pie sweep)
3. Add pull-to-refresh with custom animation
4. Add success/error animated feedback (checkmark, shake)
5. Implement Hero transitions between list -> detail screens

### Phase 2 - Enhanced (Match Web Polish)
6. Add status badge transition animations
7. Add swipe-to-action on list items (approve/reject)
8. Add button ripple/tap feedback improvements
9. Add pulse glow on active attendance status
10. Add animated empty states

### Phase 3 - Premium (Exceed Web)
11. Add Lottie animations for key states
12. Add parallax scroll effects
13. Add shared element transitions
14. Add confetti/celebration on milestones
15. Add gesture-based interactions (pinch charts, swipe cards)

---

## CRUD Coverage Score

| Module | Web CRUD Count | Mobile CRUD Count | Coverage % |
|--------|---------------|-------------------|-----------|
| Authentication | 5 | 5 | 100% |
| Attendance | 14 | 7 | 50% |
| Leave | 15 | 6 | 40% |
| Payroll | 10 | 3 | 30% |
| Employee | 16 | 4 | 25% |
| Claims | 5 | 2 | 40% |
| Tickets | 6 | 1 | 17% |
| Shifts | 7 | 3 | 43% |
| Work Types | 5 | 3 | 60% |
| Assets | 9 | 2 | 22% |
| Recruitment | 18 | 0 | 0% |
| Dashboard | 3 | 3 | 100% |
| Notifications | 4 | 4 | 100% |
| **TOTAL** | **117** | **43** | **37%** |

> Mobile currently implements 37% of the web's CRUD operations. The main gaps are in admin/management functions (Create, Update, Delete) - the mobile app focuses primarily on employee self-service (Read + Submit requests).
