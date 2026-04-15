# PPULSE HRMS — Architecture Document

## 1. System Architecture

### Overview
PPULSE follows a three-tier architecture: mobile client (Flutter), REST API (Django), and relational database (PostgreSQL). Face verification runs as an embedded service within the API tier using insightface's buffalo_l model.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      CLIENT TIER                              │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐     │
│  │   Flutter    │  │   Flutter   │  │  SwiftUI Native  │     │
│  │   Android    │  │     iOS     │  │  Platform Views  │     │
│  └──────┬───────┘  └──────┬──────┘  └────────┬─────────┘     │
│         │                 │                   │               │
│  ┌──────▼─────────────────▼───────────────────▼──────────┐   │
│  │              Provider (AppProvider)                     │   │
│  │         ApiService (HTTP + JWT + Retry)                 │   │
│  └──────────────────────┬────────────────────────────────┘   │
└─────────────────────────┼────────────────────────────────────┘
                          │ HTTPS + JSON
┌─────────────────────────▼────────────────────────────────────┐
│                       API TIER                                │
│                                                               │
│  ┌──────────────┐  ┌────────────┐  ┌───────────────────┐    │
│  │ Django Views  │  │ DRF Serial │  │ Face Verification │    │
│  │ (78 endpoints)│  │ -izers     │  │ Engine            │    │
│  └──────┬────────┘  └─────┬──────┘  └────────┬──────────┘   │
│         │                 │                   │              │
│  ┌──────▼─────────────────▼───────────────────▼──────────┐   │
│  │               Django ORM + Migrations                  │   │
│  └──────────────────────┬────────────────────────────────┘   │
└─────────────────────────┼────────────────────────────────────┘
                          │ SQL
┌─────────────────────────▼────────────────────────────────────┐
│                     DATA TIER                                 │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              PostgreSQL 16                            │    │
│  │  38 tables | Indexed FK relationships | JSONB audit   │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## 2. Mobile Architecture

### State Management
- **Pattern:** Provider (ChangeNotifier) — single AppProvider manages all app state
- **Data Flow:** UI → AppProvider.method() → ApiService.endpoint() → setState() → rebuild
- **Timers:** Notification polling (10s), heartbeat (60s), attendance polling (30s)

### Navigation
- **Shell Pattern:** ShellScreen wraps IndexedStack of 4 tabs (Dashboard, Requests, Attendance, Payroll)
- **Admin:** Separate AdminPanelScreen with own bottom nav (Overview, Users, Audit, Settings)
- **Platform Adaptive:** iOS uses CupertinoTabBar, Android uses FloatingBottomNav

### Platform Views (iOS)
```
Flutter UiKitView
  └── NativeAttendanceViewFactory (FlutterPlatformViewFactory)
      └── NativeAttendancePlatformView (FlutterPlatformView)
          └── UIHostingController<AttendanceCheckInView>
              └── AttendanceCheckInViewModel (ObservableObject)
                  └── FlutterMethodChannel (bidirectional)
```

## 3. Backend Architecture

### Request Pipeline
```
Request → CORS Middleware → Auth Middleware (JWT) → URL Router → View → Serializer → ORM → Response
```

### Face Verification Pipeline
```
Image(s) → decode → adaptive_gamma → CLAHE → white_balance → quality_gate
  → screen_replay_score (per frame) → multi_frame_liveness (cross-frame)
  → extract_embedding (RetinaFace detect → ArcFace embed)
  → cosine_match (vs EmployeeFaceData) → identity_verify → result
```

## 4. Database Architecture

### Key Relationships
- User 1:1 Employee (via employee_user_id)
- Employee 1:N Attendance (via employee_id_id)
- Employee 1:1 EmployeeFaceData (via employee_id_id, unique)
- EmployeeWorkInformation.reporting_manager_id → Employee (self-referential for org hierarchy)
- All request types (Leave, Claim, Ticket, Shift, WorkType, Asset, AttendanceRequest) → Employee

### Indexing Strategy
- Primary keys: auto-increment BigInteger
- Foreign keys: indexed by default (Django)
- Query-critical: (employee_id_id, attendance_date) on Attendance
- Unique constraints: (employee_id_id) on EmployeeFaceData

## 5. Security Architecture

### Authentication Chain
```
Login → PBKDF2 verify → check lockout → compute role → issue JWT (with token_version)
  → client stores in SharedPreferences → sent as Bearer header
  → VersionedJWTAuthentication checks token_version matches DB
  → if mismatch → 401 (forced logout)
```

### Defense Layers
1. **Transport:** HTTPS (TLS 1.3)
2. **Authentication:** JWT with 30-day expiry + token versioning
3. **Authorization:** Role-based view access
4. **Rate Limiting:** Account lockout after N failures
5. **Audit:** Every action logged with IP + user-agent
6. **Data:** GDPR export/delete, retention policies

---

**PPULSE Technologies** | Architecture Document v1.0
