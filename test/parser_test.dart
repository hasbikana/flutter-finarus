import 'package:flutter_test/flutter_test.dart';
import 'package:finarus/utils/amount_parser.dart';
import 'package:finarus/parsers/notification_parser.dart';
import 'package:finarus/parsers/ocr_parser.dart';

void main() {
  group('AmountParser.parse', () {
    test('parses Indonesian dot thousand separator', () {
      expect(AmountParser.parse('50.000'), 50000.0);
      expect(AmountParser.parse('1.000.000'), 1000000.0);
      expect(AmountParser.parse('10.000.000'), 10000000.0);
    });

    test('parses English comma thousand separator', () {
      expect(AmountParser.parse('50,000'), 50000.0);
      expect(AmountParser.parse('1,000,000'), 1000000.0);
    });

    test('parses decimal with dot', () {
      expect(AmountParser.parse('50.00'), 50.0);
      expect(AmountParser.parse('1.50'), 1.5);
    });

    test('parses decimal with comma', () {
      expect(AmountParser.parse('50,00'), 50.0);
      expect(AmountParser.parse('1,50'), 1.5);
    });

    test('parses mixed separators', () {
      expect(AmountParser.parse('1.000,50'), 1000.5);
      expect(AmountParser.parse('1,000.50'), 1000.5);
    });

    test('parses plain numbers', () {
      expect(AmountParser.parse('200'), 200.0);
      expect(AmountParser.parse('50000'), 50000.0);
    });

    test('returns null for invalid input', () {
      expect(AmountParser.parse(''), isNull);
      expect(AmountParser.parse('abc'), isNull);
    });
  });

  group('AmountParser.findFirst', () {
    test('finds Rp-prefixed amount', () {
      expect(AmountParser.findFirst('Pembayaran Rp50.000 di Indomaret'), 50000.0);
    });

    test('finds multi-thousand Rp amount', () {
      expect(AmountParser.findFirst('Transfer Rp1.500.000 berhasil'), 1500000.0);
    });

    test('finds IDR amount', () {
      expect(AmountParser.findFirst('Amount: IDR 100.000'), 100000.0);
    });

    test('finds bare amount', () {
      expect(AmountParser.findFirst('Total 50.000 sudah dibayar'), 50000.0);
    });
  });

  group('NotificationParser.parse', () {
    test('DANA income: diterima', () {
      final result = NotificationParser.parse('Rp50.000 diterima dari Budi Santoso');
      expect(result, isNotNull);
      expect(result!.type, 'income');
      expect(result.amount, 50000.0);
      expect(result.merchant, 'Budi Santoso');
    });

    test('DANA income: received english', () {
      final result = NotificationParser.parse('Rp1.000 has been received from Budi santoso');
      expect(result, isNotNull);
      expect(result!.type, 'income');
      expect(result.amount, 1000.0);
      expect(result.merchant, 'Budi santoso');
    });

    test('DANA send money expense', () {
      final result = NotificationParser.parse('Send Money Rp200 to Bapa');
      expect(result, isNotNull);
      expect(result!.type, 'expense');
      expect(result.amount, 200.0);
      expect(result.merchant, 'Bapa');
    });

    test('DANA total payment expense', () {
      final result = NotificationParser.parse('Total Payment  Rp200');
      expect(result, isNotNull);
      expect(result!.type, 'expense');
      expect(result.amount, 200.0);
    });

    test('DANA electricity expense', () {
      final result = NotificationParser.parse('Total Payment Rp21.000');
      expect(result, isNotNull);
      expect(result!.type, 'expense');
      expect(result.amount, 21000.0);
    });

    test('DANA top up income', () {
      final result = NotificationParser.parse('Top Up From Bank Total Received Rp90.000');
      expect(result, isNotNull);
      expect(result!.type, 'income');
      expect(result.amount, 90000.0);
    });

    test('multi-million amount', () {
      final result = NotificationParser.parse('Pembayaran Rp1.500.000 berhasil di Indomaret');
      expect(result, isNotNull);
      expect(result!.amount, 1500000.0);
    });

    test('returns null for empty text', () {
      expect(NotificationParser.parse(''), isNull);
    });

    test('returns null when no amount', () {
      expect(NotificationParser.parse('Halo, ini pesan tanpa nominal'), isNull);
    });
  });

  group('OcrParser.parse', () {
    test('detects total in simple receipt', () {
      final result = OcrParser.parse('''
Indomaret
Jl. Mawar No. 12
Total Rp50.000
Tunai Rp50.000
Kembali Rp0
      ''');
      expect(result.totalAmount, 50000.0);
      expect(result.type, 'expense');
    });

    test('detects total in uppercase receipt', () {
      final result = OcrParser.parse('''
TOKO ABADI
TOTAL: 1.000.000
BAYAR: 1.000.000
      ''');
      expect(result.totalAmount, 1000000.0);
    });

    test('detects income from top up receipt', () {
      final result = OcrParser.parse('''
DANA
Top Up Berhasil
Total Received Rp100.000
      ''');
      expect(result.totalAmount, 100000.0);
      expect(result.type, 'income');
    });

    test('uses largest amount fallback when no total keyword', () {
      final result = OcrParser.parse('''
Struk Belanja
500
1.000
75.000
      ''');
      expect(result.totalAmount, 75000.0);
    });

    test('detects merchant from first lines', () {
      final result = OcrParser.parse('''
Alfamart
Total Rp25.000
      ''');
      expect(result.merchant, 'Alfamart');
    });
  });
}
