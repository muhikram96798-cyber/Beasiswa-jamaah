// Service: LaporanPdfService
// Menghasilkan dokumen PDF laporan pertanggungjawaban program per semester
// Sesuai proposal:
// 1. Rekapitulasi kas: pemasukan, pengeluaran, saldo, pos cadangan 10%.
// 2. Status pembayaran seluruh donatur (matriks bayar).
// 3. Daftar anak penerima manfaat (HANYA nama samaran & kode internal, privasi terjaga).
// 4. Rincian penyaluran: toko/penjahit untuk barang, wali/ortu untuk uang saku.
// 5. Sisa kebutuhan anak yang belum terpenuhi.

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/anak.dart';
import '../models/donatur.dart';
import '../models/iuran.dart';
import '../models/penyaluran.dart';
import '../models/transaksi_kas.dart';
import '../services/donatur_service.dart';
import '../utils/rupiah_formatter.dart';
import '../utils/skor_seleksi.dart';

enum PeriodeLaporan { semester1, semester2, setahun }

extension PeriodeLaporanX on PeriodeLaporan {
  String get label {
    switch (this) {
      case PeriodeLaporan.semester1:
        return 'Semester 1 (Januari - Juni)';
      case PeriodeLaporan.semester2:
        return 'Semester 2 (Juli - Desember)';
      case PeriodeLaporan.setahun:
        return 'Satu Tahun Penuh (Januari - Desember)';
    }
  }

  int get bulanMulai {
    switch (this) {
      case PeriodeLaporan.semester1:
        return 1;
      case PeriodeLaporan.semester2:
        return 7;
      case PeriodeLaporan.setahun:
        return 1;
    }
  }

  int get bulanAkhir {
    switch (this) {
      case PeriodeLaporan.semester1:
        return 6;
      case PeriodeLaporan.semester2:
        return 12;
      case PeriodeLaporan.setahun:
        return 12;
    }
  }
}

