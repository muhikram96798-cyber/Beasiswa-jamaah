// Dialog: Catat Iuran Donatur
// Mencatat pembayaran iuran per bulan untuk satu donatur.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';

class CatatIuranDialog extends StatefulWidget {
  final Donatur donatur;
  final int? bulanAwal;
  final int? tahunAwal;

  const CatatIuranDialog({
    super.key,
    required this.donatur,
    this.bulanAwal,
    this.tahunAwal,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Donatur donatur,
    int? bulanAwal,
    int? tahunAwal,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CatatIuranDialog(
        donatur: donatur,
        bulanAwal: bulanAwal,
        tahunAwal: tahunAwal,
      ),
    );
  }

  @override
  State<CatatIuranDialog> createState() => _CatatIuranDialogState();
}

class _CatatIuranDialogState extends State<CatatIuranDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _bulanTerpilih;
  late int _tahunTerpilih;
  late TextEditingController _nominalController;
  late DateTime _tanggalBayar;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    final tahunPengaturan =
        context.read<PengaturanProvider>().tahunAjaranAktif;
    _tahunTerpilih = widget.tahunAwal ?? tahunPengaturan;
    
    // Jika bulan awal tidak dispesifikasikan, utamakan bulan yang belum lunas
    final donaturProvider = context.read<DonaturProvider>();
    int bulanAwal = widget.bulanAwal ?? DateTime.now().month;
    if (widget.bulanAwal == null &&
        donaturProvider.sudahBayar(widget.donatur.id!, bulanAwal)) {
      for (int b = 1; b <= 12; b++) {
        if (!donaturProvider.sudahBayar(widget.donatur.id!, b)) {
          bulanAwal = b;
          break;
        }
      }
    }
    _bulanTerpilih = bulanAwal;
    _nominalController =
        TextEditingController(text: widget.donatur.nominalIuran.toString());
    _tanggalBayar = DateTime.now();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBayar,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _tanggalBayar = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final donaturProvider = context.read<DonaturProvider>();
    if (donaturProvider.sudahBayar(widget.donatur.id!, _bulanTerpilih)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Iuran bulan ${DonaturService.getNamaBulan(_bulanTerpilih)} $_tahunTerpilih sudah pernah dicatat.',
          ),
          backgroundColor: Colors.orange.shade900,
        ),
      );
      return;
    }

    final nominal = parseRupiah(_nominalController.text) ?? 0;
    final tanggalStr = DateFormat('yyyy-MM-dd').format(_tanggalBayar);

    setState(() => _sedangMenyimpan = true);

    try {
      final provider = context.read<DonaturProvider>();
      await provider.catatIuran(
        donaturId: widget.donatur.id!,
        bulan: _bulanTerpilih,
        nominal: nominal,
        tanggalBayar: tanggalStr,
        tahun: _tahunTerpilih,
      );

      if (mounted) {
        final pct = context.read<PengaturanProvider>().pctCadangan;
        await context.read<KasProvider>().muatData(persentaseCadangan: pct);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final pesan = e is StateError ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
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
    final donaturProvider = context.watch<DonaturProvider>();
    final sudahBayar =
        donaturProvider.sudahBayar(widget.donatur.id!, _bulanTerpilih);

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catat Iuran Bulanan'),
          const SizedBox(height: 4),
          Text(
            widget.donatur.namaKeluarga,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.green[800],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Peringatan jika sudah bayar
            if (sudahBayar) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Iuran bulan ${DonaturService.getNamaBulan(_bulanTerpilih)} $_tahunTerpilih sudah lunas.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pilihan Bulan
            DropdownButtonFormField<int>(
              initialValue: _bulanTerpilih,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Untuk Bulan *',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: List.generate(12, (index) {
                final bulan = index + 1;
                final sudah =
                    donaturProvider.sudahBayar(widget.donatur.id!, bulan);
                return DropdownMenuItem<int>(
                  value: bulan,
                  child: Text(
                    '${DonaturService.getNamaBulan(bulan)}${sudah ? ' (Sudah Lunas)' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sudah ? Colors.green[800] : Colors.black87,
                      fontWeight: sudah ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _bulanTerpilih = val);
              },
              validator: (val) {
                if (val != null &&
                    donaturProvider.sudahBayar(widget.donatur.id!, val)) {
                  return 'Iuran bulan ini sudah lunas dicatat';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tahun Ajaran
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tahun Ajaran',
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text('$_tahunTerpilih', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // Nominal Bayar
            TextFormField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Bayar (Rp) *',
                prefixIcon: Icon(Icons.payments_outlined),
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

            // Tanggal Bayar
            InkWell(
              onTap: _pilihTanggal,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pembayaran *',
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalBayar),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: _sedangMenyimpan ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: (_sedangMenyimpan || sudahBayar) ? null : _simpan,
          icon: _sedangMenyimpan
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('Simpan ke Kas'),
        ),
      ],
    );
  }
}
