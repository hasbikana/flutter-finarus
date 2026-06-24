import 'package:flutter/services.dart';
import '../models/detected_app.dart';

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

  static Future<List<Map<String, dynamic>>> peekCaptured() async {
    try {
      final result = await _channel.invokeMethod<List>('peekCapturedNotifications');
      if (result == null || result.isEmpty) return [];
      return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<DetectedApp>> getDetectedApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getDetectedApps');
      if (result == null || result.isEmpty) return [];
      return result.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return DetectedApp(
          appId: data['appId'] as String? ?? '',
          appName: data['appName'] as String?,
          allowed: data['allowed'] as bool? ?? false,
          isNew: data['isNew'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setAllowedApps(List<String> appIds) async {
    try {
      await _channel.invokeMethod('setAllowedApps', {'appIds': appIds});
    } catch (_) {}
  }

  static Future<String?> resolveAppName(String appId) async {
    try {
      final result = await _channel.invokeMethod<String>('resolveAppName', {'appId': appId});
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<void> markAppsSeen(List<String> appIds) async {
    try {
      await _channel.invokeMethod('markAppsSeen', {'appIds': appIds});
    } catch (_) {}
  }
}