class LaporanPdfService {
  /// Generate byte data dokumen PDF laporan program
  static Future<Uint8List> generateLaporanPdf({
    required int tahunAjaran,
    required PeriodeLaporan periode,
    required List<Donatur> daftarDonatur,
    required Map<int, Map<int, Iuran>> matriksIuran,
    required List<Anak> daftarAnak,
    required List<Penyaluran> daftarPenyaluran,
    required List<TransaksiKas> daftarTransaksiKas,
    required int persentaseCadangan,
    required int biayaSd,
    required int biayaSmp,
    required int biayaSma,
    required int pipSd,
    required int pipSmp,
    required int pipSma,
    required int putusSekolah,
  }) async {
    final pdf = pw.Document();

    final bulanMulai = periode.bulanMulai;
    final bulanAkhir = periode.bulanAkhir;

    // Filter transaksi kas sesuai periode
    final transaksiPeriode = daftarTransaksiKas.where((t) {
      final tgl = DateTime.tryParse(t.tanggal);
      if (tgl == null) return false;
      return tgl.year == tahunAjaran &&
          tgl.month >= bulanMulai &&
          tgl.month <= bulanAkhir;
    }).toList();

    int totalMasukPeriode = 0;
    int totalKeluarPeriode = 0;
    for (final t in transaksiPeriode) {
      if (t.tipe == TipeTransaksi.masuk) {
        totalMasukPeriode += t.nominal;
      } else {
        totalKeluarPeriode += t.nominal;
      }
    }

    // Saldo kas kumulatif s.d. akhir periode
    final transaksiKumulatif = daftarTransaksiKas.where((t) {
      final tgl = DateTime.tryParse(t.tanggal);
      if (tgl == null) return false;
      if (tgl.year < tahunAjaran) return true;
      if (tgl.year == tahunAjaran && tgl.month <= bulanAkhir) return true;
      return false;
    }).toList();

    int totalMasukKumulatif = 0;
    int totalKeluarKumulatif = 0;
    int cadanganTerpakaiKumulatif = 0;
    for (final t in transaksiKumulatif) {
      if (t.tipe == TipeTransaksi.masuk) {
        totalMasukKumulatif += t.nominal;
      } else {
        totalKeluarKumulatif += t.nominal;
        if (t.menggunakanCadangan) {
          cadanganTerpakaiKumulatif += t.nominal;
        }
      }
    }

    final totalSaldoKas = totalMasukKumulatif - totalKeluarKumulatif;
    final cadanganWajib =
        (totalMasukKumulatif * (persentaseCadangan / 100.0)).round();
    final sisaCadangan = cadanganWajib - cadanganTerpakaiKumulatif;
    final cadanganTersedia = totalSaldoKas > 0
        ? (sisaCadangan > totalSaldoKas
            ? totalSaldoKas
            : (sisaCadangan > 0 ? sisaCadangan : 0))
        : 0;
    final saldoBisaDipakai = totalSaldoKas - cadanganTersedia;

    // Filter penyaluran sesuai periode
    final penyaluranPeriode = daftarPenyaluran.where((p) {
      final tgl = DateTime.tryParse(p.tanggal);
      if (tgl == null) return false;
      return tgl.year == tahunAjaran &&
          tgl.month >= bulanMulai &&
          tgl.month <= bulanAkhir;
    }).toList();

    // Map total penyaluran kumulatif per anak di tahun ajaran ini
    final totalPenyaluranTahunPerAnak = <int, int>{};
    for (final p in daftarPenyaluran) {
      final tgl = DateTime.tryParse(p.tanggal);
      if (tgl != null && tgl.year == tahunAjaran) {
        totalPenyaluranTahunPerAnak[p.anakId] =
            (totalPenyaluranTahunPerAnak[p.anakId] ?? 0) + p.nominal;
      }
    }

    // Tanggal Cetak
    final now = DateTime.now();
    final tglCetakStr =
        '${now.day} ${DonaturService.getNamaBulan(now.month)} ${now.year}';

    // ─────────────────────────────────────────────────────────────────────────
    // HALAMAN 1: KOP, RINGKASAN KAS, INDIKATOR PROPOSAL, & MATRIKS DONATUR
    // ─────────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // KOP LAPORAN
            _buildKopLaporan(
              tahunAjaran: tahunAjaran,
              periode: periode,
              tanggalCetak: tglCetakStr,
            ),
            pw.SizedBox(height: 16),

            // 1. RINGKASAN KEUANGAN KAS
            pw.Text(
              '1. RINGKASAN KEUANGAN KAS BERSAMA',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            _buildTabelKas(
              masukPeriode: totalMasukPeriode,
              keluarPeriode: totalKeluarPeriode,
              totalSaldo: totalSaldoKas,
              cadanganTersedia: cadanganTersedia,
              saldoSiapPakai: saldoBisaDipakai > 0 ? saldoBisaDipakai : 0,
              persenCadangan: persentaseCadangan,
            ),
            pw.SizedBox(height: 14),

            // 2. CAPAIAN INDIKATOR PROPOSAL
            pw.Text(
              '2. CAPAIAN INDIKATOR PROGRAM',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            _buildTabelIndikator(
              anakAktif: daftarAnak.where((a) => a.aktif).length,
              targetAnak: 10,
              putusSekolah: putusSekolah,
            ),
            pw.SizedBox(height: 14),

            // 3. MATRIKS IURAN DONATUR
            pw.Text(
              '3. REKAPITULASI IURAN DONATUR KELUARGA JAMAAH',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Setiap keluarga jamaah berkomitmen iuran Rp20.000 - Rp30.000 per bulan masuk satu kas bersama.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            _buildTabelDonatur(
              daftarDonatur: daftarDonatur,
              matriksIuran: matriksIuran,
              bulanMulai: bulanMulai,
              bulanAkhir: bulanAkhir,
            ),
            pw.SizedBox(height: 16),

            // 4. DAFTAR ANAK PENERIMA BEASISWA (PRIVASI TERJAGA)
            pw.Text(
              '4. DAFTAR ANAK PENERIMA MANFAAT (IDENTITAS DISAMARKAN)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '*Sesuai SOP program, identitas anak dijaga kehormatannya dan disamarkan dengan kode inisial.',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            _buildTabelAnak(
              daftarAnak: daftarAnak.where((a) => a.aktif).toList(),
              totalPenyaluranPerAnak: totalPenyaluranTahunPerAnak,
              biayaSd: biayaSd,
              biayaSmp: biayaSmp,
              biayaSma: biayaSma,
              pipSd: pipSd,
              pipSmp: pipSmp,
              pipSma: pipSma,
            ),
            pw.SizedBox(height: 16),

            // 5. RINCIAN REALISASI PENYALURAN BANTUAN
            pw.Text(
              '5. RINCIAN PENYALURAN BANTUAN PADA PERIODE INI',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Perlengkapan sekolah (seragam, sepatu, tas, buku) dibeli langsung ke toko/penjahit. Uang saku disalurkan melalui wali kelas/orang tua.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            _buildTabelPenyaluran(
              penyaluranList: penyaluranPeriode,
              daftarAnak: daftarAnak,
            ),
            pw.SizedBox(height: 24),

            // 6. LEMBAR PENGESAHAN PENGURUS
            _buildLembarPengesahan(tanggalCetak: tglCetakStr),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ─── KOMPONEN KOP LAPORAN ─────────────────────────────────────────────────
  static pw.Widget _buildKopLaporan({
    required int tahunAjaran,
    required PeriodeLaporan periode,
    required String tanggalCetak,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'PROGRAM BEASISWA JAMAAH TETAP',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'LAPORAN PERTANGGUNGJAWABAN PENYALURAN BEASISWA PENDIDIKAN',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Periode: ${periode.label} | Tahun Ajaran $tahunAjaran',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.Text(
            'Tanggal Terbit Laporan: $tanggalCetak',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ─── TABEL KEUANGAN KAS ───────────────────────────────────────────────────
  static pw.Widget _buildTabelKas({
    required int masukPeriode,
    required int keluarPeriode,
    required int totalSaldo,
    required int cadanganTersedia,
    required int saldoSiapPakai,
    required int persenCadangan,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _selHeader('Pemasukan Periode Ini'),
            _selHeader('Pengeluaran Periode Ini'),
            _selHeader('Total Saldo Kas'),
            _selHeader('Dana Cadangan ($persenCadangan%)'),
            _selHeader('Saldo Siap Pakai'),
          ],
        ),
        pw.TableRow(
          children: [
            _selData(formatRupiah(masukPeriode), align: pw.TextAlign.center),
            _selData(formatRupiah(keluarPeriode), align: pw.TextAlign.center),
            _selData(formatRupiah(totalSaldo),
                align: pw.TextAlign.center, isBold: true),
            _selData(formatRupiah(cadanganTersedia),
                align: pw.TextAlign.center),
            _selData(formatRupiah(saldoSiapPakai),
                align: pw.TextAlign.center, isBold: true),
          ],
        ),
      ],
    );
  }

  // ─── TABEL INDIKATOR PROPOSAL ─────────────────────────────────────────────
  static pw.Widget _buildTabelIndikator({
    required int anakAktif,
    required int targetAnak,
    required int putusSekolah,
  }) {
    final statusPutus = putusSekolah == 0
        ? 'Target Terjaga (0 Anak Putus Sekolah)'
        : '$putusSekolah Anak (Perlu Pendampingan)';

    final statusAnak = anakAktif >= targetAnak
        ? 'Target Tercapai ($anakAktif / $targetAnak Anak)'
        : '$anakAktif / $targetAnak Anak Terbantu';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _selHeader('Indikator Keberhasilan'),
            _selHeader('Target Proposal'),
            _selHeader('Capaian Realisasi'),
          ],
        ),
        pw.TableRow(
          children: [
            _selData('Anak Yatim/Dhuafa Terbantu'),
            _selData('Tahap Awal: 10 Anak', align: pw.TextAlign.center),
            _selData(statusAnak, isBold: true),
          ],
        ),
        pw.TableRow(
          children: [
            _selData('Anak Putus Sekolah'),
            _selData('0 Anak (Nol Kasus)', align: pw.TextAlign.center),
            _selData(statusPutus, isBold: true),
          ],
        ),
      ],
    );
  }

