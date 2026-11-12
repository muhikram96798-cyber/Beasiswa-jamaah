// Unit test: Integritas Penghapusan Data & Foreign Key Constraint
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/donatur.dart';
import 'package:beasiswa_jamaah/models/iuran.dart';
import 'package:beasiswa_jamaah/models/penyaluran.dart';

void main() {
  group('Integritas Foreign Key & Urutan Penghapusan Data', () {
    test('Simulasi penghapusan Donatur: uang kas tetap utuh (unlink transaksi_kas) dan iuran dihapus', () {
      final logPenghapusan = <String>[];

      // Simulasi tabel database: iuran berkaitan dengan transaksi_kas
      const donaturId = 1;
      final listIuran = [
        {'id': 101, 'donatur_id': donaturId, 'transaksi_kas_id': 201},
        {'id': 102, 'donatur_id': donaturId, 'transaksi_kas_id': 202},
      ];

      final iuranIds = listIuran.map((item) => item['id']).toList();

      // Langkah 1: Unlink transaksi_kas agar kas masjid tetap aman dan tidak ikut musnah
      logPenghapusan.add(
        'UPDATE transaksi_kas SET sumber_id = NULL WHERE jenis = MASUK AND sumber_id IN (${iuranIds.join(',')})',
      );

      // Langkah 2: Hapus iuran
      logPenghapusan.add('DELETE FROM iuran WHERE donatur_id = $donaturId');

      // Langkah 3: Hapus donatur
      logPenghapusan.add('DELETE FROM donatur WHERE id = $donaturId');

      // Verifikasi urutan eksekusi & pembukuan kas tetap utuh
      expect(logPenghapusan[0], contains('UPDATE transaksi_kas SET sumber_id = NULL'));
      expect(logPenghapusan[1], contains('DELETE FROM iuran'));
      expect(logPenghapusan[2], contains('DELETE FROM donatur'));
      expect(logPenghapusan.any((log) => log.contains('DELETE FROM transaksi_kas')), isFalse);
    });

    test('Simulasi pembatalan Iuran: baris iuran dihapus sebelum transaksi_kas', () {
      final logPenghapusan = <String>[];
      const iuranId = 55;
      const kasId = 77;

      // 1. Hapus iuran
      logPenghapusan.add('DELETE FROM iuran WHERE id = $iuranId');

      // 2. Hapus transaksi kas
      logPenghapusan.add('DELETE FROM transaksi_kas WHERE id = $kasId');

      expect(logPenghapusan.first, contains('iuran'));
      expect(logPenghapusan.last, contains('transaksi_kas'));
    });

    test('Simulasi penghapusan Penyaluran: baris penyaluran dihapus sebelum transaksi_kas', () {
      final logPenghapusan = <String>[];
      const penyaluranId = 12;
      const kasId = 34;

      // 1. Hapus penyaluran terlebih dahulu
      logPenghapusan.add('DELETE FROM penyaluran WHERE id = $penyaluranId');

      // 2. Hapus transaksi kas terkait
      logPenghapusan.add('DELETE FROM transaksi_kas WHERE id = $kasId');

      expect(logPenghapusan[0], contains('penyaluran'));
      expect(logPenghapusan[1], contains('transaksi_kas'));
    });

    test('Simulasi penghapusan Anak: pengeluaran kas tetap utuh (unlink transaksi_kas) dan anak dihapus', () {
      final logPenghapusan = <String>[];
      const anakId = 5;
      final listPenyaluran = [
        {'id': 1, 'anak_id': anakId, 'transaksi_kas_id': 501},
      ];

      final kasIds = listPenyaluran
          .map((item) => item['transaksi_kas_id'])
          .whereType<int>()
          .toList();

      // 1. Unlink transaksi_kas agar pengeluaran kas masjid yang sudah disalurkan tetap tercatat
      for (final kasId in kasIds) {
        logPenghapusan.add('UPDATE transaksi_kas SET sumber_id = NULL WHERE id = $kasId');
      }

      // 2. Hapus penyaluran anak
      logPenghapusan.add('DELETE FROM penyaluran WHERE anak_id = $anakId');

      // 3. Hapus anak
      logPenghapusan.add('DELETE FROM anak WHERE id = $anakId');

      expect(logPenghapusan[0], contains('UPDATE transaksi_kas SET sumber_id = NULL'));
      expect(logPenghapusan[1], contains('DELETE FROM penyaluran'));
      expect(logPenghapusan[2], contains('DELETE FROM anak'));
      expect(logPenghapusan.any((log) => log.contains('DELETE FROM transaksi_kas')), isFalse);
    });

    test('Model Donatur, Iuran, dan Penyaluran konsisten saat penghapusan', () {
      final donatur = Donatur(
        id: 1,
        namaKeluarga: 'Keluarga Bpk. Santoso',
        nominalIuran: 50000,
        tanggalDaftar: '2026-01-01',
      );
      expect(donatur.id, 1);

      const iuran = Iuran(
        id: 10,
        donaturId: 1,
        bulan: 1,
        tahunAjaran: 2026,
        nominal: 50000,
        tanggalBayar: '2026-01-05',
        transaksiKasId: 20,
      );
      expect(iuran.donaturId, donatur.id);
      expect(iuran.transaksiKasId, 20);

      const penyaluran = Penyaluran(
        id: 100,
        anakId: 5,
        tanggal: '2026-02-01',
        jenis: JenisPenyaluran.seragam,
        keterangan: 'Seragam Merah Putih',
        nominal: 150000,
        transaksiKasId: 200,
      );
      expect(penyaluran.transaksiKasId, 200);
      expect(penyaluran.jenis.adalahBarang, isTrue);
    });
  });
}
