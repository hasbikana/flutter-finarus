import 'package:intl/intl.dart';

String formatRupiah(num amount) {
  final format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return format.format(amount);
}

/// Format rupiah dalam bentuk ringkas untuk ruang sempit.
/// Contoh:
/// - 500       -> Rp 500
/// - 50.000    -> Rp 50rb
/// - 1.250.000 -> Rp 1,25jt
/// - 362.000.000 -> Rp 362jt
/// - 1.500.000.000 -> Rp 1,5M
String formatRupiahCompact(num amount) {
  final absAmount = amount.abs();

  if (absAmount >= 1000000000) {
    return 'Rp ${_compactValue(amount / 1000000000)}M';
  } else if (absAmount >= 1000000) {
    return 'Rp ${_compactValue(amount / 1000000)}jt';
  } else if (absAmount >= 1000) {
    return 'Rp ${(amount / 1000).floor()}rb';
  } else {
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}

String _compactValue(double value) {
  if (value == value.toInt()) {
    return value.toInt().toString();
  }
  String s = value.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

String formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatMonthYear(int month, int year) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${months[month - 1]} $year';
}
