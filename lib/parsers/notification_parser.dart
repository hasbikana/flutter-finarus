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
  static final _amountRegex = RegExp(
    r'[Rr][Pp]\s?([\d]+[.,]?[\d]*)',
  );

  static final _debitWords = [
    'pembelian', 'pembayaran', 'belanja', 'tarik',
    'transfer keluar', 'qris', 'poin', 'bayar',
  ];

  static final _creditWords = [
    'kredit', 'menerima', 'transfer masuk', 'top up',
    'isi saldo', 'dana masuk', 'terima uang', 'cashback',
    'refund', 'pengembalian', 'saldo masuk',
  ];

  static final _merchantRegex = RegExp(
    r'(?:di |ke |pada |kepada |untuk |dari )(.+?)(?:\n|[.,!?]|$| via)',
    caseSensitive: false,
  );

  static final _danaTransferIn = RegExp(
    r'transfer\s+masuk|dana\s+masuk|terima\s+uang|top\s*up|isi\s+saldo',
    caseSensitive: false,
  );

  static final _danaTransferOut = RegExp(
    r'pembelian|pembayaran|belanja|qris|tarik|bayar',
    caseSensitive: false,
  );

  static NotificationParseResult? parse(String body) {
    if (body.isEmpty) return null;

    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount == 0) return null;

    String type;
    if (_danaTransferIn.hasMatch(body)) {
      type = 'income';
    } else if (_danaTransferOut.hasMatch(body)) {
      type = 'expense';
    } else {
      final isDebit = _debitWords.any((w) => body.toLowerCase().contains(w));
      final isCredit = _creditWords.any((w) => body.toLowerCase().contains(w));
      type = isDebit ? 'expense' : (isCredit ? 'income' : 'expense');
    }

    final merchantMatch = _merchantRegex.firstMatch(body);
    final merchant = merchantMatch?.group(1)?.trim();

    return NotificationParseResult(
      type: type,
      amount: amount,
      merchant: merchant,
      rawBody: body,
    );
  }

  static List<NotificationParseResult> parseMultiple(List<String> bodies) {
    return bodies
        .map((b) => parse(b))
        .where((r) => r != null)
        .cast<NotificationParseResult>()
        .toList();
  }
}
