// Layar: Form Transaksi Kas
// Mencatat pemasukan (infak, donasi lain, kas sosial) atau pengeluaran
// dengan validasi saldo dan proteksi penggunaan dana cadangan 10%.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaksi_kas.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../utils/rupiah_formatter.dart';
import '../../widgets/konfirmasi_dialog.dart';

class TransaksiFormScreen extends StatefulWidget {
  final TipeTransaksi tipeAwal;

  const TransaksiFormScreen({
    super.key,
    this.tipeAwal = TipeTransaksi.masuk,
  });

  @override
  State<TransaksiFormScreen> createState() => _TransaksiFormScreenState();
}

class _TransaksiFormScreenState extends State<TransaksiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TipeTransaksi _tipe;
  late KategoriTransaksi _kategori;
  late TextEditingController _nominalController;
  late TextEditingController _keteranganController;
  late DateTime _tanggal;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _tipe = widget.tipeAwal;
    _kategori = _tipe == TipeTransaksi.masuk
        ? KategoriTransaksi.infak
        : KategoriTransaksi.lain;
    _nominalController = TextEditingController();
    _keteranganController = TextEditingController();
    _tanggal = DateTime.now();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = parseRupiah(_nominalController.text) ?? 0;
    final tanggalStr = DateFormat('yyyy-MM-dd').format(_tanggal);
    String keterangan = _keteranganController.text.trim();

    final kasProvider = context.read<KasProvider>();
    final pengaturan = context.read<PengaturanProvider>();
    final ringkasan = kasProvider.ringkasan;
    bool menggunakanCadangan = false;

    // ─── Validasi Pengeluaran Terhadap Saldo Kas ────────────────────────────
    if (_tipe == TipeTransaksi.keluar) {
      // 1. Larangan total kas negatif
      if (nominal > ringkasan.totalSaldo) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 8),
                Text('Saldo Kas Tidak Cukup'),
              ],
            ),
            content: Text(
              'Total kas saat ini adalah ${formatRupiah(ringkasan.totalSaldo)}. Pengeluaran sebesar ${formatRupiah(nominal)} ditolak karena kas tidak boleh minus.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }

      // 2. Jika pengeluaran melebihi saldo yang bisa dipakai (memakan dana cadangan 10%)
      if (nominal > ringkasan.saldoBisaDipakai) {
        if (!mounted) return;
        final alasan = await tampilkanKonfirmasiDenganAlasan(
          context: context,
          judul: 'Gunakan Dana Cadangan?',
          pesan:
              'Saldo siap pakai (${formatRupiah(ringkasan.saldoBisaDipakai)}) tidak mencukupi untuk pengeluaran ${formatRupiah(nominal)}.\n\nPengeluaran ini akan mencairkan sebagian Pos Dana Cadangan 10% (Tersedia: ${formatRupiah(ringkasan.danaCadanganTersedia)}).\n\nSesuai aturan program, mohon masukkan alasan penggunaan dana cadangan:',
        );

        if (alasan == null) {
          // Batal oleh pengguna
          return;
        }

        menggunakanCadangan = true;
        keterangan = '$keterangan [Cadangan: $alasan]';
      }
    }

    setState(() => _sedangMenyimpan = true);

    try {
      final transaksiBaru = TransaksiKas(
        tanggal: tanggalStr,
        tipe: _tipe,
        kategori: _kategori,
        keterangan: keterangan,
        nominal: nominal,
        menggunakanCadangan: menggunakanCadangan,
      );

      await kasProvider.tambahTransaksi(
        transaksiBaru,
        persentaseCadangan: pengaturan.pctCadangan,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tipe == TipeTransaksi.masuk
                  ? 'Pemasukan kas berhasil dicatat'
                  : 'Pengeluaran kas berhasil dicatat',
            ),
            backgroundColor: _tipe == TipeTransaksi.masuk
                ? Colors.green[800]
                : Colors.orange[900],
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kasProvider = context.watch<KasProvider>();
    final ringkasan = kasProvider.ringkasan;

    final daftarKategoriMasuk = [
      KategoriTransaksi.infak,
      KategoriTransaksi.donasi,
      KategoriTransaksi.kasSosial,
      KategoriTransaksi.lain,
    ];

    final daftarKategoriKeluar = [
      KategoriTransaksi.perlengkapan,
      KategoriTransaksi.uangSaku,
      KategoriTransaksi.caiCadangan,
      KategoriTransaksi.lain,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tipe == TipeTransaksi.masuk
              ? 'Catat Pemasukan Kas'
              : 'Catat Pengeluaran Kas',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Pilihan Tipe Transaksi (Masuk / Keluar) ─────────────────
              SegmentedButton<TipeTransaksi>(
                segments: const [
                  ButtonSegment(
                    value: TipeTransaksi.masuk,
                    icon: Icon(Icons.arrow_downward, color: Colors.green),
                    label: Text('Pemasukan Kas'),
                  ),
                  ButtonSegment(
                    value: TipeTransaksi.keluar,
                    icon: Icon(Icons.arrow_upward, color: Colors.red),
                    label: Text('Pengeluaran Kas'),
                  ),
                ],
                selected: {_tipe},
                onSelectionChanged: (setTipe) {
                  setState(() {
                    _tipe = setTipe.first;
                    _kategori = _tipe == TipeTransaksi.masuk
                        ? KategoriTransaksi.infak
                        : KategoriTransaksi.lain;
                  });
                },
              ),
              const SizedBox(height: 16),

              // ─── Info Saldo Terkini Saat Pengeluaran ──────────────────────
              if (_tipe == TipeTransaksi.keluar) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Siap Pakai:',
                              style: TextStyle(fontSize: 14)),
                          Text(
                            formatRupiah(ringkasan.saldoBisaDipakai),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pos Cadangan (10%):',
                              style: TextStyle(fontSize: 14)),
                          Text(
                            formatRupiah(ringkasan.danaCadanganTersedia),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Kas:',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            formatRupiah(ringkasan.totalSaldo),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Kategori Transaksi ──────────────────────────────────────
              DropdownButtonFormField<KategoriTransaksi>(
                key: ValueKey(_tipe),
                initialValue: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori Transaksi *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: (_tipe == TipeTransaksi.masuk
                        ? daftarKategoriMasuk
                        : daftarKategoriKeluar)
                    .map((kat) {
                  return DropdownMenuItem(
                    value: kat,
                    child: Text(kat.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kategori = val);
                },
              ),
              const SizedBox(height: 16),

              // ─── Nominal ────────────────────────────────────────────────
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp) *',
                  hintText: 'Contoh: 50000 atau 50.000',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  prefixText: 'Rp ',
                  helperText: _tipe == TipeTransaksi.masuk
                      ? '10% otomatis dicadangkan'
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  final nominal = parseRupiah(val);
                  return validasiNominalPositif(nominal);
                },
              ),
              const SizedBox(height: 16),

              // ─── Tanggal Transaksi ───────────────────────────────────────
              InkWell(
                onTap: _pilihTanggal,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Transaksi *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_tanggal),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Keterangan Transaksi ────────────────────────────────────
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan / Rincian *',
                  hintText: 'Contoh: Infak hamba Allah untuk operasional',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Keterangan wajib diisi';
                  }
                  if (val.trim().length < 3) {
                    return 'Keterangan terlalu singkat (min. 3 karakter)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ─── Tombol Simpan ──────────────────────────────────────────
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _tipe == TipeTransaksi.masuk
                      ? Colors.green[800]
                      : Colors.orange[900],
                ),
                onPressed: _sedangMenyimpan ? null : _simpan,
                icon: _sedangMenyimpan
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _sedangMenyimpan
                      ? 'Menyimpan...'
                      : (_tipe == TipeTransaksi.masuk
                          ? 'Simpan Pemasukan'
                          : 'Simpan Pengeluaran'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
