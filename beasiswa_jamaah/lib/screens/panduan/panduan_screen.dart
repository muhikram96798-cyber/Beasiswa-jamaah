// Layar: PanduanScreen (TAHAP 9)
// Panduan operasional dan SOP Program Beasiswa Jamaah Tetap
// Dirancang dengan bahasa yang jelas, mudah dipahami pengurus masjid dan awam teknologi.

import 'package:flutter/material.dart';

class PanduanScreen extends StatelessWidget {
  const PanduanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panduan & SOP Program',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Kartu Selamat Datang
          Card(
            color: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mosque, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Program Beasiswa Jamaah Tetap',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Pedoman teknis bagi pengurus DKM, bendahara, dan koordinator '
                    'pendidikan dalam mengelola iuran jamaah, menyeleksi penerima, '
                    'dan menyalurkan beasiswa secara amanah dan transparan.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── 1. KONSEP DASAR & IURAN ──────────────────────────────────────────
          _buildItemPanduan(
            nomor: '1',
            judul: 'Konsep Program & Iuran Ringan',
            warnaNomor: Colors.blue.shade700,
            konten: const [
              '• Iuran jamaah tetap dipatok sebesar Rp20.000 – Rp30.000 per bulan agar terjangkau dan dapat berjalan istiqomah.',
              '• Dari setiap iuran yang masuk, sistem otomatis memisahkan 10% ke dalam Pos Dana Cadangan Wajib.',
              '• Dana cadangan hanya boleh dicairkan untuk keperluan mendesak anak penerima dengan persetujuan pengurus.',
              '• Saldo yang boleh dibelanjakan adalah Saldo Kas Bersama dikurangi Dana Cadangan 10%.',
            ],
          ),

          // ─── 2. SELEKSI & PRIVASI ANAK ────────────────────────────────────────
          _buildItemPanduan(
            nomor: '2',
            judul: 'Seleksi Kebutuhan & Menjaga Martabat Anak',
            warnaNomor: Colors.purple.shade700,
            konten: const [
              '• Target program: 10 anak sekolah dari keluarga jamaah yang membutuhkan.',
              '• Skor seleksi dihitung otomatis berdasarkan 4 kriteria: Kondisi Ekonomi (40%), Status Yatim/Piatu (30%), Jumlah Saudara Sekolah (15%), dan Kepemilikan PIP/KIP (15%).',
              '• Demi menjaga harga diri dan kehormatan anak serta keluarganya, NAMA ASLI ANAK TIDAK PERNAH DITAMPILKAN di laporan publik atau papan pengumuman.',
              '• Aplikasi menggunakan Kode Unik (misal: A-01) dan Nama Samaran (misal: A.F. - SD Kelas 3).',
              '• Pengurus dapat mengunci nama lengkap dengan PIN Keamanan 6-digit di menu Pengaturan.',
            ],
          ),

          // ─── 3. ATURAN PENYALURAN (SOP ANTI-PENYALAHGUNAAN) ───────────────────
          _buildItemPanduan(
            nomor: '3',
            judul: 'SOP Penyaluran Bantuan (Anti-Penyalahgunaan)',
            warnaNomor: Colors.green.shade800,
            konten: const [
              '• Bantuan Perlengkapan Sekolah (Seragam, Sepatu, Tas, Buku) TIDAK BOLEH diberikan berupa uang tunai kepada anak.',
              '• Pengurus langsung membayarkannya ke vendor/toko seragam/penjahit rekanan dengan bukti nota/kuitansi.',
              '• Bantuan Uang Saku Bulanan HANYA BOLEH diserahkan melalui wali murid / orang tua pendamping.',
              '• Anak yang sudah menerima bantuan PIP dari pemerintah, estimasi kebutuhan dananya otomatis disesuaikan agar bantuan merata.',
            ],
          ),

          // ─── 4. TRANSPARANSI LAPORAN PDF ──────────────────────────────────────
          _buildItemPanduan(
            nomor: '4',
            judul: 'Laporan Pertanggungjawaban PDF Resmi',
            warnaNomor: Colors.teal.shade700,
            konten: const [
              '• Laporan pertanggungjawaban program dapat diterbitkan setiap Semester (Jan–Jun atau Jul–Des) atau Satu Tahun Penuh.',
              '• Dokumen PDF resmi memuat: Rekap Kas, Status 4 Indikator Proposal, Matriks Transparansi Iuran Donatur, Rincian Pembelanjaan Barang ke Toko, Uang Saku ke Wali, serta Lembar Tanda Tangan DKM.',
              '• Laporan dapat dicetak langsung ke printer fisik atau dikirim sebagai file PDF ke grup WhatsApp jamaah.',
            ],
          ),

          // ─── 5. PEMBAYARAN VIA QRIS & TRANSFER ────────────────────────────────
          _buildItemPanduan(
            nomor: '5',
            judul: 'Persiapan Pembayaran QRIS & Transfer Bank',
            warnaNomor: Colors.amber.shade900,
            konten: const [
              '• Di menu Pengaturan, pengurus dapat memasukkan nama bank, nomor rekening donasi, dan petunjuk scan QRIS masjid.',
              '• Saat menagih/mengingatkan donatur yang belum bayar, pengurus dapat menyalin template pesan WhatsApp yang otomatis memuat nomor rekening dan petunjuk QRIS.',
              '• Donatur dapat mentransfer atau scan barcode QRIS masjid, lalu bendahara mencatat status bayar di aplikasi.',
            ],
          ),

          // ─── 6. KEAMANAN & PENCADANGAN DATABASE ───────────────────────────────
          _buildItemPanduan(
            nomor: '6',
            judul: 'Pencadangan Database Offline (.db)',
            warnaNomor: Colors.red.shade800,
            konten: const [
              '• Aplikasi ini bekerja 100% offline di memori internal HP tanpa membutuhkan kuota internet.',
              '• Ukuran database sangat kecil (kurang dari 1 MB untuk pemakaian bertahun-tahun).',
              '• Pengurus sangat dianjurkan menekan tombol "Cadangkan (.db)" di menu Pengaturan minimal 1 bulan sekali untuk menyimpan salinan ke Google Drive atau WhatsApp.',
              '• Jika berganti HP baru, cukup gunakan menu "Pulihkan (.db)" untuk mengembalikan seluruh data dalam sekejap.',
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildItemPanduan({
    required String nomor,
    required String judul,
    required Color warnaNomor,
    required List<String> konten,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: warnaNomor,
                  child: Text(
                    nomor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...konten.map(
              (teks) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  teks,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
