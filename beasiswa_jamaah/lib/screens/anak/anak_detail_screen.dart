// Layar: Detail Anak Penerima Beasiswa (Mode Pengurus)
// Menampilkan nama lengkap, analisis skor seleksi, dan kalkulasi kebutuhan dana.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/anak.dart';
import '../../providers/anak_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../utils/rupiah_formatter.dart';
import '../../utils/skor_seleksi.dart';
import '../../widgets/konfirmasi_dialog.dart';
import 'anak_form_screen.dart';

class AnakDetailScreen extends StatelessWidget {
  final Anak anak;

  const AnakDetailScreen({super.key, required this.anak});

  @override
  Widget build(BuildContext context) {
    final pengaturan = context.watch<PengaturanProvider>();
    final anakProvider = context.watch<AnakProvider>();

    // Ambil data terbaru anak jika ada update
    final anakTerkini = anakProvider.daftarAnak.firstWhere(
      (a) => a.id == anak.id,
      orElse: () => anak,
    );

    final skor = hitungSkor(
      kondisiEkonomi: anakTerkini.kondisiEkonomi,
      statusYatim: anakTerkini.statusYatim,
      jumlahSaudara: anakTerkini.jumlahSaudara,
      statusPip: anakTerkini.statusPip,
      bobotEkonomi: pengaturan.bobotEkonomi,
      bobotYatim: pengaturan.bobotYatim,
      bobotSaudara: pengaturan.bobotSaudara,
      bobotKip: pengaturan.bobotKip,
    );

    final biayaStandar = getBiayaStandar(
      anakTerkini.jenjang,
      sd: pengaturan.biayaSd,
      smp: pengaturan.biayaSmp,
      sma: pengaturan.biayaSma,
    );

    final estimasiPip = getEstimasiPip(
      anakTerkini.jenjang,
      sd: pengaturan.pipSd,
      smp: pengaturan.pipSmp,
      sma: pengaturan.pipSma,
    );

    final kebutuhanBersih = hitungKebutuhanDana(
      jenjang: anakTerkini.jenjang,
      statusPip: anakTerkini.statusPip,
      biayaSd: pengaturan.biayaSd,
      biayaSmp: pengaturan.biayaSmp,
      biayaSma: pengaturan.biayaSma,
      pipSd: pengaturan.pipSd,
      pipSmp: pengaturan.pipSmp,
      pipSma: pengaturan.pipSma,
    );

    final tglMasuk = DateTime.tryParse(anakTerkini.tanggalMasuk);
    final tglStr = tglMasuk != null
        ? DateFormat('d MMMM yyyy', 'id_ID').format(tglMasuk)
        : anakTerkini.tanggalMasuk;

    return Scaffold(
      appBar: AppBar(
        title: Text('${anakTerkini.kodeAnak} - Detail Pengurus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah Data',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnakFormScreen(anak: anakTerkini),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Data',
            onPressed: () async {
              final ok = await tampilkanKonfirmasi(
                context: context,
                judul: 'Hapus Data Anak?',
                pesan:
                    'Data ${anakTerkini.namaLengkap} (${anakTerkini.kodeAnak}) akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
                destruktif: true,
                labelKonfirmasi: 'Hapus',
              );
              if (ok && context.mounted) {
                await context.read<AnakProvider>().hapusAnak(anakTerkini.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data anak telah dihapus')),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Peringatan Privasi Pengurus ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nama lengkap ini HANYA untuk internal pengurus. Laporan semester dan publik wajib hanya menggunakan nama samaran demi menjaga privasi dan kehormatan anak.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Kartu Identitas Utama ────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            anakTerkini.kodeAnak,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: anakTerkini.aktif
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: anakTerkini.aktif
                                  ? Colors.green.shade300
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            anakTerkini.aktif ? 'Aktif Terbantu' : 'Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: anakTerkini.aktif
                                  ? Colors.green[900]
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      anakTerkini.namaLengkap,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nama Samaran Publik: ${anakTerkini.namaSamaran}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _barisData('Jenjang & Kelas',
                        '${anakTerkini.jenjang.label} Kelas ${anakTerkini.kelas}'),
                    _barisData('Status Keluarga', anakTerkini.statusYatim.label),
                    _barisData(
                        'Keluarga Buruh Tani', anakTerkini.buruhTani ? 'Ya' : 'Tidak'),
                    _barisData(
                        'Kondisi Ekonomi', anakTerkini.kondisiEkonomi.label),
                    _barisData('Jumlah Saudara',
                        '${anakTerkini.jumlahSaudara} orang'),
                    _barisData('Status KIP/PIP', anakTerkini.statusPip.label),
                    _barisData(
                      'Penerima Uang Saku',
                      anakTerkini.namaWali ?? 'Belum ditentukan',
                    ),
                    _barisData('Mulai Terdaftar', tglStr),
                    if (anakTerkini.keterangan != null &&
                        anakTerkini.keterangan!.isNotEmpty)
                      _barisData('Catatan / Alamat', anakTerkini.keterangan!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Kartu Skor Kelayakan Seleksi ──────────────────────────────
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Skor Seleksi Kelayakan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$skor / 100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rincian Komponen Bobot (Dapat diatur di Pengaturan):',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    _barisBobot(
                      'Kondisi Ekonomi',
                      anakTerkini.kondisiEkonomi.label,
                      'Bobot maks: ${pengaturan.bobotEkonomi} poin',
                    ),
                    _barisBobot(
                      'Status Yatim/Piatu',
                      anakTerkini.statusYatim.label,
                      'Bobot maks: ${pengaturan.bobotYatim} poin',
                    ),
                    _barisBobot(
                      'Jumlah Saudara',
                      '${anakTerkini.jumlahSaudara} orang',
                      'Bobot maks: ${pengaturan.bobotSaudara} poin',
                    ),
                    _barisBobot(
                      'Status KIP/PIP',
                      anakTerkini.statusPip.label,
                      'Bobot maks: ${pengaturan.bobotKip} poin',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Kartu Kebutuhan Dana Beasiswa ─────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kebutuhan Dana Program (Per Tahun)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _barisKebutuhan(
                      'Estimasi Biaya Standar (${anakTerkini.jenjang.label})',
                      formatRupiah(biayaStandar),
                      isMinus: false,
                    ),
                    if (anakTerkini.statusPip == StatusPip.sudahMenerima) ...[
                      _barisKebutuhan(
                        'Bantuan Pemerintah (PIP ${anakTerkini.jenjang.label})',
                        '- ${formatRupiah(estimasiPip)}',
                        isMinus: true,
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kebutuhan Dana Bersih Kas:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatRupiah(kebutuhanBersih),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anakTerkini.statusPip == StatusPip.sudahMenerima
                          ? '*Kebutuhan dana jamaah berkurang karena anak terbantu dana PIP'
                          : '*Keluarga anak perlu dibantu mengurus KIP/PIP agar kebutuhan dana dapat turun',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisData(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisBobot(String judul, String status, String bobot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $judul ($status)', style: const TextStyle(fontSize: 13)),
          Text(bobot,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _barisKebutuhan(String label, String nilai, {required bool isMinus}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isMinus ? Colors.red[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
