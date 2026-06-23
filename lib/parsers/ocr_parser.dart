class OcrResult {
  final double? totalAmount;
  final String? merchant;
  final String? date;
  final String rawText;

  OcrResult({
    this.totalAmount,
    this.merchant,
    this.date,
    required this.rawText,
  });
}

class OcrParser {
  static final _totalRegex = RegExp(
    r'(?:total|jumlah|TOTAL|JUMLAH|Rp)[:\s]*[Rr]?[Pp]?\s?([\d.,]+)',
  );

  static final _dateRegex = RegExp(
    r'(\d{2}[/-]\d{2}[/-]\d{4})',
  );

  static OcrResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? total;
    for (final line in lines.reversed) {
      final match = _totalRegex.firstMatch(line);
      if (match != null) {
        final str = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
        total = double.tryParse(str);
        if (total != null && total > 0) break;
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

    return OcrResult(
      totalAmount: total,
      merchant: merchant,
      date: date,
      rawText: rawText,
    );
  }
}
