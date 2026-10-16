// Layar: Daftar Donatur & Pencatatan Iuran
// Menampilkan daftar keluarga donatur, status bayar bulan berjalan,
// navigasi ke matriks 12 bulan, dan aksi CRUD donatur.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../providers/donatur_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';
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
      context.read<DonaturProvider>().muatData();
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
            onPressed: () => donaturProvider.muatData(),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ringkasanBox(
                              label: 'Donatur Aktif',
                              nilai: '${donaturProvider.totalDonaturAktif}',
                              warna: Colors.green[800]!,
                              ikon: Icons.group,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ringkasanBox(
                              label: 'Belum Bayar (${DonaturService.singkatanBulan[_bulanBerjalan - 1]})',
                              nilai: '${belumBayarList.length}',
                              warna: belumBayarList.isEmpty
                                  ? Colors.green[700]!
                                  : Colors.orange[800]!,
                              ikon: Icons.pending_actions,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Buka Matriks Iuran 12 Bulan'),
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
                                            ],
                                          ),
                                        ),

                                        // Menu Opsi Donatur
                                        PopupMenuButton<String>(
                                          onSelected: (val) => _handleMenuOpsi(
                                              val, donatur, donaturProvider),
                                          itemBuilder: (ctx) => [
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

                                    // Baris Status Bayar & Tombol Aksi
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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

                                        // Tombol Catat Iuran
                                        if (donatur.statusAktif)
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(120, 36),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                            ),
                                            icon: const Icon(
                                                Icons.add_card_outlined,
                                                size: 18),
                                            label: const Text('Catat Iuran'),
                                            onPressed: () async {
                                              final berhasil =
                                                  await CatatIuranDialog.show(
                                                context,
                                                donatur: donatur,
                                                bulanAwal: _bulanBerjalan,
                                              );
                                              if (berhasil == true &&
                                                  context.mounted) {
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
                                            },
                                          ),
                                      ],
                                    ),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Donatur'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DonaturFormScreen()),
          );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: warna.withValues(alpha: 0.12),
            child: Icon(ikon, color: warna, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  nilai,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: warna,
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
    if (opsi == 'edit') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DonaturFormScreen(donatur: donatur),
        ),
      );
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
    } else if (opsi == 'hapus') {
      final ok = await tampilkanKonfirmasi(
        context: context,
        judul: 'Hapus Donatur?',
        pesan:
            'Semua riwayat iuran dari ${donatur.namaKeluarga} dan catatan kas terkait akan ikut dihapus. Tindakan ini tidak dapat dibatalkan.',
        destruktif: true,
        labelKonfirmasi: 'Hapus Permanen',
      );
      if (ok) {
        await provider.hapusDonatur(donatur.id!);
      }
    }
  }
}