  // ─── TABEL DONATUR & STATUS BAYAR ─────────────────────────────────────────
  static pw.Widget _buildTabelDonatur({
    required List<Donatur> daftarDonatur,
    required Map<int, Map<int, Iuran>> matriksIuran,
    required int bulanMulai,
    required int bulanAkhir,
  }) {
    final listBulan = List.generate(
      bulanAkhir - bulanMulai + 1,
      (i) => bulanMulai + i,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _selHeader('No', width: 24),
            _selHeader('Nama Keluarga Donatur'),
            _selHeader('Iuran/Bln'),
            ...listBulan.map(
              (b) => _selHeader(DonaturService.getSingkatanBulan(b)),
            ),
            _selHeader('Total'),
          ],
        ),
        if (daftarDonatur.isEmpty)
          pw.TableRow(
            children: [
              _selData('Belum ada data donatur', colSpan: listBulan.length + 4),
            ],
          )
        else
          ...daftarDonatur.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final d = entry.value;
            int totalBayar = 0;

            final statusPerBulan = listBulan.map((b) {
              final iuran = matriksIuran[d.id]?[b];
              if (iuran != null) {
                totalBayar += iuran.nominal;
                return _selData('L',
                    align: pw.TextAlign.center, color: PdfColors.green800);
              } else {
                return _selData('-',
                    align: pw.TextAlign.center, color: PdfColors.grey400);
              }
            }).toList();

