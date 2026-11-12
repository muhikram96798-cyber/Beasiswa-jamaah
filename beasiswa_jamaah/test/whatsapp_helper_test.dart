// Unit Test: WhatsAppHelper & Donatur Telepon
// Menguji pemformatan nomor telepon WhatsApp, pembuatan teks tagihan, dan serialisasi model Donatur.

import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/donatur.dart';
import 'package:beasiswa_jamaah/providers/pengaturan_provider.dart';
import 'package:beasiswa_jamaah/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper & Donatur Telepon Tests', () {
    test('Normalisasi nomor telepon ke format internasional 62', () {
      expect(WhatsAppHelper.normalisasiNomorWa('08123456789'), equals('628123456789'));
      expect(WhatsAppHelper.normalisasiNomorWa('+62 812-3456-7890'), equals('6281234567890'));
      expect(WhatsAppHelper.normalisasiNomorWa('628123456789'), equals('628123456789'));
      expect(WhatsAppHelper.normalisasiNomorWa('8123456789'), equals('628123456789'));
      expect(WhatsAppHelper.normalisasiNomorWa(null), isNull);
      expect(WhatsAppHelper.normalisasiNomorWa(''), isNull);
    });

    test('Pembuatan pesan tagihan memuat informasi donatur dan rekening masjid', () {
      const donatur = Donatur(
        id: 1,
        namaKeluarga: 'Keluarga Bpk. H. Ahmad',
        nomorTelepon: '081234567890',
        nominalIuran: 30000,
        tanggalDaftar: '2026-01-01',
      );

      final pengaturan = PengaturanProvider();
      pengaturan.muatDariMap({
        'nama_masjid': 'Masjid Raya Al-Muhajirin',
        'nama_bank': 'BSI (Bank Syariah Indonesia)',
        'nomor_rekening': '1234567890',
        'atas_nama_rekening': 'DKM Al-Muhajirin Beasiswa',
        'catatan_qris': 'Scan QRIS di m-banking/e-wallet',
      });

      final pesan = WhatsAppHelper.buatPesanTagihan(
        donatur: donatur,
        bulan: 10,
        pengaturan: pengaturan,
      );

      expect(pesan, contains('Keluarga Bpk. H. Ahmad'));
      expect(pesan, contains('Rp30.000'));
      expect(pesan, contains('Oktober'));
      expect(pesan, contains('Masjid Raya Al-Muhajirin'));
      expect(pesan, contains('1234567890'));
      expect(pesan, contains('DKM Al-Muhajirin Beasiswa'));
    });

    test('Serialisasi Donatur toMap dan fromMap menyimpan nomorTelepon dengan benar', () {
      const donatur = Donatur(
        id: 5,
        namaKeluarga: 'Keluarga Ibu Siti',
        nomorTelepon: '085712345678',
        nominalIuran: 25000,
        statusAktif: true,
        tanggalDaftar: '2026-02-15',
        keterangan: 'RT 03 RW 05',
      );

      final map = donatur.toMap();
      expect(map['nomor_telepon'], equals('085712345678'));

      final fromMap = Donatur.fromMap(map);
      expect(fromMap.nomorTelepon, equals('085712345678'));
      expect(fromMap.namaKeluarga, equals('Keluarga Ibu Siti'));
      expect(fromMap.nominalIuran, equals(25000));

      final updated = fromMap.copyWith(nomorTelepon: '089999999999');
      expect(updated.nomorTelepon, equals('089999999999'));
      expect(updated.namaKeluarga, equals('Keluarga Ibu Siti'));
    });
  });
}
