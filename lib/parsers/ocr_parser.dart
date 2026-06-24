import '../utils/amount_parser.dart';

class OcrResult {
  final double? totalAmount;
  final String? merchant;
  final String? date;
  final String type; // 'income' | 'expense'
  final String rawText;

  OcrResult({
    this.totalAmount,
    this.merchant,
    this.date,
    this.type = 'expense',
    required this.rawText,
  });
}

class OcrParser {
  /// Regex untuk mencari total/jumlah di struk.
  /// Support berbagai variasi: Total, Jumlah, Bayar, Tunai, Grand Total, Rp, dsb.
  static final _totalRegex = RegExp(
    r'(?:total|jumlah|bayar|tunai|grand\s*total|amount|TOTAL|JUMLAH|BAYAR|TUNAI|Rp)[:\s]*[Rr]?[Pp]?\.?\s?([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)',
    caseSensitive: false,
  );

  static final _dateRegex = RegExp(
    r'(\d{2}[/-]\d{2}[/-]\d{4})',
  );

  static final _incomeWords = [
    'diterima', 'received', 'menerima',
    'top up', 'topup', 'top-up', 'isi saldo',
    'total received', 'total receieved',
    'dana masuk', 'saldo masuk', 'transfer masuk',
    'kredit', 'terima uang', 'cashback',
    'refund', 'pengembalian',
  ];

  static final _expenseWords = [
    'send money', 'total payment', 'payment',
    'pembelian', 'pembayaran', 'belanja',
    'electricity', 'send', 'sent',
    'tarik', 'qris', 'poin', 'bayar',
    'transfer keluar',
  ];

  static OcrResult parse(String rawText) {
    final lower = rawText.toLowerCase();
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? total;
    for (final line in lines.reversed) {
      final match = _totalRegex.firstMatch(line);
      if (match != null) {
        total = AmountParser.parse(match.group(1)!);
        if (total != null && total > 0) break;
      }
    }

    // Fallback: kalau tidak ketemu 'total', ambil amount terbesar dalam teks
    // karena struk biasanya amount terbesar adalah totalnya.
    if (total == null || total == 0) {
      final amounts = AmountParser.findAll(rawText);
      if (amounts.isNotEmpty) {
        total = amounts.reduce((a, b) => a > b ? a : b);
      }
    }

    String? merchant;
    for (int i = 0; i < lines.length && i < 3; i++) {
      final line = lines[i];
      if (line.length < 40 && !line.contains(RegExp(r'\d'))) {
        merchant = line;
        break;
      }
    }

    String? date;
    for (final line in lines) {
      final match = _dateRegex.firstMatch(line);
      if (match != null) {
        date = match.group(1)!.replaceAll('/', '-');
        break;
      }
    }

    String type;
    if (_incomeWords.any((w) => lower.contains(w))) {
      type = 'income';
    } else if (_expenseWords.any((w) => lower.contains(w))) {
      type = 'expense';
    } else {
      type = 'expense';
    }

    return OcrResult(
      totalAmount: total,
      merchant: merchant,
      date: date,
      type: type,
      rawText: rawText,
    );
  }
}
