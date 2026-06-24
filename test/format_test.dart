import 'package:flutter_test/flutter_test.dart';
import 'package:finarus/utils/format.dart';

void main() {
  group('formatRupiahCompact', () {
    test('formats hundreds', () {
      expect(formatRupiahCompact(500), 'Rp 500');
      expect(formatRupiahCompact(999), 'Rp 999');
    });

    test('formats thousands as ribu', () {
      expect(formatRupiahCompact(50000), 'Rp 50rb');
      expect(formatRupiahCompact(999000), 'Rp 999rb');
    });

    test('formats millions as juta', () {
      expect(formatRupiahCompact(1000000), 'Rp 1jt');
      expect(formatRupiahCompact(1250000), 'Rp 1,25jt');
      expect(formatRupiahCompact(1500000), 'Rp 1,5jt');
      expect(formatRupiahCompact(362000000), 'Rp 362jt');
    });

    test('formats billions as M', () {
      expect(formatRupiahCompact(1000000000), 'Rp 1M');
      expect(formatRupiahCompact(1500000000), 'Rp 1,5M');
      expect(formatRupiahCompact(2500000000), 'Rp 2,5M');
    });

    test('formats zero', () {
      expect(formatRupiahCompact(0), 'Rp 0');
    });

    test('formats negative amounts', () {
      expect(formatRupiahCompact(-1250000), 'Rp -1,25jt');
      expect(formatRupiahCompact(-50000), 'Rp -50rb');
    });
  });
}
