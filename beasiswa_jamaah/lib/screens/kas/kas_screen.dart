// Layar: Kas Bersama
// Menampilkan saldo kas otomatis, pos dana cadangan 10%, pemasukan,
// pengeluaran, dan riwayat transaksi lengkap.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaksi_kas.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../services/kas_service.dart';
import '../../utils/rupiah_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/konfirmasi_dialog.dart';
import 'transaksi_form_screen.dart';

class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  int _filterTipe = 0; // 0: Semua, 1: Pemasukan, 2: Pengeluaran

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pct = context.read<PengaturanProvider>().pctCadangan;
      context.read<KasProvider>().muatData(persentaseCadangan: pct);
    });
  }

  void _muatUlang() {
    final pct = context.read<PengaturanProvider>().pctCadangan;
    context.read<KasProvider>().muatData(persentaseCadangan: pct);
  }

  @override
  Widget build(BuildContext context) {
    final kasProvider = context.watch<KasProvider>();
    final pengaturan = context.watch<PengaturanProvider>();
    final ringkasan = kasProvider.ringkasan;
    final semuaTransaksi = kasProvider.daftarTransaksi;

    List<TransaksiKas> transaksiTampil;
    if (_filterTipe == 1) {
      transaksiTampil = kasProvider.daftarPemasukan;
    } else if (_filterTipe == 2) {
      transaksiTampil = kasProvider.daftarPengeluaran;
    } else {
      transaksiTampil = semuaTransaksi;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kas Bersama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan data',
            onPressed: _muatUlang,
          ),
        ],
      ),
      body: kasProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _muatUlang(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header Saldo & Pos Cadangan ───────────────────────
                    _buildHeaderSaldo(ringkasan, pengaturan.pctCadangan),

                    // ─── Tombol Aksi Cepat (Pemasukan / Pengeluaran) ────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                minimumSize: const Size(0, 48),
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Pemasukan'),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TransaksiFormScreen(
                                          tipeAwal: TipeTransaksi.masuk,
                                        ),
                                      ),
                                    )
                                    .then((_) => _muatUlang());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange[900],
                                minimumSize: const Size(0, 48),
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Pengeluaran'),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TransaksiFormScreen(
                                          tipeAwal: TipeTransaksi.keluar,
                                        ),
                                      ),
                                    )
                                    .then((_) => _muatUlang());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Judul Riwayat & Filter ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Riwayat Kas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${transaksiTampil.length} transaksi',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter Chip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              selected: _filterTipe == 0,
                              label: Text('Semua (${semuaTransaksi.length})'),
                              onSelected: (_) =>
                                  setState(() => _filterTipe = 0),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _filterTipe == 1,
                              label: Text(
                                'Masuk (${kasProvider.daftarPemasukan.length})',
                                style: TextStyle(
                                  color: _filterTipe == 1
                                      ? Colors.green[900]
                                      : null,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _filterTipe = 1),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _filterTipe == 2,
                              label: Text(
                                'Keluar (${kasProvider.daftarPengeluaran.length})',
                                style: TextStyle(
                                  color: _filterTipe == 2
                                      ? Colors.orange[900]
                                      : null,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _filterTipe = 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ─── Daftar Transaksi ──────────────────────────────────
                    if (transaksiTampil.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EmptyState(
                          ikon: Icons.account_balance_wallet_outlined,
                          pesan: 'Belum ada riwayat transaksi kas',
                          subPesan:
                              'Setiap iuran donatur otomatis tercatat di sini, atau catat transaksi manual lewat tombol di atas.',
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transaksiTampil.length,
                        itemBuilder: (ctx, index) {
                          final item = transaksiTampil[index];
                          final isMasuk = item.tipe == TipeTransaksi.masuk;
                          final tgl = DateTime.tryParse(item.tanggal);
                          final tglStr = tgl != null
                              ? DateFormat('d MMM yyyy', 'id_ID').format(tgl)
                              : item.tanggal;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isMasuk
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  _getIkonKategori(item.kategori),
                                  color: isMasuk
                                      ? Colors.green[800]
                                      : Colors.orange[900],
                                ),
                              ),
                              title: Text(
                                item.keterangan,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      tglStr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.kategori.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    if (item.menggunakanCadangan)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.amber.shade700,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          'Pos Cadangan',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isMasuk ? '+' : '-'}${formatRupiah(item.nominal)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isMasuk
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _tampilkanDetailTransaksi(item),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSaldo(RingkasanKas ringkasan, int pctCadangan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Total Kas Keseluruhan
          const Text(
            'TOTAL KAS BERSAMA',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiah(ringkasan.totalSaldo),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: ringkasan.totalSaldo >= 0
                    ? const Color(0xFF166534)
                    : const Color(0xFFDC2626),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pemisahan: Saldo Siap Pakai vs Pos Dana Cadangan
          Row(
            children: [
              // Saldo Siap Pakai
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 15, color: Color(0xFF166534)),
                          const SizedBox(width: 5),
                          const Expanded(
                            child: Text(
                              'Saldo Siap Pakai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(ringkasan.saldoBisaDipakai),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Untuk beasiswa & belanja',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Pos Dana Cadangan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_rounded,
                              size: 15, color: Colors.amber.shade800),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Cadangan ($pctCadangan%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(ringkasan.danaCadanganTersedia),
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pos wajib darurat & amanah',
                        style: TextStyle(fontSize: 10.5, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Masuk vs Keluar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 15, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Masuk: ',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatRupiah(ringkasan.totalPemasukan),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          size: 15, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text('Keluar: ',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatRupiah(ringkasan.totalPengeluaran),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
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

  IconData _getIkonKategori(KategoriTransaksi kat) {
    switch (kat) {
      case KategoriTransaksi.iuran:
        return Icons.group;
      case KategoriTransaksi.infak:
        return Icons.volunteer_activism;
      case KategoriTransaksi.kasSosial:
        return Icons.account_balance;
      case KategoriTransaksi.donasi:
        return Icons.card_giftcard;
      case KategoriTransaksi.perlengkapan:
        return Icons.checkroom;
      case KategoriTransaksi.uangSaku:
        return Icons.school;
      case KategoriTransaksi.caiCadangan:
        return Icons.lock_open;
      case KategoriTransaksi.lain:
        return Icons.receipt_long;
    }
  }

  void _tampilkanDetailTransaksi(TransaksiKas item) {
    final tgl = DateTime.tryParse(item.tanggal);
    final tglStr = tgl != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(tgl)
        : item.tanggal;
    final isMasuk = item.tipe == TipeTransaksi.masuk;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isMasuk ? 'Detail Pemasukan Kas' : 'Detail Pengeluaran Kas',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _barisInfo('Nominal', formatRupiah(item.nominal)),
            _barisInfo('Kategori', item.kategori.label),
            _barisInfo('Tanggal', tglStr),
            _barisInfo('Keterangan', item.keterangan),
            if (item.menggunakanCadangan) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Transaksi ini menggunakan pos dana cadangan.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item.kategori == KategoriTransaksi.iuran) ...[
              const SizedBox(height: 8),
              const Text(
                'Transaksi ini terhubung otomatis dengan pembayaran iuran donatur.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Transaksi'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await tampilkanKonfirmasi(
                context: context,
                judul: 'Hapus Transaksi Kas?',
                pesan:
                    'Transaksi "${item.keterangan}" sebesar ${formatRupiah(item.nominal)} akan dihapus dari kas.',
                destruktif: true,
                labelKonfirmasi: 'Ya, Hapus',
              );
              if (ok && mounted) {
                try {
                  final pct = context.read<PengaturanProvider>().pctCadangan;
                  final tahun = context.read<PengaturanProvider>().tahunAjaranAktif;
                  await context
                      .read<KasProvider>()
                      .hapusTransaksi(item.id!, persentaseCadangan: pct);
                  if (mounted) {
                    context.read<DonaturProvider>().muatData(tahun: tahun);
                    context.read<PenyaluranProvider>().muatData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi kas telah dihapus')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus transaksi: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _barisInfo(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
