// Unit test: Penyamaran Identitas Anak dan Kode Unik
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/anak.dart';
import 'package:beasiswa_jamaah/utils/inisial_helper.dart';

void main() {
  group('Penyamaran Identitas Anak', () {
    test('Nama dua kata disamarkan menjadi inisial + jenjang + kelas', () {
      final samaran = buatNamaSamaran(
        namaLengkap: 'Ahmad Fauzi',
        jenjang: Jenjang.sd,
        kelas: 3,
      );
      expect(samaran, 'A.F. - SD Kelas 3');
    });

    test('Nama tiga kata disamarkan lengkap', () {
      final samaran = buatNamaSamaran(
        namaLengkap: 'Muhammad Rizky Pratama',
        jenjang: Jenjang.sma,
        kelas: 11,
      );
      expect(samaran, 'M.R.P. - SMA Kelas 11');
    });

    test('Nama satu kata disamarkan satu inisial', () {
      final samaran = buatNamaSamaran(
        namaLengkap: 'Siti',
        jenjang: Jenjang.smp,
        kelas: 8,
      );
      expect(samaran, 'S. - SMP Kelas 8');
    });

    test('Nama dengan spasi berlebih ditangani dengan benar', () {
      final samaran = buatNamaSamaran(
        namaLengkap: '  Budi   Santoso  ',
        jenjang: Jenjang.sd,
        kelas: 1,
      );
      expect(samaran, 'B.S. - SD Kelas 1');
    });
  });

  group('Pembuatan Kode Unik Internal Anak', () {
    test('Menghasilkan A-01 saat belum ada data anak', () {
      expect(buatKodeAnak([]), 'A-01');
    });

    test('Menghasilkan A-03 jika sudah ada A-01 dan A-02', () {
      expect(buatKodeAnak(['A-01', 'A-02']), 'A-03');
    });

    test('Mengisi nomor yang kosong (misal A-02 dihapus)', () {
      expect(buatKodeAnak(['A-01', 'A-03']), 'A-02');
    });

    test('Format angka puluhan (A-10, A-11)', () {
      final sembilanAnak = List.generate(9, (i) => 'A-0${i + 1}');
      expect(buatKodeAnak(sembilanAnak), 'A-10');
    });
  });
}
