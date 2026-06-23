import 'package:flutter/services.dart';

class NotifListenerHelper {
  static const _channel = MethodChannel('org.finarus.finarus/share');

  static Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNotificationListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
    } catch (_) {}
  }
}
