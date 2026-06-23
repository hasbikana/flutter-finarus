import 'dart:async';
import 'package:flutter/services.dart';

class ShareHandlerService {
  static const _channel = MethodChannel('org.finarus.finarus/share');

  final StreamController<Map<String, String>> _controller =
      StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get onShare => _controller.stream;

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShare') {
        final data = Map<String, String>.from(call.arguments as Map);
        _controller.add(data);
        return true;
      }
      return null;
    });
  }

  Future<Map<String, String>> getInitialData() async {
    try {
      final data = await _channel.invokeMethod<Map>('getSharedData');
      if (data != null && data.isNotEmpty) {
        return Map<String, String>.from(data);
      }
    } catch (_) {}
    return {};
  }

  void dispose() {
    _controller.close();
  }
}
