# PPulse Mobile App - Complete Action Flow Traces

> This document traces **exactly what happens in the code** when a user performs key actions in the Flutter mobile app. Each flow maps: **UI tap -> Handler -> State Management -> API Call -> Response Handling -> UI Update**.

---

## Table of Contents

1. [Punch In (Attendance)](#1-punch-in-attendance)
2. [Punch Out (Attendance)](#2-punch-out-attendance)
3. [Apply Leave](#3-apply-leave)
4. [Submit Expense Claim](#4-submit-expense-claim)
5. [Raise Support Ticket](#5-raise-support-ticket)
6. [Request Shift Change](#6-request-shift-change)
7. [Request Work Type Change](#7-request-work-type-change)
8. [Attendance Regularization](#8-attendance-regularization)
9. [Approve / Reject a Request (Manager/HR)](#9-approve--reject-a-request-managerhr)
10. [View Payslip & Download PDF](#10-view-payslip--download-pdf)
11. [Login](#11-login)
12. [Logout](#12-logout)
13. [Notification Polling & Tap](#13-notification-polling--tap)
14. [Dashboard Data Load](#14-dashboard-data-load)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter UI Layer                     │
│  lib/screens/**  (Widgets, GestureDetector, onTap, etc) │
└──────────────────────────┬──────────────────────────────┘
                           │  context.read<AppProvider>()
                           ▼
┌─────────────────────────────────────────────────────────┐
│               State Management Layer                     │
│  lib/providers/app_provider.dart  (ChangeNotifier)       │
│  lib/providers/theme_provider.dart                       │
└──────────────────────────┬──────────────────────────────┘
                           │  ApiService.methodName()
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   API Service Layer                       │
│  lib/services/api_service.dart                           │
│  Base URL: http://127.0.0.1:8000/v1                      │
│  Auth: Bearer token (SharedPreferences)                  │
└──────────────────────────┬──────────────────────────────┘
                           │  HTTP POST/GET/PUT/DELETE
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Django Backend                          │
│  ppulse_backend/  (REST API)                             │
└─────────────────────────────────────────────────────────┘
```

### Key Files Reference

| Layer              | File                                                        |
|--------------------|-------------------------------------------------------------|
| Attendance Screen  | `lib/screens/attendance/attendance_screen.dart`             |
| Dashboard Screen   | `lib/screens/dashboard/dashboard_screen.dart`               |
| Employee Home      | `lib/screens/home/employee_home.dart`                       |
| Face Verification  | `lib/screens/home/face_verification_dialog.dart`            |
| Apply Leave        | `lib/screens/requests/apply_leave_screen.dart`              |
| Submit Claim       | `lib/screens/requests/submit_claim_screen.dart`             |
| Raise Ticket       | `lib/screens/requests/raise_ticket_screen.dart`             |
| Shift Change       | `lib/screens/requests/shift_change_screen.dart`             |
| Work Type Request  | `lib/screens/requests/work_type_request_screen.dart`        |
| Attendance Request | `lib/screens/requests/attendance_request_screen.dart`       |
| Request Detail     | `lib/screens/requests/request_detail_screen.dart`           |
| Payslip Screen     | `lib/screens/payslip/payslip_screen.dart`                   |
| Payslip PDF Viewer | `lib/screens/payslip/payslip_viewer_screen.dart`            |
| App Provider       | `lib/providers/app_provider.dart`                           |
| API Service        | `lib/services/api_service.dart`                             |
| Notification Svc   | `lib/services/notification_service.dart`                    |
| Main / Routing     | `lib/main.dart`                                             |
| Shell (Nav)        | `lib/screens/shell_screen.dart`                             |

---

## 1. Punch In (Attendance)

> **Scenario:** User is on the Attendance Screen and taps the "CLOCK IN" button.

### Step-by-Step Code Flow

#### Step 1: User Taps the CLOCK IN Button

**File:** `lib/screens/attendance/attendance_screen.dart` ~line 1203-1338

The punch button lives inside the `_ClockInCard` widget (a `StatelessWidget`). It renders:
- A 130x130px circular button with a **green gradient** (`#2A8F7D` to `#1B5E50`)
- `Icons.login_rounded` icon
- Text: **"CLOCK IN"**

```dart
// _ClockInCard widget
GestureDetector(
  onTap: () {
    if (!isPunchedIn) {
      // NOT punched in → show face verification first
      showDialog(
        context: context,
        builder: (_) => const FaceVerificationDialog(),
      );
    } else {
      // Already punched in → punch out directly
      provider.togglePunch();
    }
  },
  child: Container(/* circular button with gradient */),
)
```

**Decision Point:** Since the user is NOT punched in, `isPunchedIn == false`, so a `FaceVerificationDialog` is shown.

---

#### Step 2: Face Verification Dialog

**File:** `lib/screens/home/face_verification_dialog.dart` ~lines 1-127

The dialog shows a camera preview placeholder and a "Verify" button. It has 3 states:
1. **Default** - Shows camera circle + "Verify" button
2. **Verifying** - Shows loading spinner (2 seconds)
3. **Verified** - Shows green checkmark

When user taps **"Verify"**:

```dart
void _startVerification() {
  setState(() => _isVerifying = true);

  // Simulate face verification (2 second delay)
  Future.delayed(const Duration(seconds: 2), () {
    setState(() {
      _isVerifying = false;
      _isVerified = true;
    });

    // After 500ms, trigger the punch and close dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      context.read<AppProvider>().togglePunch();  // ← TRIGGERS PUNCH
      Navigator.of(context).pop();                // ← CLOSES DIALOG
    });
  });
}
```

---

#### Step 3: AppProvider.togglePunch() → punchIn()

**File:** `lib/providers/app_provider.dart` ~lines 231-237

```dart
void togglePunch() {
  if (_isPunchedIn) {
    punchOut();
  } else {
    punchIn();   // ← Called because _isPunchedIn is false
  }
}
```

This calls `punchIn()`:

```dart
Future<void> punchIn() async {
  try {
    await ApiService.punchIn();                           // ← API CALL
    _isPunchedIn = true;                                  // ← UPDATE STATE
    _punchInTime = DateTime.now();                        // ← RECORD TIME
    triggerDynamicIsland(
      'Punched In Successfully',
      Icons.login,
      Color(0xFF34D399),                                  // ← GREEN
    );
    NotificationService.instance.showPunchIn();           // ← LOCAL NOTIFICATION
    notifyListeners();                                    // ← REBUILD UI
  } catch (e) {
    String msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('ALREADY_PUNCHED_IN') || msg.contains('Already clocked in')) {
      _isPunchedIn = true;  // Sync state
      notifyListeners();
      triggerDynamicIsland('Already Clocked In', Icons.info, Color(0xFFFF8C42));
    } else {
      triggerDynamicIsland('Punch In Failed: $msg', Icons.error, Color(0xFFEF4444));
    }
  }
}
```

---

#### Step 4: API Service Call

**File:** `lib/services/api_service.dart` ~lines 197-199

```dart
static Future<Map<String, dynamic>> punchIn() async {
  return await post('/attendance/punch-in', {});
}
```

This calls the generic `post()` method:

```dart
static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
  final token = await _getToken();          // Read from SharedPreferences
  final response = await http.post(
    Uri.parse('$baseUrl$endpoint'),          // → POST http://127.0.0.1:8000/v1/attendance/punch-in
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',      // Auth header
    },
    body: jsonEncode(body),                  // → {}
  );
  return _handleResponse(response);
}
```

**HTTP Request Sent:**
```
POST /v1/attendance/punch-in HTTP/1.1
Host: 127.0.0.1:8000
Content-Type: application/json
Authorization: Bearer <jwt_token>

{}
```

---

#### Step 5: Response Handling

**File:** `lib/services/api_service.dart` ~lines 92-117

```dart
static Map<String, dynamic> _handleResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(response.body);        // ← SUCCESS: Return parsed JSON
  } else if (response.statusCode == 401) {
    // Token expired → attempt refresh → retry
    ...
  } else {
    // Extract error message from: detail, error, non_field_errors, or message
    throw Exception(errorMessage);
  }
}
```

---

#### Step 6: UI Updates (Multiple things happen)

**6a. State Change → Widget Rebuild**

`notifyListeners()` in AppProvider causes all `Consumer<AppProvider>` and `context.watch<AppProvider>()` widgets to rebuild.

The `_ClockInCard` now reads `isPunchedIn == true` and renders:
- **Red gradient** (`#E53935` to `#B71C1C`)
- `Icons.logout_rounded` icon
- Text: **"CLOCK OUT"**
- Status: **"Working"** with elapsed time counter

**6b. Dynamic Island Notification**

```dart
void triggerDynamicIsland(String message, IconData icon, Color color) {
  _showDynamicIsland = true;
  _dynamicIslandMessage = message;    // "Punched In Successfully"
  _dynamicIslandIcon = icon;          // Icons.login
  _dynamicIslandColor = color;        // Green
  notifyListeners();

  Future.delayed(const Duration(seconds: 3), () {
    _showDynamicIsland = false;
    notifyListeners();                // Auto-hide after 3 seconds
  });
}
```

A green banner slides down from the top: **"Punched In Successfully"**

**6c. Local Push Notification**

**File:** `lib/services/notification_service.dart` ~lines 176-186

```dart
Future<void> showPunchIn() => show(
  title: 'Punched In',
  body: 'You have successfully punched in. Have a productive day!',
  payload: 'punch_in',
);
```

- Android: High-importance heads-up notification with LED light
- iOS: Alert with badge and sound
- Device vibrates for 300ms

**6d. Attendance Screen Auto-Reload**

**File:** `lib/screens/attendance/attendance_screen.dart` ~lines 50-58

```dart
void didChangeDependencies() {
  super.didChangeDependencies();
  final isPunchedIn = context.read<AppProvider>().isPunchedIn;
  if (_lastPunchedIn != null && _lastPunchedIn != isPunchedIn) {
    _loadAttendanceData();   // ← Reloads calendar, daily logs, charts
  }
  _lastPunchedIn = isPunchedIn;
}
```

The attendance calendar, punch time logs, and work hours display all refresh.

---

### Visual Summary: Punch In Flow

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│ User taps    │────▶│ FaceVerification │────▶│ AppProvider   │
│ CLOCK IN     │     │ Dialog (2s wait) │     │ .togglePunch()│
│ button       │     │ then calls       │     │ → punchIn()   │
└──────────────┘     │ togglePunch()    │     └───────┬───────┘
                     └──────────────────┘             │
                                                      ▼
                     ┌──────────────────┐     ┌──────────────────┐
                     │ ApiService       │────▶│ Django Backend    │
                     │ .punchIn()       │     │ POST /v1/         │
                     │                  │◀────│ attendance/       │
                     │ Returns JSON     │     │ punch-in          │
                     └────────┬─────────┘     └──────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │ On Success:                   │
              │ 1. _isPunchedIn = true        │
              │ 2. _punchInTime = now         │
              │ 3. Dynamic Island (green, 3s) │
              │ 4. Local notification         │
              │ 5. notifyListeners()          │
              │    → Button turns RED         │
              │    → Text → "CLOCK OUT"       │
              │    → Status → "Working"       │
              │    → Timer starts counting    │
              │    → Calendar reloads         │
              └───────────────────────────────┘
```

---

## 2. Punch Out (Attendance)

> **Scenario:** User is already clocked in and taps the "CLOCK OUT" button.

### Flow

```
User taps CLOCK OUT button (red, Icons.logout_rounded)
  │
  ▼  (isPunchedIn == true, so NO face verification needed)
GestureDetector.onTap → provider.togglePunch()
  │
  ▼  AppProvider (app_provider.dart ~line 231)
togglePunch() → _isPunchedIn is true → calls punchOut()
  │
  ▼  AppProvider.punchOut() (app_provider.dart ~line 210-229)
  │  await ApiService.punchOut()
  │    │
  │    ▼  api_service.dart ~line 201
  │    POST /v1/attendance/punch-out  (empty body, Bearer token)
  │    │
  │    ▼  Backend processes → returns 200 OK
  │
  ▼  On success:
  _isPunchedIn = false
  _punchInTime = null
  triggerDynamicIsland('Punched Out Successfully', Icons.logout, Orange)
  NotificationService.instance.showPunchOut()
    → title: 'Punched Out'
    → body: 'You have successfully punched out. See you tomorrow!'
  notifyListeners()
    → Button turns GREEN again
    → Text → "CLOCK IN"
    → Status → "Not Clocked In"
    → Timer stops
    → Attendance screen reloads via didChangeDependencies()
```

**Error Handling:**
- If error contains `'NOT_PUNCHED_IN'` or `'without punching in'` → syncs state to `_isPunchedIn = false`
- Otherwise → shows "Punch Out Failed" in Dynamic Island (red)

---

## 3. Apply Leave

> **Scenario:** User navigates to Apply Leave screen, fills out the form, and submits.

### Navigation Path

```
DashboardScreen → Quick Actions Grid → "Leave" card → Navigator.push(ApplyLeaveScreen)
```

### Step-by-Step Flow

**File:** `lib/screens/requests/apply_leave_screen.dart`

#### Step 1: Screen Loads → Fetch Leave Types

```dart
@override
void initState() {
  super.initState();
  _loadLeaveTypes();
}

Future<void> _loadLeaveTypes() async {
  final response = await ApiService.getLeaveTypes();
  // GET /v1/leave-types
  // Response: { "leave_types": [{"id": 1, "name": "Casual Leave"}, ...] }
  setState(() => _leaveTypes = response['leave_types']);
}
```

#### Step 2: User Fills the Form

Form fields:
- **Leave Type** (dropdown) - Casual, Sick, Earned, etc.
- **Start Date** (date picker)
- **End Date** (date picker)
- **Day Breakdown** (Full Day / First Half / Second Half)
- **Reason** (text field, required)

#### Step 3: User Taps "Submit"

```dart
void _submitLeave() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    await ApiService.applyLeave({
      'leave_type': _selectedLeaveType,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'breakdown': _breakdown,       // 'full_day', 'first_half', 'second_half'
      'reason': _reasonController.text,
    });
    // POST /v1/leaves/apply

    // Show success overlay animation
    _showSuccessOverlay();

    // Trigger local notification
    NotificationService.instance.showRequestApplied('Leave');

    // Refresh notifications in provider
    await ApiService.getNotifications();

    // Go back to previous screen
    Navigator.of(context).pop();
  } catch (e) {
    // Show error in snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

#### API Call

```
POST /v1/leaves/apply HTTP/1.1
Authorization: Bearer <token>
Content-Type: application/json

{
  "leave_type": "Casual Leave",
  "start_date": "2026-04-05T00:00:00.000",
  "end_date": "2026-04-06T00:00:00.000",
  "breakdown": "full_day",
  "reason": "Family function"
}
```

#### After Success

1. **SuccessOverlay** animation plays (green checkmark)
2. **Local notification**: "Request Applied - Your Leave request has been submitted successfully"
3. **Navigator.pop()** returns to Dashboard
4. The leave appears in **Requests → My Requests** tab (`GET /requests?role=self`)

---

## 4. Submit Expense Claim

> **Scenario:** User submits an expense claim with attachments.

**File:** `lib/screens/requests/submit_claim_screen.dart`

### Flow

```
DashboardScreen → "Claims" quick action → Navigator.push(SubmitClaimScreen)
  │
  ▼  initState()
  GET /v1/employees (loads employee list for dropdown)
  │
  ▼  User fills form:
  │   - Claim Type (dropdown: Travel, Food, Medical, etc.)
  │   - Amount (number input)
  │   - Date (date picker)
  │   - Description (text field)
  │   - Attachments (image picker: gallery or camera)
  │
  ▼  User taps "Submit"
  │
  ▼  _submitClaim()
  │   POST /v1/claims/submit
  │   Body: { claim_type, amount, date, description, attachments[] }
  │
  ▼  On success:
      → SuccessOverlay animation
      → NotificationService.showRequestApplied('Claim')
      → Navigator.pop()
```

**Attachment Handling:**
- Uses `image_picker` package
- User can pick from gallery or take a photo
- Images are sent as part of the multipart form data or base64 encoded

---

## 5. Raise Support Ticket

> **Scenario:** User raises an IT/HR support ticket.

**File:** `lib/screens/requests/raise_ticket_screen.dart`

### Flow

```
DashboardScreen → "Tickets" quick action → Navigator.push(RaiseTicketScreen)
  │
  ▼  User fills form:
  │   - Title (text field)
  │   - Description (text area)
  │   - Priority (dropdown: Low, Medium, High, Critical)
  │   - Attachments (optional images)
  │
  ▼  User taps "Submit"
  │
  ▼  POST /v1/tickets/raise
  │   Body: { title, description, priority, attachments[] }
  │
  ▼  On success:
      → SuccessOverlay animation
      → NotificationService.showRequestApplied('Ticket')
      → Navigator.pop()
```

---

## 6. Request Shift Change

**File:** `lib/screens/requests/shift_change_screen.dart`

### Flow

```
DashboardScreen → "Shift" quick action → Navigator.push(ShiftChangeScreen)
  │
  ▼  initState()
  GET /v1/shifts  →  Loads available shifts (Morning, Evening, Night, etc.)
  │
  ▼  User fills form:
  │   - Desired Shift (dropdown from API response)
  │   - Reason (text field)
  │
  ▼  User taps "Submit"
  │
  ▼  POST /v1/shifts/request
  │   Body: { shift_id, reason }
  │
  ▼  On success:
      → SuccessOverlay → Notification → Navigator.pop()
```

---

## 7. Request Work Type Change

**File:** `lib/screens/requests/work_type_request_screen.dart`

### Flow

```
DashboardScreen → "Work Type" quick action → Navigator.push(WorkTypeRequestScreen)
  │
  ▼  initState()
  GET /v1/work-types  →  Loads work types (WFO, WFH, Hybrid)
  │
  ▼  User fills form:
  │   - Work Type (dropdown)
  │   - Reason (text field)
  │
  ▼  User taps "Submit"
  │
  ▼  POST /v1/work-type/request
  │   Body: { work_type, reason }
  │
  ▼  On success:
      → SuccessOverlay → Notification → Navigator.pop()
```

---

## 8. Attendance Regularization

> **Scenario:** User missed a punch and wants to regularize attendance for a past date.

**File:** `lib/screens/requests/attendance_request_screen.dart`

### Flow

```
DashboardScreen → "Attendance" quick action → Navigator.push(AttendanceRequestScreen)
  │
  ▼  initState()  (parallel API calls)
  │   GET /v1/employees
  │   GET /v1/shifts
  │   GET /v1/work-types
  │
  ▼  User fills form:
  │   - Attendance Date (date picker, past dates only)
  │   - Shift (dropdown)
  │   - Status (Present / Half Day)
  │   - Check-in Time (time picker)
  │   - Check-out Time (time picker)
  │   - Reason (text field, required)
  │
  ▼  User taps "Submit"
  │
  ▼  POST /v1/attendance/regularize
  │   Body: {
  │     attendance_date, shift, status,
  │     check_in_time, check_out_time, reason
  │   }
  │
  ▼  On success:
      → SuccessOverlay → Notification → Navigator.pop()
```

---

## 9. Approve / Reject a Request (Manager/HR)

> **Scenario:** A Manager opens a pending leave request and approves or rejects it.

**File:** `lib/screens/requests/request_detail_screen.dart`

### Flow

```
RequestsScreen → "Requested" tab → Tap on a pending request
  │
  ▼  Navigator.push(RequestDetailScreen(requestId: id))
  │
  ▼  initState()
  GET /v1/requests/{id}  →  Full request details
  │   Response: {
  │     id, type, title, status,
  │     employee: { name, department, designation },
  │     start_date, end_date, reason, attachments,
  │     created_date
  │   }
  │
  ▼  Screen renders:
  │   - Employee info card
  │   - Request details (dates, reason, etc.)
  │   - Attachments preview
  │   - Two action buttons: [Accept] [Reject]
  │
  ▼  OPTION A: Manager taps "Accept"
  │   PUT /v1/requests/{id}/accept
  │   → On success: Show notification, pop screen
  │
  ▼  OPTION B: Manager taps "Reject"
  │   → Shows text field for rejection reason
  │   → Manager enters reason, taps confirm
  │   PUT /v1/requests/{id}/reject
  │   Body: { reason: "Insufficient leave balance" }
  │   → On success: Show notification, pop screen
```

---

## 10. View Payslip & Download PDF

**Files:** `lib/screens/payslip/payslip_screen.dart`, `lib/screens/payslip/payslip_viewer_screen.dart`

### Flow

```
ShellScreen → Payslips tab (index 3)
  │
  ▼  PayslipScreen.initState()
  GET /v1/payslips/list?year=2026
  │   → List of all payslips for the year
  GET /v1/payslips?month=4&year=2026
  │   → Current month payslip details
  │   Response: {
  │     basic_pay, hra, da, special_allowance,
  │     total_gross, pf, tax, total_deductions,
  │     net_pay, month, year
  │   }
  │
  ▼  Screen renders:
  │   - Month navigator (< April 2026 >)
  │   - Earnings breakdown (Basic, HRA, DA, etc.)
  │   - Deductions breakdown (PF, Tax, etc.)
  │   - Net Pay summary
  │   - "View PDF" button
  │
  ▼  User taps "View PDF"
  │
  ▼  Navigator.push(PayslipViewerScreen(payslipId: id))
  │
  ▼  GET /v1/payslips/{id}/pdf
  │   → Returns PDF bytes
  │   → Rendered using PDF viewer widget
  │   → Option to download/share
```

---

## 11. Login

**File:** `lib/screens/auth/login_screen.dart`

### Flow

```
App launches → SplashScreen
  │
  ▼  Check SharedPreferences for auth_token
  │   - Token exists & valid → ShellScreen
  │   - No token → LoginScreen
  │
  ▼  LoginScreen
  │   User enters: username + password
  │   Taps "Login"
  │
  ▼  POST /v1/auth/login
  │   Body: { username: "john", password: "****" }
  │   Response: {
  │     auth_token: "eyJ...",
  │     refresh_token: "eyJ...",
  │     user: { id, name, email, role, designation, department }
  │   }
  │
  ▼  On success:
  │   1. Save tokens to SharedPreferences
  │   2. Save user data to SharedPreferences
  │   3. AppProvider.login() → _isLoggedIn = true
  │   4. AppProvider.fetchDashboardData() → loads all initial data
  │   5. Navigator.pushReplacement(ShellScreen)
  │
  ▼  On error:
      → Shake animation on input fields
      → Error message displayed
```

---

## 12. Logout

**File:** `lib/screens/settings/settings_screen.dart`

### Flow

```
ProfileSheet → Settings icon → SettingsScreen
  │
  ▼  User taps "Logout"
  │
  ▼  AppProvider.logout()
  │   1. POST /v1/auth/logout (best effort, fire-and-forget)
  │   2. Clear all state variables (name, role, punch status, etc.)
  │   3. SharedPreferences.clear() → removes tokens + user data
  │   4. Navigator.pushAndRemoveUntil(LoginScreen) → clears nav stack
```

---

## 13. Notification Polling & Tap

**File:** `lib/screens/shell_screen.dart`, `lib/services/notification_service.dart`

### Polling Flow (Every 10 seconds)

```
ShellScreen.initState()
  │
  ▼  Timer.periodic(Duration(seconds: 10), (_) => _pollNotifications())
  │
  ▼  _pollNotifications()
  │   GET /v1/notifications
  │   Response: {
  │     unread_count: 3,
  │     notifications: [{ id, title, body, timestamp, read }, ...]
  │   }
  │
  ▼  Compare with _seenNotifIds set
  │   For each NEW unread notification:
  │     → NotificationService.show(title, body, payload)
  │     → Add to _seenNotifIds
  │
  ▼  Update AppProvider:
      _notifications = response.notifications
      _unreadNotifications = response.unread_count
      notifyListeners()
        → Bell icon badge updates
```

### Notification Tap Flow

```
User taps a push notification
  │
  ▼  NotificationService.onNotificationTap callback
  │   (set in main.dart initState)
  │
  ▼  AppProvider.navigateToRequested()
  │   _bottomNavIndex = 1          // Switch to Requests tab
  │   notifyListeners()
  │
  ▼  RequestsScreen loads and shows the request
```

---

## 14. Dashboard Data Load

> **Scenario:** App launches or user pulls to refresh dashboard.

**File:** `lib/providers/app_provider.dart` ~lines 70-186

### Flow

```
App launch / Login / Pull-to-refresh
  │
  ▼  AppProvider.fetchDashboardData()
  │
  ▼  Parallel API calls:
  │
  ├─ GET /v1/dashboard/summary
  │   → attendance status (clocked_in/out, punch_in time)
  │   → leave balance (total_remaining, percentage)
  │   → leave summary by type
  │   → recent activity
  │   → pending approvals count (managers only)
  │
  ├─ GET /v1/leaves/balance
  │   → detailed leave breakdown per type
  │
  ├─ GET /v1/users/me
  │   → user profile (name, role, designation, department, avatar)
  │   → determines role: employee / manager / hr
  │
  ├─ GET /v1/attendance/monthly
  │   → monthly attendance history for calendar
  │
  ├─ GET /v1/notifications
  │   → notification list + unread count
  │
  ├─ GET /v1/requests?type=Claims
  │   → claims count
  │
  └─ GET /v1/requests?type=Tickets
      → tickets count
  │
  ▼  All responses parsed and state updated:
  │   _userName, _designation, _department, _role
  │   _isPunchedIn, _punchInTime
  │   _leaveBalance, _leaveBalances, _approvedLeaves, _pendingLeaves
  │   _claimRequests, _tickets
  │   _pendingApprovals (managers)
  │   _recentAttendance
  │   _notifications, _unreadNotifications
  │
  ▼  notifyListeners()
      → Entire dashboard rebuilds with fresh data
```

---

## API Authentication & Error Handling

### Token Flow

```
Login → receives auth_token + refresh_token → stored in SharedPreferences

Every API call:
  1. Read auth_token from SharedPreferences
  2. Add header: Authorization: Bearer <auth_token>
  3. If response is 401 (Unauthorized):
     a. POST /v1/auth/refresh with refresh_token
     b. Save new auth_token
     c. Retry original request with new token
  4. If refresh also fails → redirect to LoginScreen
```

### Base URL Configuration

```dart
// api_service.dart
static String get baseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/v1';    // Android emulator → host machine
  }
  return 'http://127.0.0.1:8000/v1';     // iOS simulator / Web
}
```

### Error Response Parsing

The API service checks response fields in this order: `detail` → `error` → `non_field_errors` → `message`. The first non-null value becomes the exception message.

---

## Role-Based UI Differences

| Feature                  | Employee | Manager | HR  |
|--------------------------|----------|---------|-----|
| Punch In/Out             | Yes      | Yes     | Yes |
| Apply Leave/Claims/etc.  | Yes      | Yes     | Yes |
| View Own Requests        | Yes      | Yes     | Yes |
| Approve/Reject Requests  | No       | Yes     | Yes |
| Team Attendance          | No       | Yes     | Yes |
| Team Directory           | No       | Yes     | Yes |
| Analytics                | No       | Yes     | Yes |
| HR Attendance Dashboard  | No       | No      | Yes |
| HR Claims Overview       | No       | No      | Yes |
| HR Employee Directory    | No       | No      | Yes |

Role is determined from `GET /v1/users/me` response during `fetchDashboardData()` and stored in `AppProvider._role`.

---

## Complete API Endpoint Reference

| Action                    | Method | Endpoint                        | Auth |
|---------------------------|--------|---------------------------------|------|
| Login                     | POST   | `/v1/auth/login`                | No   |
| Logout                    | POST   | `/v1/auth/logout`               | Yes  |
| Refresh Token             | POST   | `/v1/auth/refresh`              | Yes  |
| Change Password           | POST   | `/v1/auth/change-password`      | Yes  |
| Get Current User          | GET    | `/v1/users/me`                  | Yes  |
| Get Employees             | GET    | `/v1/employees`                 | Yes  |
| Get Employee              | GET    | `/v1/employees/{id}`            | Yes  |
| Punch In                  | POST   | `/v1/attendance/punch-in`       | Yes  |
| Punch Out                 | POST   | `/v1/attendance/punch-out`      | Yes  |
| Today Attendance          | GET    | `/v1/attendance/today`          | Yes  |
| Monthly Attendance        | GET    | `/v1/attendance/monthly`        | Yes  |
| Weekly Attendance         | GET    | `/v1/attendance/weekly`         | Yes  |
| Team Attendance           | GET    | `/v1/attendance/team`           | Yes  |
| Regularize Attendance     | POST   | `/v1/attendance/regularize`     | Yes  |
| Get Leave Balance         | GET    | `/v1/leaves/balance`            | Yes  |
| Apply Leave               | POST   | `/v1/leaves/apply`              | Yes  |
| Get Leave Types           | GET    | `/v1/leave-types`               | Yes  |
| Submit Claim              | POST   | `/v1/claims/submit`             | Yes  |
| Raise Ticket              | POST   | `/v1/tickets/raise`             | Yes  |
| Request Shift Change      | POST   | `/v1/shifts/request`            | Yes  |
| Get Shifts                | GET    | `/v1/shifts`                    | Yes  |
| Request Work Type         | POST   | `/v1/work-type/request`         | Yes  |
| Get Work Types            | GET    | `/v1/work-types`                | Yes  |
| Request Asset             | POST   | `/v1/assets/request`            | Yes  |
| Get Requests              | GET    | `/v1/requests`                  | Yes  |
| Get Request Detail        | GET    | `/v1/requests/{id}`             | Yes  |
| Accept Request            | PUT    | `/v1/requests/{id}/accept`      | Yes  |
| Reject Request            | PUT    | `/v1/requests/{id}/reject`      | Yes  |
| Cancel Request            | DELETE | `/v1/requests/{id}/cancel`      | Yes  |
| Get Payslip               | GET    | `/v1/payslips`                  | Yes  |
| Get Payslips List         | GET    | `/v1/payslips/list`             | Yes  |
| Get Payslip PDF           | GET    | `/v1/payslips/{id}/pdf`         | Yes  |
| Get Notifications         | GET    | `/v1/notifications`             | Yes  |
| Mark Notification Read    | PUT    | `/v1/notifications/{id}/read`   | Yes  |
| Mark All Read             | PUT    | `/v1/notifications/read-all`    | Yes  |
| Register Device           | POST   | `/v1/notifications/register-device` | Yes |
| Dashboard Summary         | GET    | `/v1/dashboard/summary`         | Yes  |
| Dashboard Announcements   | GET    | `/v1/dashboard/announcements`   | Yes  |
| Dashboard Analytics       | GET    | `/v1/dashboard/analytics`       | Yes  |
| Get Departments           | GET    | `/v1/departments`               | Yes  |
| Get Settings              | GET    | `/v1/settings`                  | Yes  |
| Update Settings           | POST   | `/v1/settings`                  | Yes  |
