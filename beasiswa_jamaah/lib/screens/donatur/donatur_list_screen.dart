// Layar: Daftar Donatur & Pencatatan Iuran
// Menampilkan daftar keluarga donatur, status bayar bulan berjalan,
// navigasi ke matriks 12 bulan, dan aksi CRUD donatur.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';
import '../../utils/whatsapp_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/konfirmasi_dialog.dart';
import 'catat_iuran_dialog.dart';
import 'donatur_form_screen.dart';
import 'iuran_matriks_screen.dart';

class DonaturListScreen extends StatefulWidget {
  const DonaturListScreen({super.key});

  @override
  State<DonaturListScreen> createState() => _DonaturListScreenState();
}

class _DonaturListScreenState extends State<DonaturListScreen> {
  int _kategoriFilter = 0; // 0: Semua, 1: Belum Bayar Bulan Ini, 2: Berhenti
  final int _bulanBerjalan = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tahun = context.read<PengaturanProvider>().tahunAjaranAktif;
      context.read<DonaturProvider>().muatData(tahun: tahun);
    });
  }

  @override
  Widget build(BuildContext context) {
    final donaturProvider = context.watch<DonaturProvider>();
    final daftarSemua = donaturProvider.daftarDonatur;
    final belumBayarList = donaturProvider.donaturBelumBayarBulanIni;
    final berhentiList = donaturProvider.donaturBerhenti;

    List<Donatur> daftarTampil;
    if (_kategoriFilter == 1) {
      daftarTampil = belumBayarList;
    } else if (_kategoriFilter == 2) {
      daftarTampil = berhentiList;
    } else {
      daftarTampil = daftarSemua;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donatur Jamaah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Matriks Jan-Des',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IuranMatriksScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan data',
            onPressed: () {
              final tahun = context.read<PengaturanProvider>().tahunAjaranAktif;
              donaturProvider.muatData(tahun: tahun);
            },
          ),
        ],
      ),
      body: donaturProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── Kartu Ringkasan Atas ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ringkasanBox(
                              label: 'Donatur Aktif',
                              nilai: '${donaturProvider.totalDonaturAktif}',
                              warna: const Color(0xFF166534),
                              ikon: Icons.group_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ringkasanBox(
                              label: 'Belum Bayar (${DonaturService.singkatanBulan[_bulanBerjalan - 1]})',
                              nilai: '${belumBayarList.length}',
                              warna: belumBayarList.isEmpty
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFD97706),
                              ikon: Icons.pending_actions_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF166534), width: 1.2),
                        ),
                        icon: const Icon(Icons.table_chart_rounded, size: 18),
                        label: const Text(
                          'Buka Matriks Iuran 12 Bulan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const IuranMatriksScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ─── Filter Segmen ────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _kategoriFilter == 0,
                          label: Text('Semua (${daftarSemua.length})'),
                          onSelected: (_) =>
                              setState(() => _kategoriFilter = 0),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _kategoriFilter == 1,
                          label: Text(
                            'Belum Bayar Bulan Ini (${belumBayarList.length})',
                            style: TextStyle(
                              color: belumBayarList.isNotEmpty
                                  ? Colors.orange[900]
                                  : null,
                              fontWeight: belumBayarList.isNotEmpty
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _kategoriFilter = 1),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _kategoriFilter == 2,
                          label: Text('Berhenti (${berhentiList.length})'),
                          onSelected: (_) =>
                              setState(() => _kategoriFilter = 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Daftar Donatur ───────────────────────────────────────
                Expanded(
                  child: daftarTampil.isEmpty
                      ? EmptyState(
                          ikon: Icons.people_outline,
                          pesan: _kategoriFilter == 1
                              ? 'Alhamdulillah, semua donatur aktif sudah membayar bulan ini!'
                              : _kategoriFilter == 2
                                  ? 'Tidak ada donatur yang berstatus berhenti.'
                                  : 'Belum ada donatur terdaftar.',
                          subPesan: _kategoriFilter == 0
                              ? 'Klik tombol tambah (+) di bawah untuk mendaftarkan donatur pertama.'
                              : null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 4),
                          itemCount: daftarTampil.length,
                          itemBuilder: (context, index) {
                            final donatur = daftarTampil[index];
                            final sudahBayarBulanIni = donaturProvider
                                .sudahBayar(donatur.id!, _bulanBerjalan);

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Ikon
                                        CircleAvatar(
                                          backgroundColor: donatur.statusAktif
                                              ? Colors.green.shade100
                                              : Colors.grey.shade200,
                                          child: Icon(
                                            Icons.family_restroom,
                                            color: donatur.statusAktif
                                                ? Colors.green[800]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Info Utama
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                donatur.namaKeluarga,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Komitmen: ${formatRupiah(donatur.nominalIuran)} / bulan',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.green[900],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (donatur.nomorTelepon != null &&
                                                  donatur.nomorTelepon!.trim().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.phone_outlined,
                                                        size: 14,
                                                        color: Colors.grey[700]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      donatur.nomorTelepon!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[800],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Menu Opsi Donatur
                                        PopupMenuButton<String>(
                                          onSelected: (val) => _handleMenuOpsi(
                                              val, donatur, donaturProvider),
                                          itemBuilder: (ctx) => [
                                            if (donatur.statusAktif && sudahBayarBulanIni)
                                              PopupMenuItem(
                                                value: 'batal_iuran',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.undo,
                                                        size: 20,
                                                        color: Colors.orange.shade800),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Batalkan Iuran ${DonaturService.singkatanBulan[_bulanBerjalan - 1]}',
                                                      style: TextStyle(
                                                        color: Colors.orange.shade900,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (donatur.statusAktif && !sudahBayarBulanIni)
                                              const PopupMenuItem(
                                                value: 'wa_reminder',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.chat_outlined,
                                                        size: 20,
                                                        color: Color(0xFF2E7D32)),
                                                    SizedBox(width: 8),
                                                    Text('Pengingat WA'),
                                                  ],
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Ubah Data'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'toggle_status',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    donatur.statusAktif
                                                        ? Icons.pause_circle_outline
                                                        : Icons.play_circle_outline,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(donatur.statusAktif
                                                      ? 'Tandai Berhenti'
                                                      : 'Aktifkan Kembali'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'hapus',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline,
                                                      size: 20,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Baris Status Bayar Bulan Ini
                                    Row(
                                      children: [
                                        // Badge Status Bulan Ini
                                        if (!donatur.statusAktif)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Status: Berhenti',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          )
                                        else if (sudahBayarBulanIni)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              border: Border.all(
                                                  color: Colors.green.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle,
                                                    size: 16,
                                                    color: Colors.green[800]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Lunas ${DonaturService.getNamaBulan(_bulanBerjalan)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.green[900],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              border: Border.all(
                                                  color: Colors.orange.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.warning_amber_rounded,
                                                    size: 16,
                                                    color:
                                                        Colors.orange.shade900),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Belum Bayar ${DonaturService.singkatanBulan[_bulanBerjalan - 1]}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        Colors.orange.shade900,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Tombol Aksi (Pengingat WA & Catat Iuran)
                                    if (donatur.statusAktif) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (!sudahBayarBulanIni) ...[
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFF1B5E20),
                                                side: const BorderSide(
                                                    color: Color(0xFF81C784)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              icon: const Icon(
                                                  Icons.chat_outlined,
                                                  size: 16,
                                                  color: Color(0xFF2E7D32)),
                                              label: const Text(
                                                'Pengingat WA',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              onPressed: () {
                                                WhatsAppHelper.kirimPengingatWa(
                                                  context: context,
                                                  donatur: donatur,
                                                  bulan: _bulanBerjalan,
                                                  pengaturan: context.read<
                                                      PengaturanProvider>(),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton.tonalIcon(
                                              style: FilledButton.styleFrom(
                                                minimumSize: const Size(110, 36),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              icon: const Icon(
                                                  Icons.add_card_outlined,
                                                  size: 18),
                                              label: const Text('Catat Iuran'),
                                              onPressed: () async {
                                                final tahun = context
                                                    .read<PengaturanProvider>()
                                                    .tahunAjaranAktif;
                                                final donaturProvider =
                                                    context.read<DonaturProvider>();
                                                final kasProvider =
                                                    context.read<KasProvider>();
                                                final berhasil =
                                                    await CatatIuranDialog.show(
                                                  context,
                                                  donatur: donatur,
                                                  bulanAwal: _bulanBerjalan,
                                                  tahunAwal: tahun,
                                                );
                                                if (berhasil == true) {
                                                  await donaturProvider
                                                      .muatData(tahun: tahun);
                                                  await kasProvider.muatData();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Iuran ${donatur.namaKeluarga} berhasil dicatat dan masuk kas.'),
                                                        backgroundColor:
                                                            Colors.green[800],
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ] else ...[
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.orange.shade900,
                                                side: BorderSide(
                                                    color: Colors.orange.shade300),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              icon: const Icon(Icons.undo,
                                                  size: 16),
                                              label: const Text(
                                                'Batal Iuran',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              onPressed: () => _handleMenuOpsi(
                                                  'batal_iuran',
                                                  donatur,
                                                  donaturProvider),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton.tonalIcon(
                                              style: FilledButton.styleFrom(
                                                minimumSize: const Size(110, 36),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              icon: const Icon(
                                                  Icons.calendar_month,
                                                  size: 18),
                                              label: const Text('Bulan Lain'),
                                              onPressed: () async {
                                                final tahun = context
                                                    .read<PengaturanProvider>()
                                                    .tahunAjaranAktif;
                                                final donaturProvider =
                                                    context.read<DonaturProvider>();
                                                final kasProvider =
                                                    context.read<KasProvider>();
                                                final berhasil =
                                                    await CatatIuranDialog.show(
                                                  context,
                                                  donatur: donatur,
                                                  tahunAwal: tahun,
                                                );
                                                if (berhasil == true) {
                                                  await donaturProvider
                                                      .muatData(tahun: tahun);
                                                  await kasProvider.muatData();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Iuran ${donatur.namaKeluarga} berhasil dicatat dan masuk kas.'),
                                                        backgroundColor:
                                                            Colors.green[800],
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_tambah_donatur',
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Donatur'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DonaturFormScreen()),
          );
          if (context.mounted) {
            final tahun = context.read<PengaturanProvider>().tahunAjaranAktif;
            context.read<DonaturProvider>().muatData(tahun: tahun);
          }
        },
      ),
    );
  }

  Widget _ringkasanBox({
    required String label,
    required String nilai,
    required Color warna,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: warna, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    nilai,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: warna,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuOpsi(
    String opsi,
    Donatur donatur,
    DonaturProvider provider,
  ) async {
    if (opsi == 'wa_reminder') {
      WhatsAppHelper.kirimPengingatWa(
        context: context,
        donatur: donatur,
        bulan: _bulanBerjalan,
        pengaturan: context.read<PengaturanProvider>(),
      );
    } else if (opsi == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DonaturFormScreen(donatur: donatur),
        ),
      );
      if (mounted) {
        final tahun = context.read<PengaturanProvider>().tahunAjaranAktif;
        provider.muatData(tahun: tahun);
      }
    } else if (opsi == 'toggle_status') {
      final aksi = donatur.statusAktif ? 'menonaktifkan' : 'mengaktifkan';
      final ok = await tampilkanKonfirmasi(
        context: context,
        judul: 'Ubah Status Donatur?',
        pesan: 'Apakah Anda yakin ingin $aksi donatur ${donatur.namaKeluarga}?',
      );
      if (ok) {
        await provider.toggleStatusDonatur(donatur);
      }
    } else if (opsi == 'batal_iuran') {
      final iuran = provider.getIuran(donatur.id!, _bulanBerjalan);
      if (iuran != null) {
        final namaBulan = DonaturService.getNamaBulan(_bulanBerjalan);
        final ok = await tampilkanKonfirmasi(
          context: context,
          judul: 'Batalkan Iuran?',
          pesan:
              'Pembayaran iuran bulan $namaBulan dari ${donatur.namaKeluarga} (${formatRupiah(iuran.nominal)}) akan dibatalkan dan catatan kas terkait akan ditarik kembali secara aman.',
          destruktif: true,
          labelKonfirmasi: 'Ya, Batalkan',
        );
        if (ok && mounted) {
          final kasProvider = context.read<KasProvider>();
          final pct = context.read<PengaturanProvider>().pctCadangan;
          try {
            await provider.batalkanIuran(iuran.id!);
            await kasProvider.muatData(persentaseCadangan: pct);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Iuran bulan $namaBulan untuk ${donatur.namaKeluarga} berhasil dibatalkan.',
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membatalkan iuran: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
      }
    } else if (opsi == 'hapus') {
      final ok = await tampilkanKonfirmasi(
        context: context,
        judul: 'Hapus Donatur?',
        pesan:
            'Apakah Anda yakin ingin menghapus data donatur "${donatur.namaKeluarga}"?\n\n'
            'Catatan: Seluruh riwayat uang yang sudah disetorkan ke Kas Masjid tetap aman dan TIDAK AKAN terhapus dari pembukuan.',
        destruktif: true,
        labelKonfirmasi: 'Hapus Donatur',
      );
      if (ok && mounted) {
        final kasProvider = context.read<KasProvider>();
        final pct = context.read<PengaturanProvider>().pctCadangan;
        try {
          await provider.hapusDonatur(donatur.id!);
          await kasProvider.muatData(persentaseCadangan: pct);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Donatur ${donatur.namaKeluarga} berhasil dihapus. Saldo kas tetap aman.'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menghapus donatur: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }
}
