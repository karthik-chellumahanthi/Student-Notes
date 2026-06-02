import 'package:flutter/services.dart';

class ScreenSecurityService {
  static const platform = MethodChannel('com.studentnotes/screen_security');

  /// Enable screenshot and screen recording prevention
  static Future<void> enableSecureMode() async {
    try {
      await platform.invokeMethod('enableSecureMode');
    } catch (e) {
      // Error enabling secure mode, silently fail
    }
  }

  /// Disable screenshot and screen recording prevention
  static Future<void> disableSecureMode() async {
    try {
      await platform.invokeMethod('disableSecureMode');
    } catch (e) {
      // Error disabling secure mode, silently fail
    }
  }

  /// Check if secure mode is currently enabled
  static Future<bool> isSecureModeEnabled() async {
    try {
      final bool result = await platform.invokeMethod('isSecureModeEnabled');
      return result;
    } catch (e) {
      // Error checking secure mode, silently fail
      return false;
    }
  }
}
