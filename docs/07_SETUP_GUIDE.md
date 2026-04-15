# PPULSE HRMS — Setup & Installation Guide

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter | 3.41+ | Mobile app framework |
| Dart | 3.11+ | Programming language |
| Python | 3.12+ | Backend runtime |
| PostgreSQL | 16+ | Database |
| Xcode | 16+ | iOS builds |
| Android Studio | Latest | Android builds + emulator |
| CocoaPods | 1.15+ | iOS dependency manager |

## 1. Clone Repository

```bash
git clone https://github.com/HemanthKumar52/HRMS-Demo.git
cd HRMS-Demo
```

## 2. Backend Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
cd ppulse_backend
pip install -r requirements.txt

# Configure database (edit .env or settings.py)
# Default: SQLite for development, PostgreSQL for production

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
# Username: admin, Password: admin23

# (Optional) Register face embeddings
python manage.py register_faces --dir ./registered_faces

# Start server
python manage.py runserver 0.0.0.0:8000
```

## 3. Flutter App Setup

```bash
cd ..  # back to project root

# Install dependencies
flutter pub get

# iOS: Install CocoaPods
cd ios && pod install && cd ..

# Run on iOS Simulator
open -a Simulator
flutter run -d iPhone

# Run on Android Emulator
flutter emulators --launch Pixel_9_Pro
flutter run -d emulator-5554 --dart-define=API_HOST=10.0.2.2
```

## 4. API Configuration

| Platform | API Base URL |
|----------|-------------|
| iOS Simulator | `http://127.0.0.1:8000/v1` |
| Android Emulator | `http://10.0.2.2:8000/v1` |
| Physical Device | `http://<your-ip>:8000/v1` |

To override: `flutter run --dart-define=API_HOST=192.168.1.100`

## 5. Demo Credentials

All passwords follow `<username>23`:

| Username | Password | Role |
|----------|----------|------|
| admin | admin23 | Super Admin |
| vikram | vikram23 | Manager |
| suresh | suresh23 | Manager |
| rahul | rahul23 | Employee |
| priya | priya23 | Employee |
| *(14 more)* | *same pattern* | Employee |

## 6. Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ipa --release --no-codesign
```

---

**PPULSE Technologies**
