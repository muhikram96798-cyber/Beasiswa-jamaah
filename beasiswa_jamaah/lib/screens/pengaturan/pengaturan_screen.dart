// Layar: PengaturanScreen (TAHAP 8)
// Mengelola konfigurasi biaya pendidikan, PIP, bobot seleksi, keamanan PIN,
// persiapan rekening/QRIS masjid, serta backup dan restore database SQLite.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/pengaturan.dart';
import '../../providers/anak_provider.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/pin_dialog.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _memuat = false;

  // Controllers untuk biaya & PIP
  final _biayaSdCtrl = TextEditingController();
  final _biayaSmpCtrl = TextEditingController();
  final _biayaSmaCtrl = TextEditingController();
  final _pipSdCtrl = TextEditingController();
  final _pipSmpCtrl = TextEditingController();
  final _pipSmaCtrl = TextEditingController();

  // Controllers untuk iuran, tahun ajaran & cadangan
  final _tahunAktifCtrl = TextEditingController();
  final _iuranMinCtrl = TextEditingController();
  final _iuranMaxCtrl = TextEditingController();
  final _cadanganCtrl = TextEditingController();

  // Controllers untuk bobot
  final _bobotEkonomiCtrl = TextEditingController();
  final _bobotYatimCtrl = TextEditingController();
  final _bobotSaudaraCtrl = TextEditingController();
  final _bobotKipCtrl = TextEditingController();

  // Controllers untuk Rekening & QRIS
  final _namaMasjidCtrl = TextEditingController();
  final _namaBankCtrl = TextEditingController();
  final _nomorRekeningCtrl = TextEditingController();
  final _atasNamaCtrl = TextEditingController();
  final _catatanQrisCtrl = TextEditingController();

  bool _sudahInisialisasi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sudahInisialisasi) {
      _isiNilaiForm();
      _sudahInisialisasi = true;
    }
  }

  void _isiNilaiForm() {
    final p = context.read<PengaturanProvider>();
    _biayaSdCtrl.text = '${p.biayaSd}';
    _biayaSmpCtrl.text = '${p.biayaSmp}';
    _biayaSmaCtrl.text = '${p.biayaSma}';
    _pipSdCtrl.text = '${p.pipSd}';
    _pipSmpCtrl.text = '${p.pipSmp}';
    _pipSmaCtrl.text = '${p.pipSma}';

    _tahunAktifCtrl.text = '${p.tahunAjaranAktif}';
    _iuranMinCtrl.text = '${p.iuranMin}';
    _iuranMaxCtrl.text = '${p.iuranMax}';
    _cadanganCtrl.text = '${p.pctCadangan}';

    _bobotEkonomiCtrl.text = '${p.bobotEkonomi}';
    _bobotYatimCtrl.text = '${p.bobotYatim}';
    _bobotSaudaraCtrl.text = '${p.bobotSaudara}';
    _bobotKipCtrl.text = '${p.bobotKip}';

    _namaMasjidCtrl.text = p.namaMasjid;
    _namaBankCtrl.text = p.namaBank;
    _nomorRekeningCtrl.text = p.nomorRekening;
    _atasNamaCtrl.text = p.atasNamaRekening;
    _catatanQrisCtrl.text = p.catatanQris;
  }

  @override
  void dispose() {
    _biayaSdCtrl.dispose();
    _biayaSmpCtrl.dispose();
    _biayaSmaCtrl.dispose();
    _pipSdCtrl.dispose();
    _pipSmpCtrl.dispose();
    _pipSmaCtrl.dispose();
    _tahunAktifCtrl.dispose();
    _iuranMinCtrl.dispose();
    _iuranMaxCtrl.dispose();
    _cadanganCtrl.dispose();
    _bobotEkonomiCtrl.dispose();
    _bobotYatimCtrl.dispose();
    _bobotSaudaraCtrl.dispose();
    _bobotKipCtrl.dispose();
    _namaMasjidCtrl.dispose();
    _namaBankCtrl.dispose();
    _nomorRekeningCtrl.dispose();
    _atasNamaCtrl.dispose();
    _catatanQrisCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanSemuaPengaturan() async {
    // 1. Validasi bobot total harus 100%
    final bEko = int.tryParse(_bobotEkonomiCtrl.text.trim()) ?? 0;
    final bYat = int.tryParse(_bobotYatimCtrl.text.trim()) ?? 0;
    final bSau = int.tryParse(_bobotSaudaraCtrl.text.trim()) ?? 0;
    final bKip = int.tryParse(_bobotKipCtrl.text.trim()) ?? 0;
    final totalBobot = bEko + bYat + bSau + bKip;

    if (totalBobot != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total bobot kriteria harus tepat 100% (saat ini: $totalBobot%).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validasi tahun ajaran
    final thn = int.tryParse(_tahunAktifCtrl.text.trim()) ?? 0;
    if (thn < 2000 || thn > 2100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tahun ajaran harus berupa 4 digit angka yang valid (contoh: 2026).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Validasi rentang iuran
    final iMin = int.tryParse(_iuranMinCtrl.text.trim()) ?? 0;
    final iMax = int.tryParse(_iuranMaxCtrl.text.trim()) ?? 0;
    if (iMin <= 0 || iMax <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nominal iuran minimal dan maksimal harus lebih dari Rp0.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (iMin > iMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nominal iuran minimal tidak boleh lebih besar dari iuran maksimal.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 4. Validasi persentase pos cadangan
    final pctCad = int.tryParse(_cadanganCtrl.text.trim()) ?? -1;
    if (pctCad < 0 || pctCad > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Persentase pos cadangan harus antara 0% hingga 100%.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5. Validasi biaya pendidikan & PIP
    final bSd = int.tryParse(_biayaSdCtrl.text.trim()) ?? 0;
    final bSmp = int.tryParse(_biayaSmpCtrl.text.trim()) ?? 0;
    final bSma = int.tryParse(_biayaSmaCtrl.text.trim()) ?? 0;
    if (bSd <= 0 || bSmp <= 0 || bSma <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Estimasi biaya pendidikan per jenjang harus lebih dari Rp0.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pSd = int.tryParse(_pipSdCtrl.text.trim()) ?? 0;
    final pSmp = int.tryParse(_pipSmpCtrl.text.trim()) ?? 0;
    final pSma = int.tryParse(_pipSmaCtrl.text.trim()) ?? 0;

    final p = context.read<PengaturanProvider>();
    setState(() => _memuat = true);

    try {
      await p.setTahunAjaranAktif(thn);
      await p.set(PengaturanKey.biayaSd, '$bSd');
      await p.set(PengaturanKey.biayaSmp, '$bSmp');
      await p.set(PengaturanKey.biayaSma, '$bSma');
      await p.set(PengaturanKey.pipSd, '$pSd');
      await p.set(PengaturanKey.pipSmp, '$pSmp');
      await p.set(PengaturanKey.pipSma, '$pSma');

      await p.set(PengaturanKey.iuranMin, '$iMin');
      await p.set(PengaturanKey.iuranMax, '$iMax');
      await p.set(PengaturanKey.pctCadangan, '$pctCad');

      await p.set(PengaturanKey.bobotEkonomi, '$bEko');
      await p.set(PengaturanKey.bobotYatim, '$bYat');
      await p.set(PengaturanKey.bobotSaudara, '$bSau');
      await p.set(PengaturanKey.bobotKip, '$bKip');

      await p.set(PengaturanKey.namaMasjid, _namaMasjidCtrl.text.trim());
      await p.set(PengaturanKey.namaBank, _namaBankCtrl.text.trim());
      await p.set(PengaturanKey.nomorRekening, _nomorRekeningCtrl.text.trim());
      await p.set(PengaturanKey.atasNamaRekening, _atasNamaCtrl.text.trim());
      await p.set(PengaturanKey.catatanQris, _catatanQrisCtrl.text.trim());

      // Segarkan semua provider dengan parameter konfigurasi baru
      if (mounted) {
        final kasProv = context.read<KasProvider>();
        final anakProv = context.read<AnakProvider>();
        final donaturProv = context.read<DonaturProvider>();
        final penyaluranProv = context.read<PenyaluranProvider>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        await kasProv.muatData(persentaseCadangan: p.persentaseCadangan);
        await anakProv.muatData();
        await donaturProv.muatData(tahun: p.tahunAjaranAktif);
        await penyaluranProv.muatData();

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Semua pengaturan berhasil disimpan.'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _bukaDialogPin() async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (_) => const AturPinDialog(),
    );
    if (hasil == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN keamanan berhasil diperbarui.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _hapusPin() async {
    final pengaturan = context.read<PengaturanProvider>();
    final lolos = await PinAuthDialog.verifikasi(
      context,
      judul: 'Konfirmasi Hapus PIN',
      pesan: 'Masukkan PIN pengurus saat ini untuk menonaktifkan proteksi PIN.',
    );

    if (lolos) {
      await pengaturan.hapusPin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN keamanan telah dinonaktifkan.'),
          ),
        );
      }
    }
  }

  Future<void> _eksporCadangan() async {
    final lolosPin = await PinAuthDialog.verifikasi(
      context,
      judul: 'Verifikasi PIN Pengurus',
      pesan: 'Masukkan PIN pengurus untuk mengekspor database cadangan.',
    );
    if (!lolosPin || !mounted) return;

    setState(() => _memuat = true);
    try {
      await BackupService.eksporCadangan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadangan database berhasil diekspor.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _pulihkanCadangan() async {
    final lolosPin = await PinAuthDialog.verifikasi(
      context,
      judul: 'Verifikasi PIN Pengurus',
      pesan:
          'Masukkan PIN pengurus untuk memulihkan database dari file cadangan.',
    );
    if (!lolosPin || !mounted) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pulihkan Database?'),
          ],
        ),
        content: const Text(
          'Seluruh data saat ini di HP akan ditimpa dengan data dari file cadangan yang Anda pilih.\n\n'
          'Pastikan Anda memilih file database yang benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('Pilih File Cadangan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _memuat = true);
    try {
      final sukses = await BackupService.pulihkanCadangan();
      if (sukses && mounted) {
        final p = context.read<PengaturanProvider>();
        final donaturProv = context.read<DonaturProvider>();
        final kasProv = context.read<KasProvider>();
        final anakProv = context.read<AnakProvider>();
        final penyaluranProv = context.read<PenyaluranProvider>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        await p.muat();
        _isiNilaiForm();
        await donaturProv.muatData(tahun: p.tahunAjaranAktif);
        await kasProv.muatData(persentaseCadangan: p.persentaseCadangan);
        await anakProv.muatData();
        await penyaluranProv.muatData();

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Database berhasil dipulihkan dari cadangan.'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PengaturanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan & Keamanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 1. KEAMANAN PIN ──────────────────────────────────────────
                  _buildSectionHeader(
                    icon: Icons.security,
                    title: 'Keamanan Data & PIN Pengurus',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                p.sudahAdaPin
                                    ? Icons.lock
                                    : Icons.lock_open_outlined,
                                color: p.sudahAdaPin
                                    ? const Color(0xFF2E7D32)
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.sudahAdaPin
                                      ? 'PIN Aktif (Identitas anak terlindungi)'
                                      : 'PIN Belum Diatur (Bebas Akses)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: p.sudahAdaPin
                                        ? const Color(0xFF1B5E20)
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PIN 6-digit diperlukan saat pengurus membuka rincian '
                            'nama asli anak untuk menjaga martabat keluarga penerima.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _bukaDialogPin,
                                icon: const Icon(Icons.pin),
                                label: Text(
                                  p.sudahAdaPin ? 'Ubah PIN' : 'Buat PIN 6 Digit',
                                ),
                              ),
                              if (p.sudahAdaPin)
                                OutlinedButton(
                                  onPressed: _hapusPin,
                                  child: const Text('Nonaktifkan PIN'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 2. REKENING & QRIS MASJID ───────────────────────────────
                  _buildSectionHeader(
                    icon: Icons.qr_code_2,
                    title: 'Rekening Donasi & Instruksi QRIS Masjid',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _namaMasjidCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Masjid / Komunitas',
                              prefixIcon: Icon(Icons.mosque),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _namaBankCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Bank',
                                    prefixIcon: Icon(Icons.account_balance),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _nomorRekeningCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Nomor Rekening',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _atasNamaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Atas Nama Rekening',
                              prefixIcon: Icon(Icons.person_pin),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _catatanQrisCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Instruksi Transfer / Scan QRIS',
                              helperText:
                                  'Tampil di pesan pengingat iuran WhatsApp donatur',
                              prefixIcon: Icon(Icons.info_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 3. ESTIMASI BIAYA PENDIDIKAN PER JENJANG ─────────────────
                  _buildSectionHeader(
                    icon: Icons.school_outlined,
                    title: 'Estimasi Biaya Pendidikan per Tahun (Rupiah)',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFieldRupiah(
                            controller: _biayaSdCtrl,
                            label: 'SD per Tahun (Proposal: Rp2.310.000)',
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRupiah(
                            controller: _biayaSmpCtrl,
                            label: 'SMP per Tahun (Proposal: Rp3.575.000)',
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRupiah(
                            controller: _biayaSmaCtrl,
                            label: 'SMA per Tahun (Proposal: Rp4.785.000)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 4. PENGURANG BANTUAN PIP PEMERINTAH ─────────────────────
                  _buildSectionHeader(
                    icon: Icons.account_balance_outlined,
                    title: 'Bantuan PIP Pemerintah (Pengurang Dana Bersih)',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFieldRupiah(
                            controller: _pipSdCtrl,
                            label: 'PIP SD (Nasional: Rp450.000)',
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRupiah(
                            controller: _pipSmpCtrl,
                            label: 'PIP SMP (Nasional: Rp750.000)',
                          ),
                          const SizedBox(height: 12),
                          _buildFieldRupiah(
                            controller: _pipSmaCtrl,
                            label: 'PIP SMA (Nasional: Rp1.800.000)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 5. PERIODE TAHUN AJARAN, IURAN & CADANGAN KAS ───────────
                  _buildSectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Periode Program, Rentang Iuran & Cadangan Kas',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tahunAktifCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Tahun Ajaran Aktif Program',
                              helperText:
                                  'Tahun default untuk matriks iuran, donatur, dan laporan',
                              counterText: '',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFieldRupiah(
                                  controller: _iuranMinCtrl,
                                  label: 'Minimal (Rp20.000)',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFieldRupiah(
                                  controller: _iuranMaxCtrl,
                                  label: 'Maksimal (Rp30.000)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cadanganCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Persentase Pos Cadangan (%)',
                              helperText:
                                  'Sesuai proposal: 10% dari seluruh pemasukan kas bersama',
                              prefixIcon: Icon(Icons.pie_chart_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 6. BOBOT PRIORITAS SELEKSI (TOTAL = 100%) ────────────────
                  _buildSectionHeader(
                    icon: Icons.tune,
                    title: 'Bobot Penilaian Seleksi Anak (Total = 100%)',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bobotEkonomiCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Ekonomi (%)',
                                    helperText: 'Default: 40',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _bobotYatimCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Yatim/Piatu (%)',
                                    helperText: 'Default: 30',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bobotSaudaraCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Saudara Sek. (%)',
                                    helperText: 'Default: 15',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _bobotKipCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'KIP/PIP (%)',
                                    helperText: 'Default: 15',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── TOMBOL SIMPAN PENGATURAN ────────────────────────────────
                  FilledButton.icon(
                    onPressed: _simpanSemuaPengaturan,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Simpan Perubahan Pengaturan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── 7. CADANGKAN & PULIHKAN DATABASE SQLITE ────────────────
                  _buildSectionHeader(
                    icon: Icons.storage,
                    title: 'Pencadangan & Pemulihan Database SQLite',
                  ),
                  Card(
                    color: const Color(0xFFF9FBE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFC5E1A5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  color: Color(0xFF2E7D32)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Perlindungan & Keamanan Data Lokal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Database disimpan secara offline di HP Anda. '
                            'Cadangkan file .db secara berkala ke WhatsApp atau Google Drive '
                            'agar data tetap aman jika HP berganti.',
                            style: TextStyle(fontSize: 13, height: 1.3),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _eksporCadangan,
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Cadangkan (.db)'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pulihkanCadangan,
                                  icon: const Icon(Icons.restore, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Pulihkan (.db)'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Beasiswa Jamaah Tetap',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Versi 1.0.0 • SQLite Offline-First',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Aplikasi Pengelolaan Beasiswa Pendidikan Anak Yatim & Dhuafa\nBerbasis Jamaah Tempat Ibadah',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Colors.black45, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRupiah({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        prefixIcon: const Icon(Icons.attach_money),
      ),
    );
  }
}
