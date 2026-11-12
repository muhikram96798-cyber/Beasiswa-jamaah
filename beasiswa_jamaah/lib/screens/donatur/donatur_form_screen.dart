// Layar: Form Tambah / Ubah Donatur
// Menggunakan validasi nominal iuran dinamis dari PengaturanProvider.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../utils/rupiah_formatter.dart';

class DonaturFormScreen extends StatefulWidget {
  final Donatur? donatur;

  const DonaturFormScreen({super.key, this.donatur});

  @override
  State<DonaturFormScreen> createState() => _DonaturFormScreenState();
}

class _DonaturFormScreenState extends State<DonaturFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _teleponController;
  late TextEditingController _nominalController;
  late TextEditingController _keteranganController;

  late bool _statusAktif;
  late DateTime _tanggalDaftar;
  bool _sedangMenyimpan = false;

  bool get _isEdit => widget.donatur != null;

  @override
  void initState() {
    super.initState();
    final d = widget.donatur;
    _namaController = TextEditingController(text: d?.namaKeluarga ?? '');
    _teleponController = TextEditingController(text: d?.nomorTelepon ?? '');
    _nominalController = TextEditingController(
      text: d != null ? d.nominalIuran.toString() : '',
    );
    _keteranganController = TextEditingController(text: d?.keterangan ?? '');
    _statusAktif = d?.statusAktif ?? true;

    if (d?.tanggalDaftar != null) {
      _tanggalDaftar = DateTime.tryParse(d!.tanggalDaftar) ?? DateTime.now();
    } else {
      _tanggalDaftar = DateTime.now();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDaftar,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _tanggalDaftar = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = parseRupiah(_nominalController.text) ?? 0;
    final tanggalDaftarStr = DateFormat('yyyy-MM-dd').format(_tanggalDaftar);
    final telepon = _teleponController.text.trim().isEmpty
        ? null
        : _teleponController.text.trim();

    setState(() => _sedangMenyimpan = true);

    try {
      final donaturProvider = context.read<DonaturProvider>();

      if (_isEdit) {
        final updated = widget.donatur!.copyWith(
          namaKeluarga: _namaController.text.trim(),
          nomorTelepon: telepon,
          nominalIuran: nominal,
          statusAktif: _statusAktif,
          tanggalDaftar: tanggalDaftarStr,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
        );
        await donaturProvider.perbaruiDonatur(updated);
      } else {
        final baru = Donatur(
          namaKeluarga: _namaController.text.trim(),
          nomorTelepon: telepon,
          nominalIuran: nominal,
          statusAktif: _statusAktif,
          tanggalDaftar: tanggalDaftarStr,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
        );
        await donaturProvider.tambahDonatur(baru);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Data donatur berhasil diperbarui'
                  : 'Donatur baru berhasil didaftarkan',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
        Navigator.of(context).pop(true);
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
    final pengaturan = context.watch<PengaturanProvider>();
    final iuranMin = pengaturan.iuranMin;
    final iuranMax = pengaturan.iuranMax;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Donatur' : 'Tambah Donatur Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nama Keluarga
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Keluarga Donatur *',
                  hintText: 'Contoh: Keluarga Bpk. H. Ahmad',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama keluarga wajib diisi';
                  }
                  if (val.trim().length < 3) {
                    return 'Nama terlalu pendek (minimal 3 karakter)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nomor HP / WhatsApp
              TextFormField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp / HP (Opsional)',
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText:
                      'Digunakan untuk mengirim pesan pengingat tagihan iuran via WhatsApp',
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (clean.length < 9) {
                      return 'Nomor telepon terlalu pendek (minimal 9 digit)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nominal Iuran
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Komitmen Iuran per Bulan *',
                  hintText: '${formatRupiah(iuranMin)} - ${formatRupiah(iuranMax)}',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  helperText:
                      'Rentang yang disarankan: ${formatRupiah(iuranMin)} - ${formatRupiah(iuranMax)} / bulan',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal iuran wajib diisi';
                  }
                  final nominal = parseRupiah(val);
                  if (nominal == null) {
                    return 'Format nominal tidak valid';
                  }
                  return validasiIuran(nominal, min: iuranMin, max: iuranMax);
                },
              ),
              const SizedBox(height: 8),

              // Pilihan Cepat Nominal
              Wrap(
                spacing: 8,
                children: [
                  _chipNominal(20000),
                  _chipNominal(25000),
                  _chipNominal(30000),
                ],
              ),
              const SizedBox(height: 16),

              // Tanggal Daftar
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai Bergabung *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalDaftar),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Switch Status Aktif
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text(
                    'Status Donatur Aktif',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _statusAktif
                        ? 'Donatur rutin berpartisipasi setiap bulan'
                        : 'Donatur berhenti / non-aktif sementara',
                  ),
                  value: _statusAktif,
                  activeThumbColor: Colors.green[800],
                  onChanged: (val) => setState(() => _statusAktif = val),
                ),
              ),
              const SizedBox(height: 16),

              // Keterangan Tambahan
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Keterangan (Opsional)',
                  hintText: 'Misal: alamat rumah atau kontak perwakilan',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Tombol Simpan
              FilledButton.icon(
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
                      : (_isEdit ? 'Simpan Perubahan' : 'Daftarkan Donatur'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipNominal(int nominal) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 16),
      label: Text(formatRupiah(nominal)),
      onPressed: () {
        setState(() {
          _nominalController.text = nominal.toString();
        });
      },
    );
  }
}
