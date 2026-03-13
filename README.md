# PPulse HRMS

A Flutter-based Human Resource Management System demo application featuring role-based dashboards, attendance tracking, leave management, payroll views, and animated UI transitions.

## Demo Credentials

| Role     | Username   | Password |
|----------|------------|----------|
| Employee | `employee` | `12345`  |
| Manager  | `manager`  | `12345`  |
| HR       | `hr`       | `12345`  |

## Features

- **Role-Based Dashboard** — Adaptive widgets for Employee, Manager, and HR roles
- **Attendance** — Punch timer, daily logs, face verification dialog
- **Leave & Requests** — Apply for leave, claims, tickets, shift changes, and more
- **Payroll** — Monthly payslips with detailed breakdowns
- **Manager Tools** — Team directory, approvals, attendance overview, performance analytics
- **HR Tools** — Company-wide metrics, employee directory, claims overview, leave analytics
- **Profile & Settings** — User profile, company directory, dark/light theme toggle
- **Notifications** — Dynamic island-style notification overlay
- **Animated Transitions** — Smooth number animations and screen transitions

## Tech Stack

- **Flutter** (SDK ^3.11.0)
- **Provider** for state management
- **fl_chart** for data visualizations
- **flutter_animate** for animations
- **google_fonts** and **Material Design 3**

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Dart SDK (bundled with Flutter)

### Run the app

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── theme/              # App theming
├── providers/          # State management (AppProvider, ThemeProvider)
├── widgets/            # Reusable widgets (NeuCard, BottomNav, DynamicIsland)
└── screens/
    ├── splash/         # Splash screen
    ├── auth/           # Login
    ├── dashboard/      # Unified role-based dashboard
    ├── home/           # Employee home, face verification
    ├── attendance/     # Attendance logs and analytics
    ├── requests/       # Leave, requests, apply forms
    ├── payslip/        # Salary slips
    ├── profile/        # Profile screen and sheet
    ├── directory/      # Company directory
    ├── settings/       # App settings
    ├── manager/        # Team directory, approvals, analytics
    ├── hr/             # HR dashboard, claims, employee directory
    └── shell_screen.dart  # Root container with bottom navigation
```

## Navigation

The app uses a **Shell Screen** as the root container with bottom navigation across four tabs: Dashboard, Requests, Attendance, and Payroll. The AppBar provides access to notifications and the profile sheet.

See [SITEMAP2.md](SITEMAP2.md) for the full navigation flow and screen inventory (22 screens across 3 roles).
