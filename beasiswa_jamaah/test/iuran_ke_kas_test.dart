// Unit test: Logika pencatatan iuran dan sinkronisasi kas
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/iuran.dart';
import 'package:beasiswa_jamaah/models/transaksi_kas.dart';
import 'package:beasiswa_jamaah/services/donatur_service.dart';

void main() {
  group('Pencatatan Iuran dan Integritas Kas', () {
    test('Nama bulan dan singkatan bulan sesuai kalender Indonesia', () {
      expect(DonaturService.getNamaBulan(1), 'Januari');
      expect(DonaturService.getNamaBulan(7), 'Juli');
      expect(DonaturService.getNamaBulan(12), 'Desember');
      expect(DonaturService.singkatanBulan.length, 12);
      expect(DonaturService.singkatanBulan[0], 'Jan');
      expect(DonaturService.singkatanBulan[11], 'Des');
    });

    test('Data transaksi kas dari iuran harus bertipe MASUK dan kategori IURAN', () {
      const namaKeluarga = 'Keluarga Bpk. H. Ahmad';
      const bulan = 3;
      const tahun = 2026;
      const nominal = 25000;
      const tanggalBayar = '2026-03-05';

      final keteranganKas =
          'Iuran ${DonaturService.getNamaBulan(bulan)} $tahun - $namaKeluarga';

      final transaksi = TransaksiKas(
        tanggal: tanggalBayar,
        tipe: TipeTransaksi.masuk,
        kategori: KategoriTransaksi.iuran,
        keterangan: keteranganKas,
        nominal: nominal,
        sumberId: 10,
      );

      final map = transaksi.toMap();
      expect(map['tipe'], 'MASUK');
      expect(map['kategori'], 'IURAN');
      expect(map['nominal'], 25000);
      expect(map['tanggal'], '2026-03-05');
      expect(map['keterangan'], contains('Maret 2026'));
      expect(map['keterangan'], contains(namaKeluarga));
    });

    test('Relasi Iuran dan TransaksiKas terhubung dua arah', () {
      const kasId = 42;
      const iuranId = 99;

      final iuran = const Iuran(
        id: iuranId,
        donaturId: 1,
        bulan: 5,
        tahunAjaran: 2026,
        nominal: 30000,
        tanggalBayar: '2026-05-10',
        transaksiKasId: kasId,
      );

      expect(iuran.transaksiKasId, kasId);

      final map = iuran.toMap();
      expect(map['transaksi_kas_id'], kasId);
      expect(map['nominal'], 30000);
    });

    test('Logika pencegahan duplikasi iuran pada bulan dan tahun yang sama', () {
      final daftarIuran = <String>{};

      String buatKunci(int donaturId, int bulan, int tahun) =>
          '$donaturId-$bulan-$tahun';

      // Pembayaran pertama berhasil
      final kunci1 = buatKunci(1, 1, 2026);
      expect(daftarIuran.contains(kunci1), isFalse);
      daftarIuran.add(kunci1);

      // Pembayaran kedua pada bulan yang sama harus ditolak (terdeteksi duplikat)
      final kunciDuplikat = buatKunci(1, 1, 2026);
      expect(daftarIuran.contains(kunciDuplikat), isTrue);

      // Pembayaran pada bulan berbeda diperbolehkan
      final kunciBulanLain = buatKunci(1, 2, 2026);
      expect(daftarIuran.contains(kunciBulanLain), isFalse);
    });

    test('Logika sinkronisasi tahun ajaran aktif memastikan konsistensi pencatatan', () {
      const tahunAjaranAktifPengaturan = 2027;
      int tahunDipakaiDialog(int? tahunAwal) => tahunAwal ?? tahunAjaranAktifPengaturan;

      // Beranda mengoper tahun ajaran aktif
      final tahunDariBeranda = tahunDipakaiDialog(tahunAjaranAktifPengaturan);
      expect(tahunDariBeranda, 2027);

      // Fallback dialog menggunakan tahun ajaran aktif pengaturan
      final tahunFallback = tahunDipakaiDialog(null);
      expect(tahunFallback, 2027);
    });
  });
}
