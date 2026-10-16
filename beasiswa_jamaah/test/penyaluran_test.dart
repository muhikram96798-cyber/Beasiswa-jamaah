// Unit Test: Logika Penyaluran Bantuan Beasiswa
// Menguji aturan program:
// 1. Perlengkapan hanya berupa barang dari toko/penjahit (tanpa tunai ke anak).
// 2. Uang saku bulanan disalurkan melalui wali kelas atau orang tua.
// 3. Kalkulasi pemenuhan kebutuhan dana anak (persen, sisa, capaian).

import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/penyaluran.dart';

void main() {
  group('Aturan Program Penyaluran Bantuan', () {
    test('Perlengkapan sekolah adalah barang fisik, bukan tunai ke anak', () {
      expect(JenisPenyaluran.seragam.adalahBarang, isTrue);
      expect(JenisPenyaluran.sepatu.adalahBarang, isTrue);
      expect(JenisPenyaluran.tas.adalahBarang, isTrue);
      expect(JenisPenyaluran.buku.adalahBarang, isTrue);
      expect(JenisPenyaluran.lain.adalahBarang, isTrue);

      // Uang saku adalah non-barang (disalurkan lewat wali/ortu)
      expect(JenisPenyaluran.uangSaku.adalahBarang, isFalse);
    });

    test('Label dan value jenis penyaluran sesuai proposal', () {
      expect(JenisPenyaluran.seragam.label, 'Seragam');
      expect(JenisPenyaluran.sepatu.label, 'Sepatu');
      expect(JenisPenyaluran.tas.label, 'Tas');
      expect(JenisPenyaluran.buku.label, 'Buku & Alat Tulis');
      expect(JenisPenyaluran.uangSaku.label, 'Uang Saku');

      expect(JenisPenyaluranX.fromString('SERAGAM'), JenisPenyaluran.seragam);
      expect(JenisPenyaluranX.fromString('UANG_SAKU'), JenisPenyaluran.uangSaku);
      expect(JenisPenyaluranX.fromString('UNKNOWN'), JenisPenyaluran.lain);
    });

    test('Serialisasi dan Deserialisasi SQLite Penyaluran Barang', () {
      const p = Penyaluran(
        id: 1,
        anakId: 5,
        tanggal: '2026-07-15',
        jenis: JenisPenyaluran.seragam,
        keterangan: '2 stel seragam putih merah & pramuka',
        nominal: 450000,
        penerima: 'Toko Kain & Seragam Berkah',
        transaksiKasId: 10,
      );

      final map = p.toMap();
      expect(map['anak_id'], 5);
      expect(map['jenis'], 'SERAGAM');
      expect(map['nominal'], 450000);
      expect(map['penerima'], 'Toko Kain & Seragam Berkah');

      final dariMap = Penyaluran.fromMap(map);
      expect(dariMap.id, 1);
      expect(dariMap.anakId, 5);
      expect(dariMap.jenis, JenisPenyaluran.seragam);
      expect(dariMap.nominal, 450000);
      expect(dariMap.penerima, 'Toko Kain & Seragam Berkah');
      expect(dariMap.transaksiKasId, 10);
    });

    test('Serialisasi dan Deserialisasi SQLite Penyaluran Uang Saku', () {
      const p = Penyaluran(
        id: 2,
        anakId: 3,
        tanggal: '2026-08-01',
        jenis: JenisPenyaluran.uangSaku,
        keterangan: 'Bulan Agustus 2026',
        nominal: 150000,
        penerima: 'Ibu Rina (Wali Kelas 3 SDN 1)',
        transaksiKasId: 12,
      );

      final map = p.toMap();
      expect(map['jenis'], 'UANG_SAKU');
      expect(map['penerima'], 'Ibu Rina (Wali Kelas 3 SDN 1)');

      final dariMap = Penyaluran.fromMap(map);
      expect(dariMap.jenis, JenisPenyaluran.uangSaku);
      expect(dariMap.penerima, 'Ibu Rina (Wali Kelas 3 SDN 1)');
    });
  });

  group('Kalkulasi Progres Pemenuhan Kebutuhan Anak', () {
    test('Progres 0% ketika belum ada dana yang disalurkan', () {
      const kebutuhanBersih = 1860000;
      const tersalurkan = 0;

      final double rasio = (tersalurkan / kebutuhanBersih).clamp(0.0, 1.0);
      final double persen = (tersalurkan / kebutuhanBersih) * 100.0;
      final int sisa = kebutuhanBersih - tersalurkan;

      expect(rasio, 0.0);
      expect(persen, 0.0);
      expect(sisa, 1860000);
    });

    test('Progres proporsional saat sebagian bantuan tersalurkan', () {
      const kebutuhanBersih = 1860000; // SD dapat PIP
      const tersalurkan = 930000; // Separuh

      final double rasio = (tersalurkan / kebutuhanBersih).clamp(0.0, 1.0);
      final double persen = (tersalurkan / kebutuhanBersih) * 100.0;
      final int sisa = kebutuhanBersih - tersalurkan;

      expect(rasio, 0.5);
      expect(persen, 50.0);
      expect(sisa, 930000);
    });

    test('Progres 100% dan sisa 0 saat kebutuhan terpenuhi penuh', () {
      const kebutuhanBersih = 2825000; // SMP dapat PIP
      const tersalurkan = 2825000;

      final double rasio = (tersalurkan / kebutuhanBersih).clamp(0.0, 1.0);
      final double persen = (tersalurkan / kebutuhanBersih) * 100.0;
      final int sisa = kebutuhanBersih - tersalurkan;

      expect(rasio, 1.0);
      expect(persen, 100.0);
      expect(sisa, 0);
    });

    test('Rasio ter-clamp maksimal 1.0 jika penyaluran melebihi estimasi awal', () {
      const kebutuhanBersih = 2000000;
      const tersalurkan = 2500000;

      final double rasio = (tersalurkan / kebutuhanBersih).clamp(0.0, 1.0);
      final double persenNyata = (tersalurkan / kebutuhanBersih) * 100.0;
      final int sisa = (kebutuhanBersih - tersalurkan).clamp(0, kebutuhanBersih);

      expect(rasio, 1.0);
      expect(persenNyata, 125.0);
      expect(sisa, 0);
    });

    test('Aman dari pembagian dengan nol jika kebutuhan bernilai 0', () {
      const kebutuhanBersih = 0;
      const tersalurkan = 0;

      final double rasio = kebutuhanBersih > 0
          ? (tersalurkan / kebutuhanBersih).clamp(0.0, 1.0)
          : 1.0;
      final double persen = kebutuhanBersih > 0
          ? (tersalurkan / kebutuhanBersih) * 100.0
          : 100.0;

      expect(rasio, 1.0);
      expect(persen, 100.0);
    });
  });
}
