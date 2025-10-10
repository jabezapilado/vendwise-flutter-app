import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralizes haptic feedback so we can safely no-op on platforms that do
/// not support vibration (for example, Flutter Web).
class AppHaptics {
  const AppHaptics._();

  static bool get _canVibrate {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static Future<void> selectionChanged() async {
    if (_canVibrate) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> lightImpact() async {
    if (_canVibrate) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (_canVibrate) {
      await HapticFeedback.mediumImpact();
    }
  }
}
