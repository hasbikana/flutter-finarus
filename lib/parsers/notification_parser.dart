import 'package:flutter/foundation.dart';

class NotificationParseResult {
  final String type;
  final double amount;
  final String? merchant;
  final String rawBody;

  NotificationParseResult({
    required this.type,
    required this.amount,
    this.merchant,
    required this.rawBody,
  });
}

class NotificationParser {
  /// Match amount in various formats:
  /// - Rp50.000  → Rp + 50.000
  /// - Rp.40.000 → Rp. + 40.000
  /// - IDR 100.000 → IDR + 100.000
  /// - Rp200 → Rp + 200
  /// - 50.000 (without prefix)
  static final _amountRegex = RegExp(
    r'(?:Rp\.?|IDR|RP|idr|rp\.?)\s?([\d]+[.,]?[\d]*)|(?:^|\s)([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)(?:\s|$)',
  );

  /// Income keywords (ID + EN)
  static final _incomeWords = [
    'diterima', 'received', 'menerima',
    'top up', 'topup', 'top-up', 'isi saldo',
    'total received', 'total receieved',
    'dana masuk', 'saldo masuk', 'transfer masuk',
    'kredit', 'terima uang', 'cashback',
    'refund', 'pengembalian',
  ];

  /// Expense keywords (ID + EN)
  static final _expenseWords = [
    'send money', 'total payment', 'payment',
    'pembelian', 'pembayaran', 'belanja',
    'electricity', 'send', 'sent',
    'tarik', 'qris', 'poin', 'bayar',
    'transfer keluar',
  ];

  /// Match merchant/recipient after keywords
  static final _merchantAfterKeyword = RegExp(
    r'(?:di |ke |pada |kepada |untuk |dari |from |to |kepada )(.+?)(?:\n|[.,!?]|$)',
    caseSensitive: false,
  );

  static NotificationParseResult? parse(String body) {
    if (body.isEmpty) return null;

    final lower = body.toLowerCase();
    debugPrint('[NotificationParser] Input: "$body"');

    final amount = _extractAmount(body);
    if (amount == null) {
      debugPrint('[NotificationParser] No amount found');
      return null;
    }

    final type = _determineType(lower);

    final merchant = _extractMerchant(body, type);

    debugPrint('[NotificationParser] Result: type=$type amount=$amount merchant=$merchant');

    return NotificationParseResult(
      type: type,
      amount: amount,
      merchant: merchant,
      rawBody: body,
    );
  }

  static double? _extractAmount(String body) {
    final matches = _amountRegex.allMatches(body);

    for (final match in matches) {
      // Try group 1 (Rp-prefixed amount)
      final rpVal = match.group(1);
      if (rpVal != null) {
        final parsed = _parseAmountStr(rpVal);
        if (parsed != null && parsed > 0) return parsed;
      }

      // Try group 2 (bare amount like "40.000" or "200")
      final bareVal = match.group(2);
      if (bareVal != null) {
        final parsed = _parseAmountStr(bareVal);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Fallback: try to find any number with dots
    final fallback = RegExp(r'([\d]{1,3}(?:[.,]\d{3})*|[1-9]\d*)').firstMatch(body);
    if (fallback != null) {
      final parsed = _parseAmountStr(fallback.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
  }

  static double? _parseAmountStr(String raw) {
    // Remove leading zeros, handle thousand separators
    // Indonesian: "50.000" → 50000 (dot = thousand)
    // English: "1,000" → 1000 (comma = thousand)
    // Both: "40.000" → 40000
    // Both: "200" → 200

    // If has both comma AND dot:
    // "1.000,50" → dot = thousand, comma = decimal → 1000.50
    // "1,000.50" → comma = thousand, dot = decimal → 1000.50
    if (raw.contains('.') && raw.contains(',')) {
      final lastComma = raw.lastIndexOf(',');
      final lastDot = raw.lastIndexOf('.');
      if (lastComma > lastDot) {
        // "1.000,50" → remove dots, replace comma with dot
        final num = raw.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(num);
      } else {
        // "1,000.50" → remove commas
        final num = raw.replaceAll(',', '');
        return double.tryParse(num);
      }
    }

    // Only dots: "50.000" or "40.000"
    // Could be thousand separator or decimal
    if (raw.contains('.') && !raw.contains(',')) {
      final parts = raw.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // "50.00" → 50.0 (decimal)
        return double.tryParse(raw);
      } else {
        // "50.000" → 50000 (thousand separator)
        final num = raw.replaceAll('.', '');
        return double.tryParse(num);
      }
    }

    // Only commas: "1,000" → 1000 or "1,5" → 1.5
    if (raw.contains(',') && !raw.contains('.')) {
      final parts = raw.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // "1,5" or "1,50" → 1.5 (decimal)
        final num = raw.replaceAll(',', '.');
        return double.tryParse(num);
      } else {
        // "1,000" → 1000 (thousand separator)
        final num = raw.replaceAll(',', '');
        return double.tryParse(num);
      }
    }

    // Plain number: "200" or "50000"
    return double.tryParse(raw);
  }

  static String _determineType(String lower) {
    // Check income first
    for (final word in _incomeWords) {
      if (lower.contains(word)) return 'income';
    }

    // Check expense
    for (final word in _expenseWords) {
      if (lower.contains(word)) return 'expense';
    }

    // Default: check for "diterima" / "received" which are income
    if (lower.contains('diterima') || lower.contains('received')) {
      return 'income';
    }

    return 'expense';
  }

  static String? _extractMerchant(String body, String type) {
    final match = _merchantAfterKeyword.firstMatch(body);
    return match?.group(1)?.trim();
  }
}
