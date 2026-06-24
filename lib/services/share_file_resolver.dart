import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Helper untuk memastikan file hasil share (terutama content URI saat cold start)
/// tersedia sebagai file path biasa yang bisa dibaca ML Kit / OCR.
class ShareFileResolver {
  static const _channel = MethodChannel('org.finarus.finarus/share');

  /// Kalau path sudah file biasa dan exist, kembalikan langsung.
  /// Kalau path adalah content:// atau file belum ada, salin ke cache via native.
  static Future<String?> resolve(String path) async {
    debugPrint('[ShareFileResolver] resolving: $path');

    // Kalau sudah file biasa dan ada, pakai langsung.
    if (!path.startsWith('content://') && File(path).existsSync()) {
      debugPrint('[ShareFileResolver] file already exists: $path');
      return path;
    }

    // Kalau content URI atau file tidak ada, salin ke cache lewat native.
    try {
      final resolved = await _channel.invokeMethod<String>('resolveSharedFile', {'uri': path});
      debugPrint('[ShareFileResolver] resolved to: $resolved');
      return resolved;
    } catch (e) {
      debugPrint('[ShareFileResolver] error resolving $path: $e');
      return null;
    }
  }
}
