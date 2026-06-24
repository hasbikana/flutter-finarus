/// Utility untuk parse nominal uang dari teks.
///
/// Handle format:
/// - Indonesian : Rp50.000, Rp1.000.000, 1.000,50
/// - English    : $50,000, $1,000,000, 1,000.50
/// - Mixed      : Rp1,500.000 (kadang muncul di OCR yang kurang rapi)
/// - Plain      : 200, 50000
class AmountParser {
  /// Parse string numerik mentah menjadi double.
  /// Return null jika tidak valid.
  static double? parse(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;

    // Punya koma dan titik: tentukan yang mana desimal dari posisi terakhir.
    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      if (lastComma > lastDot) {
        // 1.000,50 -> titik ribuan, koma desimal -> 1000.50
        final num = cleaned.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(num);
      } else {
        // 1,000.50 -> koma ribuan, titik desimal -> 1000.50
        final num = cleaned.replaceAll(',', '');
        return double.tryParse(num);
      }
    }

    // Hanya titik: bisa ribuan (50.000) atau desimal (50.00)
    if (cleaned.contains('.') && !cleaned.contains(',')) {
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Desimal: 50.00 -> 50.0
        return double.tryParse(cleaned);
      } else {
        // Ribuan: 50.000 -> 50000
        return double.tryParse(cleaned.replaceAll('.', ''));
      }
    }

    // Hanya koma: bisa ribuan (1,000) atau desimal (1,5)
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Desimal: 1,5 -> 1.5
        return double.tryParse(cleaned.replaceAll(',', '.'));
      } else {
        // Ribuan: 1,000 -> 1000
        return double.tryParse(cleaned.replaceAll(',', ''));
      }
    }

    // Angka polos: 200, 50000
    return double.tryParse(cleaned);
  }

  /// Regex untuk menemukan amount dalam teks.
  /// Group 1 = setelah prefix Rp/IDR, Group 2 = bare amount.
  static final amountPattern = RegExp(
    r'(?:Rp\.?|IDR|RP|idr|rp\.?)\s?([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)|(?:^|\s)([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)(?:\s|$)',
  );

  /// Cari amount pertama yang valid dalam teks.
  static double? findFirst(String text) {
    for (final match in amountPattern.allMatches(text)) {
      final raw = match.group(1) ?? match.group(2);
      if (raw != null) {
        final value = parse(raw);
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  /// Cari semua amount yang valid dalam teks.
  static List<double> findAll(String text) {
    final result = <double>[];
    for (final match in amountPattern.allMatches(text)) {
      final raw = match.group(1) ?? match.group(2);
      if (raw != null) {
        final value = parse(raw);
        if (value != null && value > 0) result.add(value);
      }
    }
    return result;
  }
}
