import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Service yang menangani share intent dari app lain (DANA, GoPay, Gallery, dll)
/// menggunakan package receive_sharing_intent supaya lebih reliable dibanding
/// method channel custom.
class ShareIntentService {
  StreamSubscription<List<SharedMediaFile>>? _mediaSub;

  /// Listen ke share intent saat app sedang berjalan (warm state).
  void listen(void Function(ShareIntentData data) onData) {
    _mediaSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        debugPrint('[ShareIntentService] stream received: ${value.length} files');
        _handleMedia(value, onData);
      },
      onError: (err) {
        debugPrint('[ShareIntentService] getMediaStream error: $err');
      },
    );
  }

  /// Ambil share intent saat app dibuka dari keadaan mati (cold start).
  Future<void> getInitialMedia(void Function(ShareIntentData data) onData) async {
    try {
      final value = await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint('[ShareIntentService] initial media received: ${value.length} files');
      _handleMedia(value, onData);
      // Reset supaya intent yang sama tidak diproses berulang kali.
      await ReceiveSharingIntent.instance.reset();
    } catch (err) {
      debugPrint('[ShareIntentService] getInitialMedia error: $err');
    }
  }

  void _handleMedia(List<SharedMediaFile> files, void Function(ShareIntentData data) onData) {
    for (final file in files) {
      debugPrint('[ShareIntentService] file: ${file.toMap()}');
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        final text = file.message;
        if (text != null && text.isNotEmpty) {
          onData(ShareIntentData(text: text));
        }
      } else if (file.type == SharedMediaType.image ||
          file.type == SharedMediaType.video ||
          file.type == SharedMediaType.file) {
        final path = file.path;
        if (path.isNotEmpty) {
          onData(ShareIntentData(imagePath: path));
        }
      }
    }
  }

  void dispose() {
    _mediaSub?.cancel();
    _mediaSub = null;
  }
}

class ShareIntentData {
  final String? text;
  final String? imagePath;

  ShareIntentData({this.text, this.imagePath});

  bool get isText => text != null && text!.isNotEmpty;
  bool get isImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  String toString() => 'ShareIntentData(text=$text, imagePath=$imagePath)';
}
