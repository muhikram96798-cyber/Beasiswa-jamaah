import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/pengaturan.dart';
import 'package:beasiswa_jamaah/providers/pengaturan_provider.dart';
import 'package:beasiswa_jamaah/utils/pin_helper.dart';

void main() {
  group('Uji Logika Keamanan PIN (Tahap 8)', () {
    test('PinHelper menghasilkan hash SHA-256 yang konsisten dengan salt', () {
      final hash1 = PinHelper.hashPin('123456');
      final hash2 = PinHelper.hashPin('123456');
      final hashLain = PinHelper.hashPin('654321');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashLain)));
      expect(hash1.length, equals(64)); // SHA-256 hex string panjang 64 karakter
      // Pastikan bukan plain text
      expect(hash1.contains('123456'), isFalse);
    });

    test('PinHelper verifikasiPin memvalidasi kecocokan PIN dengan benar', () {
      final storedHash = PinHelper.hashPin('987654');

      expect(PinHelper.verifikasiPin('987654', storedHash), isTrue);
      expect(PinHelper.verifikasiPin('111111', storedHash), isFalse);
      expect(PinHelper.verifikasiPin('98765', storedHash), isFalse);
    });

    test('PinHelper mengizinkan akses jika PIN belum diset (storedHash kosong)', () {
      expect(PinHelper.verifikasiPin('apapun', ''), isTrue);
    });
  });

  group('Uji Nilai Default & Konfigurasi Pengaturan (Tahap 8)', () {
    test('Nilai default proposal sesuai spesifikasi teknis', () {
      final defaults = PengaturanKey.defaults;

      expect(defaults[PengaturanKey.biayaSd], equals('2310000'));
      expect(defaults[PengaturanKey.biayaSmp], equals('3575000'));
      expect(defaults[PengaturanKey.biayaSma], equals('4785000'));
      expect(defaults[PengaturanKey.pipSd], equals('450000'));
      expect(defaults[PengaturanKey.pipSmp], equals('750000'));
      expect(defaults[PengaturanKey.pipSma], equals('1800000'));
      expect(defaults[PengaturanKey.iuranMin], equals('20000'));
      expect(defaults[PengaturanKey.iuranMax], equals('30000'));
      expect(defaults[PengaturanKey.pctCadangan], equals('10'));
      expect(defaults[PengaturanKey.bobotEkonomi], equals('40'));
      expect(defaults[PengaturanKey.bobotYatim], equals('30'));
      expect(defaults[PengaturanKey.bobotSaudara], equals('15'));
      expect(defaults[PengaturanKey.bobotKip], equals('15'));
    });

    test('PengaturanKey mendukung konfigurasi Rekening & QRIS Masjid', () {
      final defaults = PengaturanKey.defaults;

      expect(defaults[PengaturanKey.namaMasjid], isNotEmpty);
      expect(defaults[PengaturanKey.namaBank], isNotEmpty);
      expect(defaults[PengaturanKey.nomorRekening], isNotEmpty);
      expect(defaults[PengaturanKey.atasNamaRekening], isNotEmpty);
      expect(defaults[PengaturanKey.catatanQris], contains('QRIS'));
    });

    test('PengaturanProvider membaca nilai default saat fallback testing', () async {
      final provider = PengaturanProvider();
      await provider.muat();

      expect(provider.biayaSd, equals(2310000));
      expect(provider.biayaSmp, equals(3575000));
      expect(provider.biayaSma, equals(4785000));
      expect(provider.pctCadangan, equals(10));
      expect(provider.persentaseCadangan, equals(10));
      expect(provider.sudahAdaPin, isFalse);
      expect(provider.verifikasiPin('123456'), isTrue); // belum ada PIN
    });
  });

  group('Uji Validasi File Header SQLite Cadangan (Tahap 8)', () {
    test('Validasi header SQLite format 3', () async {
      const headerSqlite = [
        0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
        0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00
      ];

      // Simulasi bytes file database sah
      final validBytes = List<int>.from(headerSqlite)..addAll([0x01, 0x02]);
      bool isValid = true;
      for (int i = 0; i < 16; i++) {
        if (validBytes[i] != headerSqlite[i]) {
          isValid = false;
          break;
        }
      }
      expect(isValid, isTrue);

      // Simulasi file text / gambar palsu
      final invalidBytes = [0x50, 0x4B, 0x03, 0x04]; // ZIP header
      bool isInvalidValid = true;
      if (invalidBytes.length < 16) {
        isInvalidValid = false;
      }
      expect(isInvalidValid, isFalse);
    });
  });
}
