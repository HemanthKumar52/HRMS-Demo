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
  static const Duration micro = Duration(milliseconds: 100);       // tap feedback
  static const Duration small = Duration(milliseconds: 250);       // small UI changes
  static const Duration medium = Duration(milliseconds: 400);      // standard transitions
  static const Duration large = Duration(milliseconds: 700);       // charts, page transitions
  static const Duration chart = Duration(milliseconds: 900);       // chart entry animations
  static const Duration counter = Duration(milliseconds: 1500);    // number roll-up

  // ─── Curves ──────────────────────────────────────────
  static const Curve curveStandard = Curves.easeOutCubic;          // default for most
  static const Curve curveMicro = Curves.easeOut;                  // taps, micro
  static const Curve curveSmall = Curves.easeInOut;                // small UI
  static const Curve curveDecelerate = Curves.easeOutCubic;        // enter/appear
  static const Curve curveBounce = Curves.easeOutBack;             // playful overshoot
  static const Curve curveChart = Curves.easeOutCubic;             // chart fills

  // ─── Stagger Delays ──────────────────────────────────
  static const Duration staggerItem = Duration(milliseconds: 60);  // list items
  static const Duration staggerCard = Duration(milliseconds: 80);  // cards/sections
  static const Duration staggerChart = Duration(milliseconds: 80); // chart segments

  // ─── Standard List Item Enter ────────────────────────
  /// Enhanced stagger animation for list items.
  /// Usage: widget.staggerEntry(index)
  static List<Effect<dynamic>> listEntry(int index) => [
        FadeEffect(
          duration: 420.ms,
          delay: (index * 60).ms,
          curve: curveDecelerate,
        ),
        SlideEffect(
          duration: 420.ms,
          delay: (index * 60).ms,
          begin: const Offset(0, 0.12),
          end: Offset.zero,
          curve: curveDecelerate,
        ),
        ScaleEffect(
          duration: 420.ms,
          delay: (index * 60).ms,
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: curveDecelerate,
        ),
      ];

  // ─── Card Section Enter ──────────────────────────────
  static List<Effect<dynamic>> cardEntry(int index) => [
        FadeEffect(
          duration: medium,
          delay: (index * 80).ms,
          curve: curveDecelerate,
        ),
        SlideEffect(
          duration: medium,
          delay: (index * 80).ms,
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          curve: curveDecelerate,
        ),
      ];

  // ─── Page Transition ─────────────────────────────────
  static Route<T> pageRoute<T>(Widget page) {
    // iOS/macOS: native Cupertino slide transition
    if (isApplePlatform) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    // Android: custom fade + slide transition
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
