// Layar: Daftar Anak Penerima Beasiswa
// Menjaga privasi: hanya menampilkan kode unik internal (A-01) dan nama samaran.
// Dilengkapi skor seleksi dan kebutuhan dana bersih per anak.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/anak.dart';
import '../../providers/anak_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../utils/rupiah_formatter.dart';
import '../../utils/skor_seleksi.dart';
import '../../widgets/empty_state.dart';
import '../penyaluran/penyaluran_form_screen.dart';
import 'anak_detail_screen.dart';
import 'anak_form_screen.dart';

class AnakListScreen extends StatefulWidget {
  const AnakListScreen({super.key});

  @override
  State<AnakListScreen> createState() => _AnakListScreenState();
}

class _AnakListScreenState extends State<AnakListScreen> {
  int _filterJenjangIndex = 0; // 0: Semua, 1: SD, 2: SMP, 3: SMA

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnakProvider>().muatData();
      context.read<PenyaluranProvider>().muatData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final anakProvider = context.watch<AnakProvider>();
    final penyaluranProvider = context.watch<PenyaluranProvider>();
    final pengaturan = context.watch<PengaturanProvider>();
    final semuaAnak = anakProvider.daftarAnak;
    final totalKebutuhan = anakProvider.hitungTotalKebutuhan(pengaturan);

    List<Anak> daftarTampil = semuaAnak;
    if (_filterJenjangIndex == 1) {
      daftarTampil = semuaAnak.where((a) => a.jenjang == Jenjang.sd).toList();
    } else if (_filterJenjangIndex == 2) {
      daftarTampil = semuaAnak.where((a) => a.jenjang == Jenjang.smp).toList();
    } else if (_filterJenjangIndex == 3) {
      daftarTampil = semuaAnak.where((a) => a.jenjang == Jenjang.sma).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anak Penerima Beasiswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volunteer_activism_outlined),
            tooltip: 'Salurkan Bantuan',
            onPressed: () async {
              final hasil = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const PenyaluranFormScreen(),
                ),
              );
              if (hasil == true && context.mounted) {
                await penyaluranProvider.muatData();
                await anakProvider.muatData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan data',
            onPressed: () {
              anakProvider.muatData();
              penyaluranProvider.muatData();
            },
          ),
        ],
      ),
      body: anakProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── Header Ringkasan & Indikator Target ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      // Target Anak Terbantu (Target awal 10 anak)
                      Expanded(
                        child: _boxRingkasan(
                          context,
                          label: 'Anak Terbantu',
                          nilai: '${anakProvider.totalAnakAktif} / 10',
                          sub: 'Target Awal: 10 Anak',
                          warna: Colors.green[800]!,
                          ikon: Icons.school,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Total Kebutuhan Bersih
                      Expanded(
                        child: _boxRingkasan(
                          context,
                          label: 'Kebutuhan Dana / Thn',
                          nilai: formatRupiah(totalKebutuhan),
                          sub: 'Sudah potong PIP',
                          warna: Colors.blue[800]!,
                          ikon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Filter Jenjang ────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _filterJenjangIndex == 0,
                        label: Text('Semua (${semuaAnak.length})'),
                        onSelected: (_) =>
                            setState(() => _filterJenjangIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filterJenjangIndex == 1,
                        label: Text(
                            'SD (${semuaAnak.where((a) => a.jenjang == Jenjang.sd).length})'),
                        onSelected: (_) =>
                            setState(() => _filterJenjangIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filterJenjangIndex == 2,
                        label: Text(
                            'SMP (${semuaAnak.where((a) => a.jenjang == Jenjang.smp).length})'),
                        onSelected: (_) =>
                            setState(() => _filterJenjangIndex = 2),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filterJenjangIndex == 3,
                        label: Text(
                            'SMA (${semuaAnak.where((a) => a.jenjang == Jenjang.sma).length})'),
                        onSelected: (_) =>
                            setState(() => _filterJenjangIndex = 3),
                      ),
                    ],
                  ),
                ),

                // ─── Daftar Anak (Menjaga Privasi) ─────────────────────────
                Expanded(
                  child: daftarTampil.isEmpty
                      ? const EmptyState(
                          ikon: Icons.school_outlined,
                          pesan: 'Belum ada data anak penerima',
                          subPesan:
                              'Tekan tombol tambah (+) untuk mendaftarkan anak penerima beasiswa.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 4),
                          itemCount: daftarTampil.length,
                          itemBuilder: (ctx, index) {
                            final anak = daftarTampil[index];
                            final skor = hitungSkor(
                              kondisiEkonomi: anak.kondisiEkonomi,
                              statusYatim: anak.statusYatim,
                              jumlahSaudara: anak.jumlahSaudara,
                              statusPip: anak.statusPip,
                              bobotEkonomi: pengaturan.bobotEkonomi,
                              bobotYatim: pengaturan.bobotYatim,
                              bobotSaudara: pengaturan.bobotSaudara,
                              bobotKip: pengaturan.bobotKip,
                            );

                            final kebutuhanDana = hitungKebutuhanDana(
                              jenjang: anak.jenjang,
                              statusPip: anak.statusPip,
                              biayaSd: pengaturan.biayaSd,
                              biayaSmp: pengaturan.biayaSmp,
                              biayaSma: pengaturan.biayaSma,
                              pipSd: pengaturan.pipSd,
                              pipSmp: pengaturan.pipSmp,
                              pipSma: pengaturan.pipSma,
                            );

                            final tersalurkan =
                                penyaluranProvider.getTotalPenyaluran(anak.id!);
                            final double rasio = kebutuhanDana > 0
                                ? (tersalurkan / kebutuhanDana).clamp(0.0, 1.0)
                                : 1.0;
                            final double persenNyata = kebutuhanDana > 0
                                ? (tersalurkan / kebutuhanDana) * 100.0
                                : 100.0;

                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AnakDetailScreen(anak: anak),
                                    ),
                                  );
                                  if (context.mounted) {
                                    anakProvider.muatData();
                                    penyaluranProvider.muatData();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Kode Unik Internal
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              anak.kodeAnak,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.green[900],
                                              ),
                                            ),
                                          ),

                                          // Skor Seleksi Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.amber.shade600,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              'Skor: $skor',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Nama Samaran Publik
                                      Text(
                                        anak.namaSamaran,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Status Ringkas & Kebutuhan Dana
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${anak.statusYatim.label} • ${anak.kondisiEkonomi.label}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            formatRupiah(kebutuhanDana),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Lencana PIP
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: anak.statusPip ==
                                                      StatusPip.sudahMenerima
                                                  ? Colors.blue.shade50
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              anak.statusPip.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: anak.statusPip ==
                                                        StatusPip.sudahMenerima
                                                    ? Colors.blue[900]
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            'Tap untuk detail pengurus →',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Progress Bar Pemenuhan Kebutuhan Dana
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: rasio,
                                                minHeight: 6,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  rasio >= 1.0
                                                      ? Colors.green.shade800
                                                      : Colors.green,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${persenNyata.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: rasio >= 1.0
                                                  ? Colors.green[800]
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Anak'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AnakFormScreen()),
          );
        },
      ),
    );
  }

  Widget _boxRingkasan(
    BuildContext context, {
    required String label,
    required String nilai,
    required String sub,
    required Color warna,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 16, color: warna),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
