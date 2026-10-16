// Unit test: Logika Kas Bersama, Dana Cadangan 10%, dan Proteksi Saldo Negatif
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/transaksi_kas.dart';
import 'package:beasiswa_jamaah/services/kas_service.dart';

void main() {
  group('Perhitungan Saldo Kas dan Dana Cadangan 10%', () {
    test('Perhitungan saldo total kas dari pemasukan dan pengeluaran', () {
      final daftarTransaksi = [
        const TransaksiKas(
          tanggal: '2026-01-10',
          tipe: TipeTransaksi.masuk,
          kategori: KategoriTransaksi.iuran,
          keterangan: 'Iuran Januari Donatur A',
          nominal: 30000,
        ),
        const TransaksiKas(
          tanggal: '2026-01-12',
          tipe: TipeTransaksi.masuk,
          kategori: KategoriTransaksi.infak,
          keterangan: 'Infak Hamba Allah',
          nominal: 70000,
        ),
        const TransaksiKas(
          tanggal: '2026-01-15',
          tipe: TipeTransaksi.keluar,
          kategori: KategoriTransaksi.lain,
          keterangan: 'Pembelian Buku Kas & Kwitansi',
          nominal: 20000,
        ),
      ];

      final ringkasan = RingkasanKas.hitung(daftarTransaksi, persentaseCadangan: 10);

      // Total Pemasukan = 30.000 + 70.000 = 100.000
      expect(ringkasan.totalPemasukan, 100000);
      // Total Pengeluaran = 20.000
      expect(ringkasan.totalPengeluaran, 20000);
      // Total Saldo = 100.000 - 20.000 = 80.000
      expect(ringkasan.totalSaldo, 80000);
      // Dana Cadangan 10% dari 100.000 = 10.000
      expect(ringkasan.danaCadanganWajib, 10000);
      expect(ringkasan.danaCadanganTersedia, 10000);
      // Saldo Siap Pakai = 80.000 - 10.000 = 70.000
      expect(ringkasan.saldoBisaDipakai, 70000);
    });

    test('Pemisahan pos dana cadangan dan saldo yang bisa dipakai', () {
      final daftarTransaksi = [
        const TransaksiKas(
          tanggal: '2026-02-01',
          tipe: TipeTransaksi.masuk,
          kategori: KategoriTransaksi.donasi,
          keterangan: 'Donasi Awal',
          nominal: 1000000, // 1 Juta
        ),
      ];

      final ringkasan = RingkasanKas.hitung(daftarTransaksi, persentaseCadangan: 10);

      // Cadangan 10% = Rp100.000
      expect(ringkasan.danaCadanganTersedia, 100000);
      // Saldo Siap Pakai = Rp900.000
      expect(ringkasan.saldoBisaDipakai, 900000);
      // Total Kas = Rp1.000.000
      expect(ringkasan.totalSaldo, 1000000);
    });

    test('Pencairan dana cadangan secara sah mengurangi pos cadangan', () {
      final daftarTransaksi = [
        const TransaksiKas(
          tanggal: '2026-03-01',
          tipe: TipeTransaksi.masuk,
          kategori: KategoriTransaksi.iuran,
          keterangan: 'Total Iuran',
          nominal: 1000000, // 1 Juta (Cadangan 10% = 100.000, Siap Pakai = 900.000)
        ),
        const TransaksiKas(
          tanggal: '2026-03-10',
          tipe: TipeTransaksi.keluar,
          kategori: KategoriTransaksi.caiCadangan,
          keterangan: 'Bantuan Darurat Anak Sakit [Cadangan: rawat inap]',
          nominal: 50000, // Ambil 50.000 dari cadangan
          menggunakanCadangan: true,
        ),
      ];

      final ringkasan = RingkasanKas.hitung(daftarTransaksi, persentaseCadangan: 10);

      // Cadangan awal 100.000 terpakai 50.000 -> sisa cadangan 50.000
      expect(ringkasan.danaCadanganTerpakai, 50000);
      expect(ringkasan.danaCadanganTersedia, 50000);
      // Total saldo kas = 1.000.000 - 50.000 = 950.000
      expect(ringkasan.totalSaldo, 950000);
      // Saldo siap pakai tetap 900.000 karena yang terpakai adalah pos cadangan
      expect(ringkasan.saldoBisaDipakai, 900000);
    });

    test('Deteksi pengeluaran yang melebihi saldo siap pakai dan total kas', () {
      final daftarTransaksi = [
        const TransaksiKas(
          tanggal: '2026-04-01',
          tipe: TipeTransaksi.masuk,
          kategori: KategoriTransaksi.infak,
          keterangan: 'Saldo Awal',
          nominal: 100000, // Pemasukan 100.000 (Cadangan: 10.000, Siap Pakai: 90.000)
        ),
      ];

      final ringkasan = RingkasanKas.hitung(daftarTransaksi, persentaseCadangan: 10);

      const pengeluaranWajar = 50000;
      const pengeluaranMakanCadangan = 95000; // Lebih dari 90.000 tapi <= 100.000
      const pengeluaranBikinMinus = 110000;   // Lebih dari 100.000 (akan bikin total kas minus)

      // 1. Pengeluaran wajar aman tanpa cadangan
      expect(pengeluaranWajar <= ringkasan.saldoBisaDipakai, isTrue);

      // 2. Pengeluaran makan cadangan terdeteksi (perlu konfirmasi dan alasan)
      expect(pengeluaranMakanCadangan > ringkasan.saldoBisaDipakai, isTrue);
      expect(pengeluaranMakanCadangan <= ringkasan.totalSaldo, isTrue);

      // 3. Pengeluaran yang membuat total kas minus dilarang mutlak
      expect(pengeluaranBikinMinus > ringkasan.totalSaldo, isTrue);
    });
  });
}
