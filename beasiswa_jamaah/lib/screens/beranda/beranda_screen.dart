// Layar: Beranda Utama (Dashboard Program Beasiswa Jamaah Tetap)
// Menampilkan:
// 1. Saldo kas bersama, pos dana cadangan 10%, dan saldo siap pakai.
// 2. Status donatur aktif dan daftar yang belum bayar bulan ini.
// 3. Jumlah anak terbantu (target 10 anak).
// 4. Total kebutuhan dana vs dana terkumpul dan dana tersalurkan.
// 5. Indikator proposal: anak terbantu, putus sekolah (input manual), % terpenuhi.
// 6. Aksi Cepat (Quick Actions) untuk memudahkan pengurus awam.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../providers/anak_provider.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';
import '../anak/anak_form_screen.dart';
import '../donatur/catat_iuran_dialog.dart';
import '../donatur/donatur_form_screen.dart';
import '../pengaturan/pengaturan_screen.dart';
import '../penyaluran/penyaluran_form_screen.dart';

class BerandaScreen extends StatefulWidget {
  final void Function(int)? onPindahTab;

  const BerandaScreen({super.key, this.onPindahTab});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _segarkanSemuaData();
    });
  }

  Future<void> _segarkanSemuaData() async {
    final pengaturan = context.read<PengaturanProvider>();
    await pengaturan.muat();
    if (!mounted) return;
    await Future.wait([
      context.read<KasProvider>().muatData(
            persentaseCadangan: pengaturan.persentaseCadangan,
          ),
      context.read<DonaturProvider>().muatData(
            tahun: pengaturan.tahunAjaranAktif,
          ),
      context.read<AnakProvider>().muatData(),
      context.read<PenyaluranProvider>().muatData(),
    ]);
  }

  /// Dialog input manual untuk jumlah anak putus sekolah (target: 0)
  Future<void> _ubahPutusSekolah(int nilaiSekarang) async {
    final controller = TextEditingController(text: '$nilaiSekarang');
    final formKey = GlobalKey<FormState>();

    final hasil = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.green),
            SizedBox(width: 8),
            Text('Status Putus Sekolah'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indikator keberhasilan proposal menargetkan 0 anak putus sekolah. '
                'Masukkan jumlah anak jika ada kejadian putus sekolah:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Anak Putus Sekolah (Target: 0)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Masukkan angka (0 jika tidak ada)';
                  }
                  final n = int.tryParse(val.trim());
                  if (n == null || n < 0) {
                    return 'Masukkan angka 0 atau lebih';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final angka = int.parse(controller.text.trim());
                Navigator.of(ctx).pop(angka);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasil != null && mounted) {
      await context.read<PengaturanProvider>().setPutusSekolah(hasil);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text('Indikator anak putus sekolah diperbarui ($hasil anak)'),
          ),
        );
      }
    }
  }

  /// Tampilkan bottom sheet daftar donatur yang belum bayar bulan berjalan
  void _tampilkanDaftarBelumBayar(List<Donatur> daftarBelumBayar, int bulan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Donatur Belum Bayar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bulan ${DonaturService.getNamaBulan(bulan)} (${daftarBelumBayar.length} keluarga)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: daftarBelumBayar.isEmpty
                      ? const Center(
                          child: Text('Semua donatur aktif telah membayar!'),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: daftarBelumBayar.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final d = daftarBelumBayar[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                d.namaKeluarga,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Iuran: ${formatRupiah(d.nominalIuran)} / bulan',
                              ),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  final hasil = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => CatatIuranDialog(
                                      donatur: d,
                                      bulanAwal: bulan,
                                    ),
                                  );
                                  if (hasil == true && mounted) {
                                    await _segarkanSemuaData();
                                  }
                                },
                                child: const Text('Catat Bayar'),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog cepat untuk memilih donatur saat klik Quick Action "Catat Iuran"
  void _pilihDonaturUntukIuran() {
    final donaturProvider = context.read<DonaturProvider>();
    final daftar = donaturProvider.donaturAktif;

    if (daftar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada donatur aktif terdaftar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Donatur untuk Iuran'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (c, idx) {
              final d = daftar[idx];
              return ListTile(
                title: Text(d.namaKeluarga,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Iuran: ${formatRupiah(d.nominalIuran)}/bln'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final hasil = await showDialog<bool>(
                    context: context,
                    builder: (_) => CatatIuranDialog(donatur: d),
                  );
                  if (hasil == true && mounted) {
                    await _segarkanSemuaData();
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasProvider = context.watch<KasProvider>();
    final donaturProvider = context.watch<DonaturProvider>();
    final anakProvider = context.watch<AnakProvider>();
    final penyaluranProvider = context.watch<PenyaluranProvider>();
    final pengaturan = context.watch<PengaturanProvider>();

    final ringkasanKas = kasProvider.ringkasanKas;
    final bulanSekarang = DateTime.now().month;
    final tahunAktif = pengaturan.tahunAjaranAktif;

    final totalDonaturAktif = donaturProvider.totalDonaturAktif;
    final belumBayarBulanIni = donaturProvider.getDonaturBelumBayar(bulanSekarang);
    final sudahBayarBulanIni = max(0, totalDonaturAktif - belumBayarBulanIni.length);
    final persenTertib = totalDonaturAktif > 0
        ? (sudahBayarBulanIni / totalDonaturAktif) * 100.0
        : 0.0;

    final totalAnakAktif = anakProvider.totalAnakAktif;
    final targetAnakProposal = 10;
    final persenAnakTerbantu =
        min(100.0, (totalAnakAktif / targetAnakProposal) * 100.0);

    final totalKebutuhanBersih =
        anakProvider.hitungTotalKebutuhan(pengaturan);
    final totalTersalurkan = penyaluranProvider.totalPenyaluranSemua;
    final persenTersalurkan = totalKebutuhanBersih > 0
        ? (totalTersalurkan / totalKebutuhanBersih) * 100.0
        : 0.0;

    final putusSekolah = pengaturan.putusSekolah;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beasiswa Jamaah Tetap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tahun Ajaran $tahunAktif • Jamaah Tempat Ibadah',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan & Keamanan',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PengaturanScreen()),
              );
              if (context.mounted) {
                _segarkanSemuaData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan data',
            onPressed: _segarkanSemuaData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _segarkanSemuaData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. KARTU UTAMA KAS BERSAMA & CADANGAN 10% ─────────────────
              _bangunKartuKasUtama(
                context,
                ringkasanKas: ringkasanKas,
                tahun: tahunAktif,
              ),

              // ─── 2. PERHATIAN BULAN INI (DONATUR BELUM BAYAR) ─────────────
              _bangunKartuPeringatanIuran(
                context,
                totalAktif: totalDonaturAktif,
                belumBayar: belumBayarBulanIni,
                bulan: bulanSekarang,
                tahun: tahunAktif,
              ),

              // ─── 3. INDIKATOR PROPOSAL PROGRAM ────────────────────────────
              _bangunIndikatorProposal(
                context,
                anakAktif: totalAnakAktif,
                targetAnak: targetAnakProposal,
                persenAnak: persenAnakTerbantu,
                putusSekolah: putusSekolah,
                totalKebutuhan: totalKebutuhanBersih,
                totalTersalurkan: totalTersalurkan,
                persenTersalurkan: persenTersalurkan,
                sudahBayar: sudahBayarBulanIni,
                totalDonatur: totalDonaturAktif,
                persenTertib: persenTertib,
              ),

              // ─── 4. AKSI CEPAT PENGURUS (QUICK ACTIONS) ───────────────────
              _bangunAksiCepat(context),

              // ─── 5. KOMPARASI DANA TERKUMPUL VS TARGET TAHUNAN ─────────────
              _bangunKartuKomparasiDana(
                context,
                totalPemasukanKas: ringkasanKas.totalPemasukan,
                totalKebutuhan: totalKebutuhanBersih,
                totalTersalurkan: totalTersalurkan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGET BUILDER SECTIONS ──────────────────────────────────────────────

  /// Kartu Utama Kas Hijau Material 3
  Widget _bangunKartuKasUtama(
    BuildContext context, {
    required dynamic ringkasanKas,
    required int tahun,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800,
            Colors.green.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'KAS BERSAMA JAMAAH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tahun $tahun',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Saldo Siap Pakai (Bisa Disalurkan):',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            formatRupiah(ringkasanKas.saldoBisaDipakai),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Pos Dana Cadangan 10% & Total Kas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: Colors.amber.shade300),
                          const SizedBox(width: 4),
                          Text(
                            'Cadangan 10% (Tersedia):',
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(ringkasanKas.danaCadanganTersedia),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Keseluruhan Kas:',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(ringkasanKas.totalSaldo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Status Iuran Bulan Ini
  Widget _bangunKartuPeringatanIuran(
    BuildContext context, {
    required int totalAktif,
    required List<Donatur> belumBayar,
    required int bulan,
    required int tahun,
  }) {
    final namaBulan = DonaturService.getNamaBulan(bulan);
    final bool adaTunggakan = belumBayar.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: adaTunggakan ? Colors.amber.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: adaTunggakan ? Colors.amber.shade400 : Colors.green.shade300,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                adaTunggakan ? Colors.amber.shade100 : Colors.green.shade100,
            child: Icon(
              adaTunggakan ? Icons.priority_high : Icons.check_circle_outline,
              color:
                  adaTunggakan ? Colors.orange.shade900 : Colors.green.shade800,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adaTunggakan
                      ? '${belumBayar.length} Donatur Belum Bayar ($namaBulan)'
                      : 'Iuran $namaBulan Lunas Sempurna',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: adaTunggakan
                        ? Colors.orange.shade900
                        : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adaTunggakan
                      ? 'Dari $totalAktif donatur aktif. Tekan untuk melihat daftar & tagih.'
                      : 'Seluruh $totalAktif donatur aktif telah menyalurkan iuran tepat waktu.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          if (adaTunggakan)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _tampilkanDaftarBelumBayar(belumBayar, bulan),
              child: const Text('Lihat'),
            ),
        ],
      ),
    );
  }

  /// 4 Indikator Proposal Program
  Widget _bangunIndikatorProposal(
    BuildContext context, {
    required int anakAktif,
    required int targetAnak,
    required double persenAnak,
    required int putusSekolah,
    required int totalKebutuhan,
    required int totalTersalurkan,
    required double persenTersalurkan,
    required int sudahBayar,
    required int totalDonatur,
    required double persenTertib,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, size: 20, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Indikator Proposal Program',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid 2 x 2 Indikator
          Row(
            children: [
              // 1. Anak Terbantu (Target 10)
              Expanded(
                child: _kotakMetrik(
                  context,
                  judul: 'Anak Terbantu',
                  nilai: '$anakAktif / $targetAnak Anak',
                  subJudul: anakAktif >= targetAnak
                      ? 'Target tercapai 100%'
                      : 'Kurang ${targetAnak - anakAktif} anak',
                  progres: (anakAktif / targetAnak).clamp(0.0, 1.0),
                  warna: Colors.green.shade800,
                  ikon: Icons.school,
                  onTap: () => widget.onPindahTab?.call(3),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Anak Putus Sekolah (Target 0, Input Manual)
              Expanded(
                child: _kotakMetrik(
                  context,
                  judul: 'Putus Sekolah',
                  nilai: '$putusSekolah Anak',
                  subJudul: putusSekolah == 0
                      ? 'Target terjaga (0 anak)'
                      : 'Perlu pendampingan',
                  progres: putusSekolah == 0 ? 1.0 : 0.0,
                  warna: putusSekolah == 0
                      ? Colors.teal.shade700
                      : Colors.red.shade800,
                  ikon: putusSekolah == 0
                      ? Icons.verified
                      : Icons.warning_amber_rounded,
                  badgeText: 'Ubah Data',
                  onTap: () => _ubahPutusSekolah(putusSekolah),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // 3. Pemenuhan Kebutuhan Dana
              Expanded(
                child: _kotakMetrik(
                  context,
                  judul: 'Kebutuhan Terpenuhi',
                  nilai: '${persenTersalurkan.toStringAsFixed(1)}%',
                  subJudul:
                      '${formatRupiah(totalTersalurkan)} / ${formatRupiah(totalKebutuhan)}',
                  progres: (persenTersalurkan / 100.0).clamp(0.0, 1.0),
                  warna: Colors.blue.shade800,
                  ikon: Icons.pie_chart_outline,
                  onTap: () => widget.onPindahTab?.call(3),
                ),
              ),
              const SizedBox(width: 10),

              // 4. Donatur Aktif Membayar
              Expanded(
                child: _kotakMetrik(
                  context,
                  judul: 'Tertib Iuran Bulan Ini',
                  nilai: '$sudahBayar / $totalDonatur',
                  subJudul: '${persenTertib.toStringAsFixed(0)}% telah lunas',
                  progres: (persenTertib / 100.0).clamp(0.0, 1.0),
                  warna: Colors.deepPurple.shade700,
                  ikon: Icons.people,
                  onTap: () => widget.onPindahTab?.call(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu Kotak Metrik
  Widget _kotakMetrik(
    BuildContext context, {
    required String judul,
    required String nilai,
    required String subJudul,
    required double progres,
    required Color warna,
    required IconData ikon,
    String? badgeText,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(ikon, color: warna, size: 20),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: warna.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: warna,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                judul,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                nilai,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progres,
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(warna),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subJudul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol Aksi Cepat (Quick Actions)
  Widget _bangunAksiCepat(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat Pengurus',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tombolPintas(
                  icon: Icons.payments_outlined,
                  label: 'Catat Iuran',
                  warna: Colors.green.shade800,
                  onTap: _pilihDonaturUntukIuran,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tombolPintas(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Salurkan Bantuan',
                  warna: Colors.teal.shade800,
                  onTap: () async {
                    final hasil = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const PenyaluranFormScreen(),
                      ),
                    );
                    if (hasil == true && mounted) {
                      await _segarkanSemuaData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tombolPintas(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Tambah Anak',
                  warna: Colors.blue.shade800,
                  onTap: () async {
                    final hasil = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AnakFormScreen(),
                      ),
                    );
                    if (hasil == true && mounted) {
                      await _segarkanSemuaData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tombolPintas(
                  icon: Icons.group_add_outlined,
                  label: 'Tambah Donatur',
                  warna: Colors.deepPurple.shade800,
                  onTap: () async {
                    final hasil = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const DonaturFormScreen(),
                      ),
                    );
                    if (hasil == true && mounted) {
                      await _segarkanSemuaData();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tombolPintas({
    required IconData icon,
    required String label,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: warna.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: warna.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: warna),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu Komparasi Dana Terkumpul vs Kebutuhan Program
  Widget _bangunKartuKomparasiDana(
    BuildContext context, {
    required int totalPemasukanKas,
    required int totalKebutuhan,
    required int totalTersalurkan,
  }) {
    final double rasioPengumpulan = totalKebutuhan > 0
        ? (totalPemasukanKas / totalKebutuhan).clamp(0.0, 1.0)
        : 1.0;
    final int selisihTarget = max(0, totalKebutuhan - totalPemasukanKas);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Komparasi Dana Beasiswa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(rasioPengumpulan * 100).toStringAsFixed(0)}% Terkumpul',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar pengumpulan dana
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rasioPengumpulan,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Kas Masuk:',
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
                  Text(
                    formatRupiah(totalPemasukanKas),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target Bersih Setahun:',
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
                  Text(
                    formatRupiah(totalKebutuhan),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          if (selisihTarget > 0) ...[
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange[800]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Perlu ${formatRupiah(selisihTarget)} lagi dari iuran/infak jamaah untuk mencukupi seluruh kebutuhan anak tahun ini.',
                    style: TextStyle(fontSize: 11, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
