// Layar: LaporanScreen (TAHAP 7)
// Mengelola laporan pertanggungjawaban program beasiswa semesteran dan tahunan.
// Menyediakan rekap ringkas visual serta integrasi cetak/bagikan dokumen PDF resmi.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../models/transaksi_kas.dart';
import '../../providers/anak_provider.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../services/laporan_pdf_service.dart';
import '../../utils/rupiah_formatter.dart';
import 'pratinjau_laporan_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  PeriodeLaporan _periodeTerpilih = PeriodeLaporan.semester1;
  int? _tahunTerpilih;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pengaturan = context.read<PengaturanProvider>();
      setState(() {
        _tahunTerpilih = pengaturan.tahunAjaranAktif;
      });
      // Pastikan data donatur dan kas termuat
      context.read<DonaturProvider>().muatData(tahun: _tahunTerpilih);
      context.read<KasProvider>().muatData(
            persentaseCadangan: pengaturan.persentaseCadangan,
          );
      context.read<AnakProvider>().muatData();
      context.read<PenyaluranProvider>().muatData();
    });
  }

  void _bukaPratinjauPdf({
    required int tahun,
    required PeriodeLaporan periode,
    required DonaturProvider donaturProv,
    required KasProvider kasProv,
    required AnakProvider anakProv,
    required PenyaluranProvider penyaluranProv,
    required PengaturanProvider pengaturanProv,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PratinjauLaporanScreen(
          tahunAjaran: tahun,
          periode: periode,
          daftarDonatur: donaturProv.daftarDonatur,
          matriksIuran: donaturProv.matriksIuran,
          daftarAnak: anakProv.daftarAnak,
          daftarPenyaluran: penyaluranProv.daftarSemuaPenyaluran,
          daftarTransaksiKas: kasProv.daftarTransaksi,
          persentaseCadangan: pengaturanProv.persentaseCadangan,
          biayaSd: pengaturanProv.biayaSd,
          biayaSmp: pengaturanProv.biayaSmp,
          biayaSma: pengaturanProv.biayaSma,
          pipSd: pengaturanProv.pipSd,
          pipSmp: pengaturanProv.pipSmp,
          pipSma: pengaturanProv.pipSma,
          putusSekolah: pengaturanProv.putusSekolah,
        ),
      ),
    );
  }

  Future<void> _bagikanLangsung({
    required int tahun,
    required PeriodeLaporan periode,
    required DonaturProvider donaturProv,
    required KasProvider kasProv,
    required AnakProvider anakProv,
    required PenyaluranProvider penyaluranProv,
    required PengaturanProvider pengaturanProv,
  }) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Menyiapkan file PDF laporan...'),
          duration: Duration(seconds: 1),
        ),
      );

      final bytes = await LaporanPdfService.generateLaporanPdf(
        tahunAjaran: tahun,
        periode: periode,
        daftarDonatur: donaturProv.daftarDonatur,
        matriksIuran: donaturProv.matriksIuran,
        daftarAnak: anakProv.daftarAnak,
        daftarPenyaluran: penyaluranProv.daftarSemuaPenyaluran,
        daftarTransaksiKas: kasProv.daftarTransaksi,
        persentaseCadangan: pengaturanProv.persentaseCadangan,
        biayaSd: pengaturanProv.biayaSd,
        biayaSmp: pengaturanProv.biayaSmp,
        biayaSma: pengaturanProv.biayaSma,
        pipSd: pengaturanProv.pipSd,
        pipSmp: pengaturanProv.pipSmp,
        pipSma: pengaturanProv.pipSma,
        putusSekolah: pengaturanProv.putusSekolah,
      );

      final namaFile =
          'Laporan_Beasiswa_Jamaah_${tahun}_${periode.name}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: namaFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengaturanProv = context.watch<PengaturanProvider>();
    final donaturProv = context.watch<DonaturProvider>();
    final kasProv = context.watch<KasProvider>();
    final anakProv = context.watch<AnakProvider>();
    final penyaluranProv = context.watch<PenyaluranProvider>();

    final tahunAktif = _tahunTerpilih ?? pengaturanProv.tahunAjaranAktif;

    // Filter kalkulasi ringkas untuk tampilan on-screen
    final bulanMulai = _periodeTerpilih.bulanMulai;
    final bulanAkhir = _periodeTerpilih.bulanAkhir;

    final transaksiPeriode = kasProv.daftarTransaksi.where((t) {
      final tgl = DateTime.tryParse(t.tanggal);
      if (tgl == null) return false;
      return tgl.year == tahunAktif &&
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

    final totalAnakAktif = anakProv.anakAktif.length;
    final totalDonaturAktif = donaturProv.donaturAktif.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Pertanggungjawaban',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await donaturProv.muatData(tahun: tahunAktif);
          await kasProv.muatData(
            persentaseCadangan: pengaturanProv.persentaseCadangan,
          );
          await anakProv.muatData();
          await penyaluranProv.muatData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── KARTU PEMILIHAN PERIODE & TAHUN ──────────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pilih Periode Laporan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Pilihan Tahun
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: tahunAktif,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: [
                                  tahunAktif - 1,
                                  tahunAktif,
                                  tahunAktif + 1,
                                ].map((thn) {
                                  return DropdownMenuItem<int>(
                                    value: thn,
                                    child: Text(
                                      'Tahun $thn',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _tahunTerpilih = val;
                                    });
                                    donaturProv.muatData(tahun: val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pilihan Semester / Setahun
                      SegmentedButton<PeriodeLaporan>(
                        segments: const [
                          ButtonSegment(
                            value: PeriodeLaporan.semester1,
                            label: Text('Sem 1 (Jan-Jun)'),
                          ),
                          ButtonSegment(
                            value: PeriodeLaporan.semester2,
                            label: Text('Sem 2 (Jul-Des)'),
                          ),
                          ButtonSegment(
                            value: PeriodeLaporan.setahun,
                            label: Text('1 Thn Penuh'),
                          ),
                        ],
                        selected: {_periodeTerpilih},
                        onSelectionChanged: (Set<PeriodeLaporan> newSelection) {
                          setState(() {
                            _periodeTerpilih = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── REKAP VISUAL CEPAT ──────────────────────────────────────────
              Card(
                color: const Color(0xFFF1F8E9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFA5D6A7)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ringkasan ${_periodeTerpilih.label}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildItemRingkasan(
                              label: 'Pemasukan Kas',
                              nilai: formatRupiah(totalMasukPeriode),
                              warna: const Color(0xFF2E7D32),
                              icon: Icons.arrow_downward,
                            ),
                          ),
                          Container(
                            height: 48,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildItemRingkasan(
                              label: 'Pengeluaran Kas',
                              nilai: formatRupiah(totalKeluarPeriode),
                              warna: const Color(0xFFC62828),
                              icon: Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildItemRingkasan(
                              label: 'Donatur Aktif',
                              nilai: '$totalDonaturAktif Orang',
                              warna: Colors.blueGrey.shade800,
                              icon: Icons.people_outline,
                            ),
                          ),
                          Container(
                            height: 48,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildItemRingkasan(
                              label: 'Anak Terbantu',
                              nilai: '$totalAnakAktif Siswa',
                              warna: Colors.blueGrey.shade800,
                              icon: Icons.school_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── KARTU KELENGKAPAN DOKUMEN PDF ──────────────────────────────
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Kepatuhan SOP & Privasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPoinChecklist(
                        '1. Rekapitulasi Kas & Pos Cadangan 10% terpisah.',
                      ),
                      _buildPoinChecklist(
                        '2. Evaluasi 4 Target Indikator Proposal Program.',
                      ),
                      _buildPoinChecklist(
                        '3. Matriks Transparansi Iuran Seluruh Donatur.',
                      ),
                      _buildPoinChecklist(
                        '4. Privasi Anak Terjaga (Kode & Inisial, Tanpa Nama Lengkap).',
                      ),
                      _buildPoinChecklist(
                        '5. Rincian Penyaluran Barang ke Toko & Uang ke Wali.',
                      ),
                      _buildPoinChecklist(
                        '6. Lembar Pengesahan Tanda Tangan Pengurus & DKM.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── TOMBOL AKSI UTAMA DOKUMEN PDF ───────────────────────────────
              FilledButton.icon(
                onPressed: () => _bukaPratinjauPdf(
                  tahun: tahunAktif,
                  periode: _periodeTerpilih,
                  donaturProv: donaturProv,
                  kasProv: kasProv,
                  anakProv: anakProv,
                  penyaluranProv: penyaluranProv,
                  pengaturanProv: pengaturanProv,
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text(
                  'Pratinjau & Cetak Dokumen PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _bagikanLangsung(
                  tahun: tahunAktif,
                  periode: _periodeTerpilih,
                  donaturProv: donaturProv,
                  kasProv: kasProv,
                  anakProv: anakProv,
                  penyaluranProv: penyaluranProv,
                  pengaturanProv: pengaturanProv,
                ),
                icon: const Icon(Icons.share, size: 20),
                label: const Text(
                  'Kirim File PDF (WhatsApp / Unduh)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRingkasan({
    required String label,
    required String nilai,
    required Color warna,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoinChecklist(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
