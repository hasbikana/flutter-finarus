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
    'diterima', 'received', 'receive', 'menerima',
    'receive money', 'received money',
    'top up', 'topup', 'top-up', 'isi saldo',
    'total received', 'total receieved',
    'dana masuk', 'saldo masuk', 'transfer masuk',
    'kredit', 'terima uang', 'cashback',
    'refund', 'pengembalian', 'deposit',
    'cash in', 'credited', 'pengembalian dana',
  ];

  /// Expense keywords (ID + EN)
  static final _expenseWords = [
    'send money', 'sent money', 'kirim uang',
    'total payment', 'payment',
    'pembelian', 'pembayaran', 'belanja',
    'electricity', 'send', 'sent',
    'tarik', 'qris', 'poin', 'bayar',
    'transfer keluar', 'cash out', 'withdraw',
    'debit', 'potongan',
  ];

  /// Action keywords typically followed by the transaction amount.
  static final _actionAmountKeywords = [
    'send money', 'sent money', 'receive money', 'received money', 'received',
    'kirim uang', 'transfer', 'diterima', 'pembayaran',
    'pembelian', 'bayar', 'top up', 'topup', 'deposit',
  ];

  /// Words that should stop merchant extraction.
  static final _merchantNoiseWords = [
    'via', 'pada', 'tanggal', 'tgl', 'note', 'catatan',
    'selengkapnya', 'detail', 'status', 'berhasil', 'gagal',
    'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu',
    'jan', 'feb', 'mar', 'apr', 'mei', 'jun',
    'jul', 'ags', 'sep', 'okt', 'nov', 'des',
  ];

  /// Match merchant/recipient after prepositions.
  static final _merchantPreposition = RegExp(
    r'(?:di |ke |pada |kepada |untuk |dari |from |to )(.+)',
    caseSensitive: false,
  );

  static NotificationParseResult? parse(String body) {
    if (body.isEmpty) return null;

    final lower = body.toLowerCase();
    debugPrint('[NotificationParser] Input: "$body"');

    final amount = _extractAmount(body, lower);
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

  static double? _extractAmount(String body, String lower) {
    final matches = _amountRegex.allMatches(body).toList();
    if (matches.isEmpty) return null;

    // 1. Prefer amount near action keywords (e.g. "Send Money Rp50.000")
    final actionAmount = _extractAmountNearAction(body, lower, matches);
    if (actionAmount != null) return actionAmount;

    // 2. Fallback: use the LAST amount (often the transaction amount; balance is usually first)
    final lastMatch = matches.last;
    final raw = lastMatch.group(1) ?? lastMatch.group(2);
    if (raw != null) {
      final parsed = AmountParser.parse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 3. Fallback: iterate all matches
    for (final match in matches) {
      final raw = match.group(1) ?? match.group(2);
      if (raw != null) {
        final parsed = AmountParser.parse(raw);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    return null;
  }

  static double? _extractAmountNearAction(
    String body,
    String lower,
    List<RegExpMatch> matches,
  ) {
    for (final keyword in _actionAmountKeywords) {
      final idx = lower.indexOf(keyword);
      if (idx == -1) continue;

      final keywordEnd = idx + keyword.length;

      // Find the first amount that starts at or after the keyword
      for (final match in matches) {
        if (match.start >= keywordEnd) {
          final raw = match.group(1) ?? match.group(2);
          if (raw != null) {
            final parsed = AmountParser.parse(raw);
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    }
    return null;
  }

  static String _determineType(String lower) {
    // Check income keywords first
    for (final word in _incomeWords) {
      if (lower.contains(word)) return 'income';
    }

    // Check expense keywords
    for (final word in _expenseWords) {
      if (lower.contains(word)) return 'expense';
    }

    // Direction-based heuristics
    if (_hasIncomeDirection(lower)) return 'income';
    if (_hasExpenseDirection(lower)) return 'expense';

    return 'expense';
  }

  static bool _hasIncomeDirection(String lower) {
    // Patterns like "X dari Y" or "X from Y" without expense keywords
    return RegExp(r'(?:^|\s)(?:diterima|terima|masuk|from)(?:\s|$)').hasMatch(lower);
  }

  static bool _hasExpenseDirection(String lower) {
    // Patterns like "X ke Y" or "X to Y" without income keywords
    return RegExp(r'(?:^|\s)(?:ke|to|kirim|keluar)(?:\s|$)').hasMatch(lower);
  }

  static String? _extractMerchant(String body, String type) {
    final match = _merchantPreposition.firstMatch(body);
    if (match == null) return null;

    var merchant = match.group(1)?.trim() ?? '';
    if (merchant.isEmpty) return null;

    // Cut off at noise words
    final lowerMerchant = merchant.toLowerCase();
    int? cutIndex;
    for (final noise in _merchantNoiseWords) {
      final idx = lowerMerchant.indexOf(' $noise');
      if (idx != -1 && (cutIndex == null || idx < cutIndex)) {
        cutIndex = idx;
      }
    }
    if (cutIndex != null) {
      merchant = merchant.substring(0, cutIndex).trim();
    }

    // Limit length
    if (merchant.length > 50) {
      merchant = merchant.substring(0, 50).trim();
    }

    return merchant.isEmpty ? null : merchant;
  }
}
