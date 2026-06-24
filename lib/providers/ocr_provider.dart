import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/api_config.dart';
import '../parsers/ocr_parser.dart';
import '../parsers/notification_parser.dart';

class OcrProvider extends ChangeNotifier {
  final String? Function() getToken;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  OcrResult? _ocrResult;
  NotificationParseResult? _notifResult;
  XFile? _image;
  String? _error;
  String? _rawInput;

  OcrProvider(this.getToken);

  bool get loading => _loading;
  OcrResult? get ocrResult => _ocrResult;
  NotificationParseResult? get notifResult => _notifResult;
  XFile? get image => _image;
  String? get error => _error;
  String? get rawInput => _rawInput;

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<void> pickAndProcessImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 2048);
    if (picked == null) return;
    await _processImage(picked);
  }

  Future<void> processImagePath(String filePath) async {
    await _processImage(XFile(filePath));
  }

  /// Jalur pemrosesan gambar yang sama untuk gallery picker maupun share image.
  Future<void> _processImage(XFile imageFile) async {
    _loading = true;
    _error = null;
    _image = imageFile;
    _notifResult = null;
    notifyListeners();

    try {
      final path = imageFile.path;
      debugPrint('[OCR] _processImage: path=$path');

      // Validasi file ada dan bisa dibaca.
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('File tidak ditemukan: $path');
      }
      debugPrint('[OCR] _processImage: file size=${file.lengthSync()} bytes');

      final inputImage = InputImage.fromFilePath(path);
      final recognizer = TextRecognizer();
      final recognisedText = await recognizer.processImage(inputImage);
      recognizer.close();
      final text = recognisedText.text;
      debugPrint('[OCR] _processImage: recognized ${text.length} chars');
      if (text.isEmpty) {
        debugPrint('[OCR] _processImage: WARNING - OCR text is empty');
      }
      _ocrResult = OcrParser.parse(text);
      debugPrint('[OCR] OCR result: type=${_ocrResult?.type} amount=${_ocrResult?.totalAmount} merchant=${_ocrResult?.merchant}');
    } catch (e) {
      _error = e.toString();
      debugPrint('[OCR] _processImage error: $e');
      _ocrResult = OcrResult(rawText: '');
    }

    _loading = false;
    notifyListeners();
  }

  void processText(String text) {
    debugPrint('[OCR] processText received (${text.length} chars): ${text.length > 100 ? "${text.substring(0, 100)}..." : text}');
    _rawInput = text;
    _notifResult = NotificationParser.parse(text);
    debugPrint('[OCR] Parse result: ${_notifResult != null ? "${_notifResult!.type} ${_notifResult!.amount} merchant=${_notifResult!.merchant}" : "null"}');
    _ocrResult = null;
    _image = null;
    notifyListeners();
  }

  Future<bool> submitPending({
    required int categoryId,
    required int accountId,
    String? description,
    String? date,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      String source;
      Map<String, dynamic> body;

      if (_ocrResult != null && _image != null) {
        source = 'ocr';
        final merchant = _ocrResult!.merchant?.trim();
        final desc = description?.trim();
        body = {
          'type': _ocrResult!.type,
          'amount': _ocrResult!.totalAmount ?? 0,
          if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
          if (desc != null && desc.isNotEmpty) 'description': desc,
          'notification_date': date ?? _ocrResult!.date ?? DateTime.now().toIso8601String().split('T').first,
          'raw_body': _ocrResult!.rawText,
          'source': 'ocr',
          'category_id': categoryId,
          'account_id': accountId,
        };

        final uri = Uri.parse('${ApiConfig.baseUrl}/pending-notifications');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        request.fields.addAll(body.map((k, v) => MapEntry(k, v.toString())));
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
        final response = await request.send();
        final respBody = jsonDecode(await response.stream.bytesToString());
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(respBody['message'] ?? 'Gagal menyimpan');
        }
      } else if (_notifResult != null) {
        source = 'push_notif';
        body = _notifResult!.toJson();
        body['category_id'] = categoryId;
        body['account_id'] = accountId;
        if (description != null) body['description'] = description;
        body['source'] = source;

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/pending-notifications'),
          headers: _headers,
          body: jsonEncode(body),
        );
        final data = jsonDecode(response.body);
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(data['message'] ?? 'Gagal menyimpan');
        }
      }

      reset();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _ocrResult = null;
    _notifResult = null;
    _image = null;
    _loading = false;
    _error = null;
    _rawInput = null;
    notifyListeners();
  }
}

extension NotificationParseResultJson on NotificationParseResult {
  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    if (merchant != null) 'merchant': merchant,
    'raw_body': rawBody,
    'notification_date': DateTime.now().toIso8601String().split('T').first,
  };
}