            return pw.TableRow(
              children: [
                _selData('$idx', align: pw.TextAlign.center),
                _selData(d.namaKeluarga),
                _selData(formatRupiah(d.nominalIuran),
                    align: pw.TextAlign.right),
                ...statusPerBulan,
                _selData(formatRupiah(totalBayar),
                    align: pw.TextAlign.right, isBold: true),
              ],
            );
          }),
      ],
    );
  }

  // ─── TABEL ANAK PENERIMA MANFAAT ──────────────────────────────────────────
  static pw.Widget _buildTabelAnak({
    required List<Anak> daftarAnak,
    required Map<int, int> totalPenyaluranPerAnak,
    required int biayaSd,
    required int biayaSmp,
    required int biayaSma,
    required int pipSd,
    required int pipSmp,
    required int pipSma,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _selHeader('Kode'),
            _selHeader('Inisial & Jenjang'),
            _selHeader('Status KIP/PIP'),
            _selHeader('Target Kebutuhan'),
            _selHeader('Tersalurkan'),
            _selHeader('Sisa Kebutuhan'),
          ],
        ),
        if (daftarAnak.isEmpty)
          pw.TableRow(
            children: [
              _selData('Belum ada data anak penerima beasiswa', colSpan: 6),
            ],
          )
        else
          ...daftarAnak.map((anak) {
            final kebutuhanBersih = hitungKebutuhanDana(
              jenjang: anak.jenjang,
              statusPip: anak.statusPip,
              biayaSd: biayaSd,
              biayaSmp: biayaSmp,
              biayaSma: biayaSma,
              pipSd: pipSd,
              pipSmp: pipSmp,
              pipSma: pipSma,
            );
            final tersalurkan = totalPenyaluranPerAnak[anak.id] ?? 0;
            final sisa = (kebutuhanBersih - tersalurkan).clamp(0, kebutuhanBersih);

            return pw.TableRow(
              children: [
                _selData(anak.kodeAnak,
                    align: pw.TextAlign.center, isBold: true),
                _selData(anak.namaSamaran),
                _selData(anak.statusPip.label),
                _selData(formatRupiah(kebutuhanBersih),
                    align: pw.TextAlign.right),
                _selData(formatRupiah(tersalurkan),
                    align: pw.TextAlign.right, isBold: true),
                _selData(formatRupiah(sisa), align: pw.TextAlign.right),
              ],
            );
          }),
      ],
    );
  }

  // ─── TABEL RINCIAN REALISASI PENYALURAN ────────────────────────────────────
  static pw.Widget _buildTabelPenyaluran({
    required List<Penyaluran> penyaluranList,
    required List<Anak> daftarAnak,
  }) {
    final mapAnak = {for (final a in daftarAnak) a.id: a};

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _selHeader('Tgl'),
            _selHeader('Penerima / Toko'),
            _selHeader('Jenis'),
            _selHeader('Keterangan / Item'),
            _selHeader('Nominal'),
          ],
        ),
        if (penyaluranList.isEmpty)
          pw.TableRow(
            children: [
              _selData('Belum ada penyaluran bantuan pada periode ini',
                  colSpan: 5),
            ],
          )
        else
          ...penyaluranList.map((p) {
            final anak = mapAnak[p.anakId];
            final tgl = DateTime.tryParse(p.tanggal);
            final tglStr = tgl != null
                ? DateFormat('dd/MM/yy').format(tgl)
                : p.tanggal;

            final penerimaInfo = p.jenis == JenisPenyaluran.uangSaku
                ? 'Wali: ${p.penerima ?? '-'}'
                : 'Toko: ${p.penerima ?? '-'}';

            final labelAnak = anak != null ? anak.kodeAnak : '-';

            return pw.TableRow(
              children: [
                _selData(tglStr, align: pw.TextAlign.center),
                _selData('$labelAnak - $penerimaInfo'),
                _selData(p.jenis.label),
                _selData(p.keterangan.isNotEmpty ? p.keterangan : '-'),
                _selData(formatRupiah(p.nominal),
                    align: pw.TextAlign.right, isBold: true),
              ],
            );
          }),
      ],
    );
  }

  // ─── LEMBAR PENGESAHAN PENGURUS ───────────────────────────────────────────
  static pw.Widget _buildLembarPengesahan({required String tanggalCetak}) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Laporan ini disusun dengan sebenar-benarnya sebagai bentuk amanah dan pertanggungjawaban kepada jamaah.',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kolomTandaTangan('Ketua Pengurus', '....................................'),
              _kolomTandaTangan('Bendahara Kas', '....................................'),
              _kolomTandaTangan('Seksi Seleksi & Pendampingan', '....................................'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _kolomTandaTangan(String jabatan, String nama) {
    return pw.Column(
      children: [
        pw.Text(jabatan,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 40),
        pw.Text(nama, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  // ─── HELPER SEL TABEL ─────────────────────────────────────────────────────
  static pw.Widget _selHeader(String text, {double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green900,
        ),
      ),
    );
  }

  static pw.Widget _selData(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? color,
    int? colSpan,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
