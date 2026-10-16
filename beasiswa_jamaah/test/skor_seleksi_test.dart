// Unit test: Skor Seleksi dan Kebutuhan Dana per Jenjang
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/anak.dart';
import 'package:beasiswa_jamaah/utils/skor_seleksi.dart';

void main() {
  group('Skor Kelayakan Seleksi Anak', () {
    const bobotEkonomi = 40;
    const bobotYatim = 30;
    const bobotSaudara = 15;
    const bobotKip = 15;

    test('Anak prioritas tinggi (yatim piatu, sangat kurang, 4 saudara, belum PIP) mendapat skor maksimal', () {
      final skor = hitungSkor(
        kondisiEkonomi: KondisiEkonomi.sangatKurang,
        statusYatim: StatusYatim.yatimPiatu,
        jumlahSaudara: 4,
        statusPip: StatusPip.belum,
        bobotEkonomi: bobotEkonomi,
        bobotYatim: bobotYatim,
        bobotSaudara: bobotSaudara,
        bobotKip: bobotKip,
      );

      expect(skor, 100);
    });

    test('Anak prioritas rendah (lengkap, cukup, 0 saudara, sudah PIP) mendapat skor minimal', () {
      final skor = hitungSkor(
        kondisiEkonomi: KondisiEkonomi.cukup,
        statusYatim: StatusYatim.lengkap,
        jumlahSaudara: 0,
        statusPip: StatusPip.sudahMenerima,
        bobotEkonomi: bobotEkonomi,
        bobotYatim: bobotYatim,
        bobotSaudara: bobotSaudara,
        bobotKip: bobotKip,
      );

      // Hanya dapat poin parsial dari kondisi cukup (0.25 * 40 = 10)
      expect(skor, 10);
    });

    test('Skor seleksi dinamis mengikuti perubahan bobot pengaturan', () {
      // Bobot baru: ekonomi dominan 60 poin, yatim 20, saudara 10, kip 10
      final skor = hitungSkor(
        kondisiEkonomi: KondisiEkonomi.sangatKurang, // 1.0 * 60 = 60
        statusYatim: StatusYatim.lengkap,           // 0
        jumlahSaudara: 0,                           // 0
        statusPip: StatusPip.sudahMenerima,         // 0
        bobotEkonomi: 60,
        bobotYatim: 20,
        bobotSaudara: 10,
        bobotKip: 10,
      );

      expect(skor, 60);
    });
  });

  group('Kalkulasi Kebutuhan Dana per Jenjang (dengan dan tanpa PIP)', () {
    const biayaSd = 2310000;
    const biayaSmp = 3575000;
    const biayaSma = 4785000;

    const pipSd = 450000;
    const pipSmp = 750000;
    const pipSma = 1800000;

    test('SD: tanpa PIP = Rp2.310.000, dengan PIP = Rp1.860.000', () {
      final tanpaPip = hitungKebutuhanDana(
        jenjang: Jenjang.sd,
        statusPip: StatusPip.belum,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(tanpaPip, 2310000);

      final denganPip = hitungKebutuhanDana(
        jenjang: Jenjang.sd,
        statusPip: StatusPip.sudahMenerima,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(denganPip, 2310000 - 450000);
      expect(denganPip, 1860000);
    });

    test('SMP: tanpa PIP = Rp3.575.000, dengan PIP = Rp2.825.000', () {
      final tanpaPip = hitungKebutuhanDana(
        jenjang: Jenjang.smp,
        statusPip: StatusPip.belum,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(tanpaPip, 3575000);

      final denganPip = hitungKebutuhanDana(
        jenjang: Jenjang.smp,
        statusPip: StatusPip.sudahMenerima,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(denganPip, 3575000 - 750000);
      expect(denganPip, 2825000);
    });

    test('SMA: tanpa PIP = Rp4.785.000, dengan PIP = Rp2.985.000', () {
      final tanpaPip = hitungKebutuhanDana(
        jenjang: Jenjang.sma,
        statusPip: StatusPip.belum,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(tanpaPip, 4785000);

      final denganPip = hitungKebutuhanDana(
        jenjang: Jenjang.sma,
        statusPip: StatusPip.sudahMenerima,
        biayaSd: biayaSd,
        biayaSmp: biayaSmp,
        biayaSma: biayaSma,
        pipSd: pipSd,
        pipSmp: pipSmp,
        pipSma: pipSma,
      );
      expect(denganPip, 4785000 - 1800000);
      expect(denganPip, 2985000);
    });
  });
}
