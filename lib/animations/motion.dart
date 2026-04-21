/// Global Motion System - Standardized animation constants for PPulse HRMS
///
/// Usage:
///   .animate().fadeIn(duration: Motion.medium, curve: Motion.curveStandard)
///   AnimationController(duration: Motion.micro)
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/platform_adaptive.dart';

class Motion {
  Motion._();

  // ─── Durations ───────────────────────────────────────
  static Duration get micro => isApplePlatform
      ? const Duration(milliseconds: 80)
      : const Duration(milliseconds: 100);

  static Duration get small => isApplePlatform
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 250);

  static Duration get medium => isApplePlatform
      ? const Duration(milliseconds: 350)
      : const Duration(milliseconds: 400);

  static Duration get large => isApplePlatform
      ? const Duration(milliseconds: 550)
      : const Duration(milliseconds: 700);

  static const Duration chart = Duration(milliseconds: 900);
  static const Duration counter = Duration(milliseconds: 1500);

  // ─── Curves ──────────────────────────────────────────
  static Curve get curveStandard =>
      isApplePlatform ? Curves.easeOutExpo : Curves.easeOutCubic;

  static const Curve curveMicro = Curves.easeOut;
  static const Curve curveSmall = Curves.easeInOut;

  static Curve get curveDecelerate =>
      isApplePlatform ? Curves.easeOutExpo : Curves.easeOutCubic;

  static const Curve curveBounce = Curves.easeOutBack;
  static const Curve curveChart = Curves.easeOutCubic;

  /// iOS-style spring curve for natural feel
  static const Curve iosSpring = _IOSSpringCurve();

  // ─── Stagger Delays ──────────────────────────────────
  static Duration get staggerItem => isApplePlatform
      ? const Duration(milliseconds: 40)
      : const Duration(milliseconds: 60);

  static Duration get staggerCard => isApplePlatform
      ? const Duration(milliseconds: 50)
      : const Duration(milliseconds: 80);

  static const Duration staggerChart = Duration(milliseconds: 80);

  // ─── Standard List Item Enter ────────────────────────
  static List<Effect<dynamic>> listEntry(int index) {
    final delay = (index * staggerItem.inMilliseconds).ms;
    return [
      FadeEffect(duration: 420.ms, delay: delay, curve: curveDecelerate),
      SlideEffect(
        duration: 420.ms,
        delay: delay,
        begin: const Offset(0, 0.12),
        end: Offset.zero,
        curve: curveDecelerate,
      ),
      ScaleEffect(
        duration: 420.ms,
        delay: delay,
        begin: const Offset(0.98, 0.98),
        end: const Offset(1, 1),
        curve: curveDecelerate,
      ),
    ];
  }

  // ─── Card Section Enter ──────────────────────────────
  static List<Effect<dynamic>> cardEntry(int index) {
    final delay = (index * staggerCard.inMilliseconds).ms;
    return [
      FadeEffect(duration: medium, delay: delay, curve: curveDecelerate),
      SlideEffect(
        duration: medium,
        delay: delay,
        begin: const Offset(0, 0.08),
        end: Offset.zero,
        curve: curveDecelerate,
      ),
    ];
  }

  // ─── Page Transition ─────────────────────────────────
  static Route<T> pageRoute<T>(Widget page) {
    if (isApplePlatform) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: curveDecelerate,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Custom spring-like curve that approximates iOS UIKit spring animations.
class _IOSSpringCurve extends Curve {
  const _IOSSpringCurve();

  @override
  double transformInternal(double t) {
    // Damped spring approximation matching iOS default spring
    const damping = 0.825;
    const response = 0.55;
    final omega = 2.0 * 3.14159 / response;
    final decay = _exp(-damping * omega * t);
    return 1.0 - decay * _cos(omega * _sqrt(1.0 - damping * damping) * t);
  }

  // Use top-level math functions to avoid importing dart:math in a const class
  static double _exp(double x) {
    // Fast approximation using Taylor series for const-friendliness
    double result = 1.0;
    double term = 1.0;
    for (var i = 1; i <= 12; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static double _cos(double x) {
    // Normalize x to [0, 2*pi]
    const twoPi = 6.283185307;
    var nx = x % twoPi;
    if (nx < 0) nx += twoPi;
    // Taylor series for cos
    double result = 1.0;
    double term = 1.0;
    for (var i = 1; i <= 10; i++) {
      term *= -nx * nx / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
