import 'package:flutter/foundation.dart';
import '../utils/amount_parser.dart';

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
  static final _amountRegex = AmountParser.amountPattern;


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
        final parsed = AmountParser.parse(rpVal);
        if (parsed != null && parsed > 0) return parsed;
      }

      // Try group 2 (bare amount like "40.000" or "200")
      final bareVal = match.group(2);
      if (bareVal != null) {
        final parsed = AmountParser.parse(bareVal);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Fallback: try to find any number with separators
    final fallback = RegExp(r'([\d]{1,3}(?:[.,]\d{3})*|[1-9]\d*)').firstMatch(body);
    if (fallback != null) {
      final parsed = AmountParser.parse(fallback.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
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
