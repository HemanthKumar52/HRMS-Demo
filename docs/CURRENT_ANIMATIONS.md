# PPulse HRMS Mobile App - Current Animations Inventory

> Generated: 2026-03-31 | Total Animation Instances: 200+ across 26 files

---

## Table of Contents
1. [Animation Summary](#animation-summary)
2. [AnimationController (Manual)](#1-animationcontroller-manual-animations)
3. [flutter_animate Package](#2-flutter_animate-package-usage)
4. [TweenAnimationBuilder](#3-tweenanimationbuilder-counter-animations)
5. [Implicit Animations](#4-implicit-animations)
6. [Page Transitions](#5-page-transitions)
7. [Custom Painters](#6-custom-painters-static)
8. [Skeleton/Shimmer Loading](#7-skeletonshimmer-loading)
9. [What's Missing](#8-whats-missing---animations-not-yet-implemented)

---

## Animation Summary

| Animation Type | Count | Files Used |
|---|---|---|
| AnimationController (manual) | 4 controllers | 4 files |
| flutter_animate (.fadeIn, .slideY, .slideX) | 149+ instances | 20 files |
| TweenAnimationBuilder (counters) | 23+ instances | 10+ files |
| AnimatedBuilder | 4 instances | 1 file |
| FadeTransition | 3 | 2 files |
| ScaleTransition | 3 | 3 files |
| AnimatedContainer | 11 | 8 files |
| AnimatedPositioned | 1 | 1 file |
| AnimatedSwitcher | 2 | 2 files |
| CurvedAnimation | 5+ | 4 files |
| PageRouteBuilder | 2 | 2 files |
| Shimmer Effect | 1 | 1 file |
| CustomPainter (static, no animation) | 2 | 1 file |

---

## 1. AnimationController (Manual Animations)

### A. Splash Screen - Logo Entrance
- **File:** `lib/screens/splash/splash_screen.dart` (Lines 16-32)
- **Controllers:**
  - `_controller` - Duration: 1500ms
  - `_fadeAnim`: Tween 0 -> 1, Curve: `easeIn`
  - `_scaleAnim`: Tween 0.8 -> 1, Curve: `easeOutBack`
- **Effect:** Logo fades in and scales up on app launch
- **Widgets:** `FadeTransition` + `ScaleTransition`

### B. Login Screen - Floating Orbs
- **File:** `lib/screens/auth/login_screen.dart` (Lines 30-54)
- **Controllers:**
  - `_orbController` - Duration: 14s, `.repeat()`
  - `_pulseController` - Duration: 5s, `.repeat(reverse: true)`
- **Effect:** 3 purple gradient circles orbit using sin/cos math, person icon glows with pulsing shadow
- **Widgets:** `AnimatedBuilder` x4 (Lines 136-220, 248-271)

### C. Bottom Navigation - Bounce Effect
- **File:** `lib/widgets/bottom_nav.dart` (Lines 95-126)
- **Controllers:**
  - `_bounceController` - Duration: 300ms
  - `_bounceAnimation`: TweenSequence [1.0 -> 0.85 -> 1.1 -> 1.0]
  - Curve: `easeInOut`
- **Effect:** Tab icon bounces (shrink -> overshoot -> settle) on selection
- **Widget:** `ScaleTransition`

### D. NeuCard - Press Feedback
- **File:** `lib/widgets/neu_card.dart` (Lines 25-44)
- **Controllers:**
  - `_scaleController` - Duration: 120ms
  - `_scaleAnimation`: Tween 1.0 -> 0.96, Curve: `easeInOut`
- **Effect:** Card shrinks slightly on tap (neumorphic press effect)
- **Widget:** `ScaleTransition`

---

## 2. flutter_animate Package Usage

### Common Pattern
```dart
.animate()
  .fadeIn(duration: 400.ms, delay: (index * 80).ms)
  .slideY(begin: 0.08, end: 0)
```

### Per-Screen Breakdown

| Screen | File | Animated Elements | Delay Pattern | Effect |
|--------|------|-------------------|---------------|--------|
| **Home** | `employee_home.dart` | 11+ elements | 80ms stagger | fadeIn + slideY |
| **Attendance** | `attendance_screen.dart` | 6 sections | 80ms stagger | fadeIn + slideY |
| **Dashboard** | `dashboard_screen.dart` | 15+ elements | 80ms stagger | fadeIn + slideY |
| **Payslip** | `payslip_screen.dart` | 8 elements | 40-80ms stagger | fadeIn + slideY |
| **Directory** | `directory_screen.dart` | List items | 60ms per item | fadeIn + slideX |
| **Requests** | `requests_screen.dart` | List items | 60ms per item | fadeIn + slideX |
| **Leave** | `leave_screen.dart` | List items | 80ms per item | fadeIn + slideY |
| **Settings** | `settings_screen.dart` | 8 items | 80ms per item | fadeIn + slideY |
| **Profile** | `profile_screen.dart` | 2 sections | 100ms delay | fadeIn |
| **Analytics** | `analytics_screen.dart` | 9 chart sections | 80ms stagger | fadeIn + slideY |
| **Approvals** | `approvals_screen.dart` | Approval cards | chained | fadeIn |
| **Team Directory** | `team_directory_screen.dart` | Team items | 100ms per item | fadeIn |
| **Team Attendance** | `team_attendance_screen.dart` | 3+ sections | 60ms per item | fadeIn |
| **HR Employee Dir** | `hr_employee_directory.dart` | List items | 80ms delay | fadeIn |
| **HR Claims** | `hr_claims_overview.dart` | 3+ sections | 80ms stagger | fadeIn |
| **HR Attendance** | `hr_attendance_dashboard.dart` | 10+ elements | up to 720ms | fadeIn + slideY |
| **Assigned Detail** | `assigned_detail_screen.dart` | 3 sections | 80ms stagger | fadeIn + slideY |
| **Request Detail** | `request_detail_screen.dart` | Multiple sections | 80-160ms | fadeIn + slideY |
| **Bottom Nav** | `bottom_nav.dart` | Nav container | 200ms delay | fadeIn + slideY |

---

## 3. TweenAnimationBuilder (Counter Animations)

### Pattern
```dart
TweenAnimationBuilder<int>(
  tween: IntTween(begin: 0, end: value),
  duration: Duration(milliseconds: 3500),
  curve: Curves.easeOutExpo,
  builder: (context, value, _) => Text('$value'),
)
```

### Locations

| Screen | What Animates | Type | Duration |
|--------|--------------|------|----------|
| Home | Leave balance counter | IntTween | 3500ms |
| Home | Attendance percentage | IntTween | 3500ms |
| Home | Payroll value | DoubleTween | 3500ms |
| Attendance | Multiple counters | IntTween | 3500ms |
| Payslip | Salary amounts | DoubleTween | 3500ms |
| Dashboard | Metric counters | IntTween | 3500ms |
| Dashboard | Percentages | DoubleTween | 3500ms |
| Employee Profile | Performance counters | IntTween | 3500ms |
| HR Attendance | Attendance metrics | IntTween | 3500ms |
| Leave | Leave count | IntTween | 3500ms |

**Curve:** `Curves.easeOutExpo` (fast start, slow settle)

---

## 4. Implicit Animations

### AnimatedContainer (11 instances)
- **Settings Screen:** Theme selection tiles (200ms)
- **Payslip Screen:** Chart container transitions
- **Requests Screen:** Status/filter containers
- **Analytics Screen:** Period selector buttons (Line 96)
- **Team Attendance:** Status containers
- **HR Attendance:** Chart/metric containers
- **NeuCard:** Decoration animation for pressed/unpressed (200ms)
- **Dynamic Island:** Container with `easeOutBack` (400ms)

### AnimatedPositioned (1 instance)
- **File:** `lib/widgets/dynamic_island.dart` (Lines 12-17)
- **Effect:** Slides down from -80 to 8 (top position)
- **Duration:** 400ms, Curve: `easeOutBack`

### AnimatedSwitcher (2 instances)
- **Login Screen:** Switches between welcome actions and login form (400ms)
- **Requests Screen:** Switches between empty and loaded state

---

## 5. Page Transitions

### Splash -> Home/Login
- **File:** `splash_screen.dart` (Lines 63-70)
- **Type:** `PageRouteBuilder` with `FadeTransition`
- **Duration:** 600ms

### Login -> Shell
- **File:** `login_screen.dart` (Lines 92-95)
- **Type:** `PageRouteBuilder` with `FadeTransition` + `CurvedAnimation(easeInOut)`

---

## 6. Custom Painters (Static)

- **`_MicrosoftLogoPainter`** (Lines 571-582) - Draws 4-color Microsoft logo squares
- **`_GoogleLogoPainter`** (Lines 585-598) - Draws 4-color Google logo arcs
- **Note:** These are static renders, no animation applied

---

## 7. Skeleton/Shimmer Loading

- **File:** `login_screen.dart` (Lines 439-469, 507-514)
- **Class:** `_SkeletonBox`
- **Effect:** `.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.05))`
- **Usage:** Login screen loading overlay with 6 skeleton elements
- **Only used on login screen** - no other screens have skeleton loading

---

## 8. What's Missing - Animations NOT Yet Implemented

### Chart Animations
| Animation Type | Description | Status |
|---|---|---|
| Radial Sweep | Pie/donut charts fill like a clock | NOT IMPLEMENTED |
| Bar Grow | Bars animate height from 0 to value | NOT IMPLEMENTED |
| Data Morphing | Smooth transition when chart data changes | NOT IMPLEMENTED |
| Segment Expansion | Pie slice pops out on tap | NOT IMPLEMENTED |

### Interaction Animations
| Animation Type | Description | Status |
|---|---|---|
| Hover/Tap Scale | Card/item scales up on long-press/hover | PARTIAL (NeuCard only) |
| Ripple Effect | Material ripple on tap | Default InkWell only |
| Pull-to-Refresh | Custom animated refresh indicator | NOT IMPLEMENTED |
| Swipe Actions | Swipe-to-delete/approve with animation | NOT IMPLEMENTED |

### State Change Animations
| Animation Type | Description | Status |
|---|---|---|
| Status Badge Transition | Animated status change (Pending -> Approved) | NOT IMPLEMENTED |
| Success Checkmark | Animated checkmark after form submission | NOT IMPLEMENTED |
| Error Shake | Form shakes on validation error | NOT IMPLEMENTED |
| Confetti/Celebration | Success celebration animation | NOT IMPLEMENTED |

### Navigation Animations
| Animation Type | Description | Status |
|---|---|---|
| Shared Element / Hero | Image/card morphs between screens | NOT IMPLEMENTED |
| Slide Transitions | Screen slides left/right between tabs | NOT IMPLEMENTED |
| Bottom Sheet Animation | Smooth bottom sheet open/close | Default only |
| Parallax Scroll | Header parallax on scroll | NOT IMPLEMENTED |

### Loading Animations
| Animation Type | Description | Status |
|---|---|---|
| Skeleton Loading | Shimmer placeholder while data loads | LOGIN ONLY |
| Lottie Animations | Rich animated illustrations | NOT IMPLEMENTED |
| Progress Indicators | Circular/linear progress with animation | Basic spinner only |
| Empty State Animation | Animated illustration for empty lists | NOT IMPLEMENTED |

### Data Visualization Animations
| Animation Type | Description | Status |
|---|---|---|
| Counter Roll-Up | Numbers counting up | IMPLEMENTED (TweenAnimationBuilder) |
| Staggered List Entry | Items enter one by one | IMPLEMENTED (flutter_animate) |
| Chart Tooltip Animation | Tooltip appears with animation on tap | NOT IMPLEMENTED |
| Gauge/Meter Fill | Circular gauge fills to percentage | NOT IMPLEMENTED |

---

## Animation Design Patterns Used

### 1. Staggered List Entry
```
Duration: 400ms per item
Delay: index * 60-100ms
Effect: fadeIn + slideY(begin: 0.08) or slideX(begin: 0.05)
Curve: default (ease)
```

### 2. Counter Roll-Up
```
Duration: 3500ms
Curve: easeOutExpo
Type: IntTween or DoubleTween
```

### 3. Button Press Feedback
```
Duration: 120-300ms
Scale: 1.0 -> 0.96
Curve: easeInOut
```

### 4. Page Transition
```
Duration: 600ms
Type: FadeTransition
Curve: easeInOut
```

### 5. Background Ambient
```
Duration: 5-14 seconds
Type: Looping sin/cos orbital motion
Controllers: repeat() or repeat(reverse: true)
```
