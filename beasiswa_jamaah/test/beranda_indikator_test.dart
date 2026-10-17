// Unit Test: Logika Indikator Proposal & Metrik Beranda
// Menguji:
// 1. Indikator target 10 anak terbantu.
// 2. Indikator 0 anak putus sekolah (input manual, target default 0).
// 3. Persentase kebutuhan dana program terpenuhi (% tersalurkan).
// 4. Rasio ketertiban donatur aktif membayar iuran bulan berjalan.
// 5. Komparasi dana kas terkumpul vs target kebutuhan dana program.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/pengaturan.dart';

void main() {
  group('Indikator Proposal Program Beasiswa', () {
    test('Default indikator putus sekolah adalah 0 anak', () {
      final defaults = PengaturanKey.defaults;
      expect(defaults[PengaturanKey.putusSekolah], '0');
    });

    test('Indikator target 10 anak terbantu dihitung proporsional', () {
      const targetProposal = 10;

      // 0 anak
      expect(min(100.0, (0 / targetProposal) * 100.0), 0.0);

      // 5 anak
      expect(min(100.0, (5 / targetProposal) * 100.0), 50.0);

      // 10 anak (target terpenuhi penuh)
      expect(min(100.0, (10 / targetProposal) * 100.0), 100.0);

      // 12 anak (melebihi target, ter-clamp 100% untuk progress bar)
      expect(min(100.0, (12 / targetProposal) * 100.0), 100.0);
    });

    test('Indikator anak putus sekolah mendeteksi target terjaga (0) atau ada kasus', () {
      int putusSekolah = 0;
      bool targetTerjaga = putusSekolah == 0;
      expect(targetTerjaga, isTrue);

      putusSekolah = 1;
      targetTerjaga = putusSekolah == 0;
      expect(targetTerjaga, isFalse);
    });

    test('Indikator pemenuhan kebutuhan dana bersih dihitung akurat', () {
      const totalKebutuhan = 25000000; // Rp 25.000.000
      int totalTersalurkan = 15000000; // Rp 15.000.000

      double persen = totalKebutuhan > 0
          ? (totalTersalurkan / totalKebutuhan) * 100.0
          : 0.0;
      expect(persen, 60.0);

      totalTersalurkan = 25000000;
      persen = totalKebutuhan > 0
          ? (totalTersalurkan / totalKebutuhan) * 100.0
          : 0.0;
      expect(persen, 100.0);

      // Penanganan zero-division
      const totalKebutuhanNol = 0;
      final persenNol = totalKebutuhanNol > 0
          ? (totalTersalurkan / totalKebutuhanNol) * 100.0
          : 0.0;
      expect(persenNol, 0.0);
    });

    test('Rasio ketertiban donatur membayar iuran bulan ini', () {
      const totalDonaturAktif = 20;
      const jumlahBelumBayar = 4;
      const sudahBayar = totalDonaturAktif - jumlahBelumBayar; // 16

      final double rasio = totalDonaturAktif > 0
          ? (sudahBayar / totalDonaturAktif) * 100.0
          : 0.0;

      expect(sudahBayar, 16);
      expect(rasio, 80.0);
    });

    test('Komparasi dana kas masuk vs target kebutuhan program setahun', () {
      const totalPemasukanKas = 18000000;
      const totalKebutuhanTahun = 20000000;

      final double rasioPengumpulan = totalKebutuhanTahun > 0
          ? (totalPemasukanKas / totalKebutuhanTahun).clamp(0.0, 1.0)
          : 1.0;
      final int sisaPerluDikumpulkan =
          max(0, totalKebutuhanTahun - totalPemasukanKas);

      expect(rasioPengumpulan, 0.9);
      expect(sisaPerluDikumpulkan, 2000000);
    });
  });
}
