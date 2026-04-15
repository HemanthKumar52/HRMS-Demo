# PPULSE HRMS

A cross-platform HRMS mobile application built with **Flutter** and **Django REST Framework**, featuring platform-adaptive UI (iOS Liquid Glass + Material Design), Live Activities, real-time notifications, and role-based dashboards.

## Architecture

```
lib/
├── controllers/          # Business logic layer
│   ├── auth_controller.dart
│   ├── attendance_controller.dart
│   ├── dashboard_controller.dart
│   ├── leave_controller.dart
│   ├── live_activity_controller.dart
│   └── notification_controller.dart
├── providers/            # State management (ChangeNotifier)
│   ├── app_provider.dart
│   └── theme_provider.dart
├── services/             # API & platform services
│   ├── api_service.dart
│   ├── live_activity_service.dart
│   └── notification_service.dart
├── screens/              # UI screens by feature
│   ├── auth/
│   ├── dashboard/
│   ├── attendance/
│   ├── requests/
│   ├── payslip/
│   ├── directory/
│   ├── manager/
│   ├── settings/
│   └── shell_screen.dart
├── widgets/              # Reusable UI components
├── utils/                # Platform adaptive, responsive utilities
├── theme/                # App theme (light/dark)
└── animations/           # Custom animations & transitions

ppulse_backend/           # Django REST API
ios/AttendanceWidget/     # iOS Live Activity Widget Extension
```

## Features

### Core
- **Role-Based Dashboard** - Adaptive widgets for Employee, Manager, and HR
- **Attendance Tracking** - Punch in/out with timer, daily/monthly logs, face verification
- **Leave Management** - Apply, track, approve/reject with real-time notifications
- **Requests** - Claims, tickets, shift changes, work type changes, attendance requests
- **Payroll** - Monthly payslips with earnings/deductions breakdown charts
- **Announcements** - Real-time announcements from admin/HR (from database)
- **Notifications** - Push notifications with polling, mark read, notification center

### Platform-Adaptive UI
- **iOS**: Liquid glass nav bar & tab bar (BackdropFilter blur), CupertinoDatePicker, CupertinoAlertDialog, CupertinoButton tap feedback, Cupertino page transitions, haptic feedback
- **Android**: Material Design, neomorphic cards, floating bottom nav, Material date/time pickers

### Live Activities (iOS + Android)
- **iOS**: Dynamic Island + Lock Screen Live Activity for attendance timer
- **Android**: Ongoing notification with chronometer and progress bar
- **Features**: Leave request tracking, shift reminders, payroll notifications

### Other
- **Responsive** - Adapts to phone, tablet, and desktop screen sizes
- **Dark/Light Theme** - Full theme support with neomorphic styling
- **Microsoft SSO** - Single sign-on via Microsoft Azure AD
- **Org Chart** - Visual organization hierarchy

## Prerequisites

- Flutter 3.41+ / Dart 3.11+
- Python 3.12+ / Django 5.x
- PostgreSQL (backend database)
- Xcode 16+ (for iOS builds)
- Android Studio (for Android builds)

## Setup

### 1. Backend

```bash
cd ppulse_backend
python -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt

# Configure database in .env or settings.py
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### 2. Flutter App

```bash
# Install dependencies
flutter pub get

# Run on iOS Simulator
open -a Simulator
flutter run -d iPhone

# Run on Android Emulator
flutter run -d emulator-5554

# Run on both
flutter run -d all
```

### 3. iOS Live Activity Setup (Xcode)

The Widget Extension target is pre-configured. To enable signing:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **AttendanceWidget** target -> Signing & Capabilities
3. Set your development **Team**
4. Add **App Groups** capability -> `group.com.ppulse.hrmsDemo`
5. Repeat step 3-4 for the **Runner** target
6. Build & run

## API Configuration

The app connects to `localhost:8000` by default:
- **iOS Simulator**: `http://127.0.0.1:8000/v1`
- **Android Emulator**: `http://10.0.2.2:8000/v1` (Android's localhost alias)

To change, edit `lib/services/api_service.dart`.

## Demo Credentials

All passwords follow the pattern **`<username>23`** (e.g. username `admin` → password `admin23`).

### Super Admin

| Username | Password | Role | Department |
|----------|----------|------|------------|
| `admin` | `admin23` | **Super Admin** | Engineering |

### Managers

| Username | Password | Role | Department |
|----------|----------|------|------------|
| `vikram` | `vikram23` | Manager | Sales |
| `suresh` | `suresh23` | Manager | Legal |

### Employees

| Username | Password | Role | Department |
|----------|----------|------|------------|
| `rahul` | `rahul23` | Employee | Engineering |
| `priya` | `priya23` | Employee | Human Resources |
| `amit` | `amit23` | Employee | Finance |
| `sneha` | `sneha23` | Employee | Marketing |
| `ananya` | `ananya23` | Employee | Operations |
| `karthik` | `karthik23` | Employee | Design |
| `divya` | `divya23` | Employee | Product |
| `meera` | `meera23` | Employee | Engineering |
| `raj` | `raj23` | Employee | Human Resources |
| `neha` | `neha23` | Employee | Finance |
| `arun` | `arun23` | Employee | Marketing |
| `kavitha` | `kavitha23` | Employee | Sales |
| `deepak` | `deepak23` | Employee | Operations |

## Project Structure

| Directory | Description |
|-----------|-------------|
| `lib/` | Flutter mobile app source code |
| `ppulse_backend/` | Django REST API backend |
| `ppulse-web/` | Django web application (admin portal) |
| `ios/` | iOS native code + Widget Extension |
| `android/` | Android native code |
| `assets/` | Static assets (images, icons) |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.41, Dart 3.11 |
| State | Provider (ChangeNotifier) |
| Backend | Django 5.x, Django REST Framework |
| Database | PostgreSQL |
| Auth | JWT (SimpleJWT) + Microsoft SSO |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Live Activities | live_activities (iOS) + ongoing notifications (Android) |
| Animations | flutter_animate |

## License

See [LICENSE](LICENSE) for details.
