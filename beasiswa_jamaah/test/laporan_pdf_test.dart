import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/models/anak.dart';
import 'package:beasiswa_jamaah/models/donatur.dart';
import 'package:beasiswa_jamaah/models/iuran.dart';
import 'package:beasiswa_jamaah/models/penyaluran.dart';
import 'package:beasiswa_jamaah/models/transaksi_kas.dart';
import 'package:beasiswa_jamaah/services/laporan_pdf_service.dart';

void main() {
  group('LaporanPdfService Tests', () {
    const donatur1 = Donatur(
      id: 1,
      namaKeluarga: 'Keluarga Bpk. H. Ahmad',
      nominalIuran: 30000,
      statusAktif: true,
      tanggalDaftar: '2026-01-01',
    );

    const donatur2 = Donatur(
      id: 2,
      namaKeluarga: 'Keluarga Ibu Siti',
      nominalIuran: 25000,
      statusAktif: true,
      tanggalDaftar: '2026-01-15',
    );

    const anak1 = Anak(
      id: 1,
      kodeAnak: 'A-01',
      namaLengkap: 'Ahmad Fauzi Rahardjo', // Full private name
      namaSamaran: 'A.F. - SD Kelas 3',
      jenjang: Jenjang.sd,
      kelas: 3,
      namaWali: 'Ibu Rahmawati',
      statusYatim: StatusYatim.yatim,
      jumlahSaudara: 2,
      kondisiEkonomi: KondisiEkonomi.sangatKurang,
      statusPip: StatusPip.belum,
      buruhTani: true,
      tanggalMasuk: '2026-01-01',
      aktif: true,
    );

    const anak2 = Anak(
      id: 2,
      kodeAnak: 'A-02',
      namaLengkap: 'Nurul Hidayati Kusuma',
      namaSamaran: 'N.H. - SMP Kelas 8',
      jenjang: Jenjang.smp,
      kelas: 8,
      namaWali: 'Bpk. Santoso',
      statusYatim: StatusYatim.piatu,
      jumlahSaudara: 1,
      kondisiEkonomi: KondisiEkonomi.kurang,
      statusPip: StatusPip.sudahMenerima,
      buruhTani: false,
      tanggalMasuk: '2026-01-01',
      aktif: true,
    );

    const iuran1 = Iuran(
      id: 1,
      donaturId: 1,
      bulan: 1,
      tahunAjaran: 2026,
      nominal: 30000,
      tanggalBayar: '2026-01-05',
    );

    const iuran2 = Iuran(
      id: 2,
      donaturId: 1,
      bulan: 2,
      tahunAjaran: 2026,
      nominal: 30000,
      tanggalBayar: '2026-02-05',
    );

    final matriksIuran = <int, Map<int, Iuran>>{
      1: {1: iuran1, 2: iuran2},
    };

    const daftarTransaksiKas = [
      TransaksiKas(
        id: 1,
        tanggal: '2026-01-05',
        tipe: TipeTransaksi.masuk,
        kategori: KategoriTransaksi.iuran,
        nominal: 30000,
        keterangan: 'Iuran Januari Donatur 1',
      ),
      TransaksiKas(
        id: 2,
        tanggal: '2026-02-05',
        tipe: TipeTransaksi.masuk,
        kategori: KategoriTransaksi.iuran,
        nominal: 30000,
        keterangan: 'Iuran Februari Donatur 1',
      ),
      TransaksiKas(
        id: 3,
        tanggal: '2026-03-10',
        tipe: TipeTransaksi.keluar,
        kategori: KategoriTransaksi.perlengkapan,
        nominal: 450000,
        keterangan: 'Seragam Toko Barokah',
      ),
    ];

    const daftarPenyaluran = [
      Penyaluran(
        id: 1,
        anakId: 1,
        tanggal: '2026-03-10',
        jenis: JenisPenyaluran.seragam,
        nominal: 450000,
        penerima: 'Toko Seragam Berkah',
        keterangan: '2 stel seragam merah putih',
      ),
      Penyaluran(
        id: 2,
        anakId: 1,
        tanggal: '2026-04-01',
        jenis: JenisPenyaluran.uangSaku,
        nominal: 150000,
        penerima: 'Ibu Rahmawati',
        keterangan: 'Uang saku April via wali',
      ),
    ];

    test('generateLaporanPdf menghasilkan dokumen Uint8List untuk Semester 1',
        () async {
      final bytes = await LaporanPdfService.generateLaporanPdf(
        tahunAjaran: 2026,
        periode: PeriodeLaporan.semester1,
        daftarDonatur: [donatur1, donatur2],
        matriksIuran: matriksIuran,
        daftarAnak: [anak1, anak2],
        daftarPenyaluran: daftarPenyaluran,
        daftarTransaksiKas: daftarTransaksiKas,
        persentaseCadangan: 10,
        biayaSd: 2310000,
        biayaSmp: 3575000,
        biayaSma: 4785000,
        pipSd: 450000,
        pipSmp: 750000,
        pipSma: 1800000,
        putusSekolah: 0,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      // Validasi PDF signature header (%PDF-)
      final pdfHeader = String.fromCharCodes(bytes.sublist(0, 5));
      expect(pdfHeader, equals('%PDF-'));
    });

    test('generateLaporanPdf menghasilkan dokumen valid untuk Semester 2 & Setahun',
        () async {
      final bytesSem2 = await LaporanPdfService.generateLaporanPdf(
        tahunAjaran: 2026,
        periode: PeriodeLaporan.semester2,
        daftarDonatur: [donatur1],
        matriksIuran: matriksIuran,
        daftarAnak: [anak1],
        daftarPenyaluran: daftarPenyaluran,
        daftarTransaksiKas: daftarTransaksiKas,
        persentaseCadangan: 10,
        biayaSd: 2310000,
        biayaSmp: 3575000,
        biayaSma: 4785000,
        pipSd: 450000,
        pipSmp: 750000,
        pipSma: 1800000,
        putusSekolah: 0,
      );
      expect(bytesSem2.isNotEmpty, isTrue);

      final bytesSetahun = await LaporanPdfService.generateLaporanPdf(
        tahunAjaran: 2026,
        periode: PeriodeLaporan.setahun,
        daftarDonatur: [donatur1, donatur2],
        matriksIuran: matriksIuran,
        daftarAnak: [anak1, anak2],
        daftarPenyaluran: daftarPenyaluran,
        daftarTransaksiKas: daftarTransaksiKas,
        persentaseCadangan: 10,
        biayaSd: 2310000,
        biayaSmp: 3575000,
        biayaSma: 4785000,
        pipSd: 450000,
        pipSmp: 750000,
        pipSma: 1800000,
        putusSekolah: 0,
      );
      expect(bytesSetahun.isNotEmpty, isTrue);
    });

    test('generateLaporanPdf menjaga privasi nama lengkap anak', () async {
      // Inisial/samaran anak: "A.F. - SD Kelas 3"
      expect(anak1.namaSamaran, contains('A.F.'));
      expect(anak2.namaSamaran, contains('N.H.'));

      final bytes = await LaporanPdfService.generateLaporanPdf(
        tahunAjaran: 2026,
        periode: PeriodeLaporan.semester1,
        daftarDonatur: [donatur1],
        matriksIuran: matriksIuran,
        daftarAnak: [anak1],
        daftarPenyaluran: daftarPenyaluran,
        daftarTransaksiKas: daftarTransaksiKas,
        persentaseCadangan: 10,
        biayaSd: 2310000,
        biayaSmp: 3575000,
        biayaSma: 4785000,
        pipSd: 450000,
        pipSmp: 750000,
        pipSma: 1800000,
        putusSekolah: 0,
      );

      // Pastikan nama lengkap anak "Ahmad Fauzi Rahardjo" tidak bocor dalam representasi teks PDF
      final pdfContent = String.fromCharCodes(bytes);
      expect(pdfContent.contains('Ahmad Fauzi Rahardjo'), isFalse);
    });
  });
}
