// Unit test: Rupiah Formatter dan Validasi Nominal Iuran
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/utils/rupiah_formatter.dart';

void main() {
  group('Format Rupiah', () {
    test('Format integer ke Rupiah dengan benar', () {
      expect(formatRupiah(20000), contains('20.000'));
      expect(formatRupiah(30000), contains('30.000'));
      expect(formatRupiah(2310000), contains('2.310.000'));
      expect(formatRupiah(0), contains('0'));
    });

    test('Parse string Rupiah ke integer', () {
      expect(parseRupiah('20000'), 20000);
      expect(parseRupiah('20.000'), 20000);
      expect(parseRupiah('Rp20.000'), 20000);
      expect(parseRupiah('Rp 30.000'), 30000);
      expect(parseRupiah('  25.000  '), 25000);
      expect(parseRupiah('bukan_angka'), isNull);
    });
  });

  group('Validasi Nominal Iuran', () {
    const min = 20000;
    const max = 30000;

    test('Nominal di bawah batas minimal mengembalikan pesan error', () {
      final hasil = validasiIuran(15000, min: min, max: max);
      expect(hasil, isNotNull);
      expect(hasil, contains('minimal'));
    });

    test('Nominal di atas batas maksimal mengembalikan pesan error', () {
      final hasil = validasiIuran(35000, min: min, max: max);
      expect(hasil, isNotNull);
      expect(hasil, contains('maksimal'));
    });

    test('Nominal pas pada batas minimal atau maksimal adalah valid', () {
      expect(validasiIuran(20000, min: min, max: max), isNull);
      expect(validasiIuran(30000, min: min, max: max), isNull);
    });

    test('Nominal di dalam rentang adalah valid', () {
      expect(validasiIuran(25000, min: min, max: max), isNull);
    });

    test('Validasi nominal positif', () {
      expect(validasiNominalPositif(null), isNotNull);
      expect(validasiNominalPositif(0), isNotNull);
      expect(validasiNominalPositif(-5000), isNotNull);
      expect(validasiNominalPositif(10000), isNull);
    });
  });
}
