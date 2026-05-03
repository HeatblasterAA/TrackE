import 'package:flutter/services.dart';

/// Control channel for the Android NotificationListenerService.
///
/// Stream of captured signals is exposed separately via
/// [NotificationSource] (EventChannel `tracke/notifications/stream`).
class NotificationBridge {
  static const MethodChannel _channel =
      MethodChannel('tracke/notifications/control');

  /// Whether the user has granted "Notification access" to TrackE
  /// in system settings.
  static Future<bool> isListenerEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens system Settings → Notification access. Returns immediately;
  /// callers should re-check [isListenerEnabled] on app resume.
  static Future<void> openListenerSettings() async {
    try {
      await _channel.invokeMethod('openListenerSettings');
    } on PlatformException {
      // ignore — caller will see isListenerEnabled remain false.
    } on MissingPluginException {
      // non-Android: no-op
    }
  }
}
