// Unit Test: Equality & HashCode untuk Model Anak dan Donatur
// Memastikan integritas DropdownButtonFormField dan Set/Map collection

import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/anak.dart';
import 'package:beasiswa_jamaah/models/donatur.dart';

void main() {
  group('Model Equality & HashCode Tests', () {
    test('Anak dengan id sama dianggap sama (equal) dan memiliki hashCode identik', () {
      const anakA = Anak(
        id: 1,
        kodeAnak: 'A-01',
        namaLengkap: 'Fauzi',
        namaSamaran: 'F. - SD',
        jenjang: Jenjang.sd,
        kelas: 2,
        namaWali: 'Wali A',
        statusYatim: StatusYatim.yatim,
        jumlahSaudara: 2,
        kondisiEkonomi: KondisiEkonomi.kurang,
        statusPip: StatusPip.belum,
        buruhTani: false,
        tanggalMasuk: '2026-01-01',
        aktif: true,
      );

      const anakB = Anak(
        id: 1,
        kodeAnak: 'A-01',
        namaLengkap: 'Fauzi (Updated)',
        namaSamaran: 'F. - SD',
        jenjang: Jenjang.sd,
        kelas: 3,
        namaWali: 'Wali A',
        statusYatim: StatusYatim.yatim,
        jumlahSaudara: 2,
        kondisiEkonomi: KondisiEkonomi.kurang,
        statusPip: StatusPip.belum,
        buruhTani: false,
        tanggalMasuk: '2026-01-01',
        aktif: true,
      );

      const anakLain = Anak(
        id: 2,
        kodeAnak: 'A-02',
        namaLengkap: 'Budi',
        namaSamaran: 'B. - SD',
        jenjang: Jenjang.sd,
        kelas: 2,
        namaWali: 'Wali B',
        statusYatim: StatusYatim.yatim,
        jumlahSaudara: 1,
        kondisiEkonomi: KondisiEkonomi.cukup,
        statusPip: StatusPip.sudahMenerima,
        buruhTani: false,
        tanggalMasuk: '2026-01-01',
        aktif: true,
      );

      expect(anakA == anakB, isTrue);
      expect(anakA.hashCode == anakB.hashCode, isTrue);
      expect(anakA == anakLain, isFalse);

      final himpunan = {anakA};
      expect(himpunan.contains(anakB), isTrue);
    });

    test('Donatur dengan id sama dianggap sama (equal) dan memiliki hashCode identik', () {
      const donaturA = Donatur(
        id: 10,
        namaKeluarga: 'Keluarga Bpk. Ahmad',
        nominalIuran: 30000,
        statusAktif: true,
        tanggalDaftar: '2026-01-01',
      );

      const donaturB = Donatur(
        id: 10,
        namaKeluarga: 'Keluarga Bpk. Ahmad (Re-read)',
        nominalIuran: 35000,
        statusAktif: true,
        tanggalDaftar: '2026-01-01',
      );

      const donaturLain = Donatur(
        id: 11,
        namaKeluarga: 'Keluarga Bpk. Budi',
        nominalIuran: 30000,
        statusAktif: true,
        tanggalDaftar: '2026-01-01',
      );

      expect(donaturA == donaturB, isTrue);
      expect(donaturA.hashCode == donaturB.hashCode, isTrue);
      expect(donaturA == donaturLain, isFalse);

      final himpunan = {donaturA};
      expect(himpunan.contains(donaturB), isTrue);
    });
  });
}
