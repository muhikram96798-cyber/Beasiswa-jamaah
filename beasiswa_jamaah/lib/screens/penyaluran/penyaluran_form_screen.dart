// Layar: Form Pencatatan Penyaluran Bantuan
// Mencatat pembelian perlengkapan (barang langsung ke toko/penjahit)
// atau uang saku bulanan (lewat wali kelas/orang tua).
// Otomatis terintegrasi sebagai pengeluaran kas bersama.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/anak.dart';
import '../../models/penyaluran.dart';
import '../../providers/anak_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../providers/penyaluran_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';
import '../../widgets/konfirmasi_dialog.dart';

class PenyaluranFormScreen extends StatefulWidget {
  final Anak? anak;

  const PenyaluranFormScreen({super.key, this.anak});

  @override
  State<PenyaluranFormScreen> createState() => _PenyaluranFormScreenState();
}

class _PenyaluranFormScreenState extends State<PenyaluranFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Anak? _anakTerpilih;
  bool _isUangSaku = false;
  JenisPenyaluran _jenisBarang = JenisPenyaluran.seragam;

  // Controller
  final _nominalController = TextEditingController();
  final _penerimaTokoController = TextEditingController();
  final _keteranganBarangController = TextEditingController();

  int _bulanUangSaku = DateTime.now().month;
  DateTime _tanggal = DateTime.now();
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _anakTerpilih = widget.anak;
    _inisialisasiPenerima();
  }

  void _inisialisasiPenerima() {
    if (_isUangSaku) {
      if (_anakTerpilih?.namaWali != null &&
          _anakTerpilih!.namaWali!.trim().isNotEmpty) {
        _penerimaTokoController.text = _anakTerpilih!.namaWali!;
      }
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _penerimaTokoController.dispose();
    _keteranganBarangController.dispose();
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
    if (_anakTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih anak penerima terlebih dahulu')),
      );
      return;
    }

    final nominal = parseRupiah(_nominalController.text) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final kasProvider = context.read<KasProvider>();
    final anakProvider = context.read<AnakProvider>();
    final penyaluranProvider = context.read<PenyaluranProvider>();
    final pengaturan = context.read<PengaturanProvider>();
    final ringkasan = kasProvider.ringkasanKas;

    // 1. Cek Saldo Total Kas
    if (nominal > ringkasan.totalSaldo) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Kas Tidak Mencukupi'),
          content: Text(
            'Total saldo kas saat ini hanya ${formatRupiah(ringkasan.totalSaldo)}.\n\n'
            'Penyaluran sebesar ${formatRupiah(nominal)} tidak dapat dilakukan karena kas tidak boleh minus.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Cek apakah melebihi Saldo yang Bisa Dipakai (Perlu Dana Cadangan)
    bool gunakanCadangan = false;
    String? alasanCadangan;

    if (nominal > ringkasan.saldoBisaDipakai) {
      if (!mounted) return;
      final alasan = await tampilkanKonfirmasiDenganAlasan(
        context: context,
        judul: 'Gunakan Dana Cadangan?',
        pesan:
            'Saldo siap pakai (${formatRupiah(ringkasan.saldoBisaDipakai)}) tidak mencukupi untuk penyaluran ${formatRupiah(nominal)}.\n\n'
            'Penyaluran ini akan mencairkan sebagian Pos Dana Cadangan 10% (Tersedia: ${formatRupiah(ringkasan.danaCadanganTersedia)}).\n\n'
            'Sesuai aturan program, mohon masukkan alasan penggunaan dana cadangan:',
      );

      if (alasan == null) {
        return; // Dibatalkan oleh pengurus
      }

      gunakanCadangan = true;
      alasanCadangan = alasan;
    }

    // 3. Susun data Penyaluran
    final JenisPenyaluran jenisFinal =
        _isUangSaku ? JenisPenyaluran.uangSaku : _jenisBarang;

    final String keteranganFinal;
    if (_isUangSaku) {
      final namaBulan = DonaturService.getNamaBulan(_bulanUangSaku);
      final rincianTambahan = _keteranganBarangController.text.trim();
      keteranganFinal = rincianTambahan.isNotEmpty
          ? 'Bulan $namaBulan ($rincianTambahan)'
          : 'Bulan $namaBulan';
    } else {
      keteranganFinal = _keteranganBarangController.text.trim();
    }

    final penyaluranBaru = Penyaluran(
      anakId: _anakTerpilih!.id!,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      jenis: jenisFinal,
      keterangan: keteranganFinal,
      nominal: nominal,
      penerima: _penerimaTokoController.text.trim(),
    );

    setState(() => _sedangMenyimpan = true);

    try {
      await penyaluranProvider.catatPenyaluran(
        penyaluran: penyaluranBaru,
        namaAnak: '${_anakTerpilih!.kodeAnak} (${_anakTerpilih!.namaSamaran})',
        gunakanCadangan: gunakanCadangan,
        alasanCadangan: alasanCadangan,
        persentaseCadangan: pengaturan.persentaseCadangan,
      );

      // Refresh data kas dan anak
      if (mounted) {
        await kasProvider.muatData();
        await anakProvider.muatData();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text(
              'Bantuan berhasil disalurkan & dicatat di kas keluar (${formatRupiah(nominal)})',
            ),
          ),
        );
        nav.pop(true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text(e.toString()),
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
    final ringkasan = kasProvider.ringkasanKas;
    final anakProvider = context.watch<AnakProvider>();
    final daftarAnak = anakProvider.daftarAnakAktif;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Penyaluran Bantuan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Kartu Informasi Saldo Kas Saat Ini ──────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.green[800], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Kas Siap Pakai:',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          Text(
                            formatRupiah(ringkasan.saldoBisaDipakai),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          Text(
                            'Total Kas: ${formatRupiah(ringkasan.totalSaldo)} (termasuk cadangan 10%)',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Pemilihan Anak Penerima ──────────────────────────────────
              if (widget.anak != null) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        widget.anak!.kodeAnak,
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      widget.anak!.namaLengkap,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${widget.anak!.namaSamaran} • ${widget.anak!.jenjang.label} Kelas ${widget.anak!.kelas}',
                    ),
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<Anak>(
                  initialValue: _anakTerpilih,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Anak Penerima *',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: daftarAnak.map((anak) {
                    return DropdownMenuItem(
                      value: anak,
                      child: Text(
                        '${anak.kodeAnak}: ${anak.namaSamaran} (${anak.jenjang.label} Kl. ${anak.kelas})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _anakTerpilih = val;
                      _inisialisasiPenerima();
                    });
                  },
                  validator: (val) =>
                      val == null ? 'Pilih anak penerima' : null,
                ),
              ],
              const SizedBox(height: 16),

              // ─── Pemilihan Jenis Bantuan ──────────────────────────────────
              const Text(
                'Bentuk Bantuan:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Perlengkapan'),
                    icon: Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Uang Saku'),
                    icon: Icon(Icons.monetization_on_outlined),
                  ),
                ],
                selected: {_isUangSaku},
                onSelectionChanged: (set) {
                  setState(() {
                    _isUangSaku = set.first;
                    _penerimaTokoController.clear();
                    _inisialisasiPenerima();
                  });
                },
              ),
              const SizedBox(height: 16),

              // ─── Bagian Khusus Perlengkapan Barang ────────────────────────
              if (!_isUangSaku) ...[
                // Banner Aturan Program: Perlengkapan HANYA Barang
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Perlengkapan sekolah dibeli langsung berupa barang ke toko/penjahit. Tidak ada opsi uang tunai ke anak.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori Perlengkapan
                DropdownButtonFormField<JenisPenyaluran>(
                  initialValue: _jenisBarang,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Perlengkapan Sekolah *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    JenisPenyaluran.seragam,
                    JenisPenyaluran.sepatu,
                    JenisPenyaluran.tas,
                    JenisPenyaluran.buku,
                    JenisPenyaluran.lain,
                  ].map((j) {
                    return DropdownMenuItem(
                      value: j,
                      child: Text(j.label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _jenisBarang = val);
                  },
                ),
                const SizedBox(height: 16),

                // Nama Toko / Penjahit (Wajib)
                TextFormField(
                  controller: _penerimaTokoController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko / Penjahit *',
                    hintText: 'Contoh: Toko Seragam Barokah / Penjahit Pak Joko',
                    prefixIcon: Icon(Icons.storefront_outlined),
                    helperText: 'Tempat perlengkapan dibeli / dipesan',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama toko atau penjahit wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rincian Barang
                TextFormField(
                  controller: _keteranganBarangController,
                  decoration: const InputDecoration(
                    labelText: 'Rincian Barang (Ukuran / Spesifikasi)',
                    hintText: 'Contoh: 2 setel merah putih + sabuk dan topi',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],

              // ─── Bagian Khusus Uang Saku Bulanan ──────────────────────────
              if (_isUangSaku) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Uang saku bulanan disalurkan melalui wali kelas atau orang tua anak.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Pilihan Bulan
                DropdownButtonFormField<int>(
                  initialValue: _bulanUangSaku,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Untuk Bulan *',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: List.generate(12, (i) {
                    final b = i + 1;
                    return DropdownMenuItem(
                      value: b,
                      child: Text(
                        DonaturService.getNamaBulan(b),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) setState(() => _bulanUangSaku = val);
                  },
                ),
                const SizedBox(height: 16),

                // Penerima Uang Saku (Wali / Orang Tua)
                TextFormField(
                  controller: _penerimaTokoController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima (Wali Kelas / Orang Tua) *',
                    hintText: 'Contoh: Ibu Rina (Wali Kelas 3) / Bu Maryam (Ibu)',
                    prefixIcon: Icon(Icons.person_pin_outlined),
                    helperText: 'Yang menerima dan mendampingi uang saku anak',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama penerima uang saku wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Catatan Tambahan
                TextFormField(
                  controller: _keteranganBarangController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Penyaluran (Opsional)',
                    hintText: 'Contoh: Diserahkan tunai di ruang guru',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ─── Nominal (Rp) ────────────────────────────────────────────
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nominal Biaya / Bantuan (Rp) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  hintText: 'Contoh: 150000',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  final n = parseRupiah(val);
                  return validasiNominalPositif(n);
                },
              ),
              const SizedBox(height: 16),

              // ─── Tanggal Penyaluran ──────────────────────────────────────
              InkWell(
                onTap: _pilihTanggal,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Penyaluran / Pembelian *',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_tanggal),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Tombol Simpan ───────────────────────────────────────────
              FilledButton.icon(
                onPressed: _sedangMenyimpan ? null : _simpan,
                icon: _sedangMenyimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _sedangMenyimpan
                      ? 'Menyimpan...'
                      : 'Simpan Penyaluran (Masuk Kas Keluar)',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
