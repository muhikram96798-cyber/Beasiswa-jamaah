// Layar: Matriks Pembayaran Iuran Januari - Desember
// Menampilkan status pembayaran 12 bulan untuk seluruh donatur secara komprehensif.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/donatur.dart';
import '../../models/iuran.dart';
import '../../providers/donatur_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../services/donatur_service.dart';
import '../../utils/rupiah_formatter.dart';
import '../../utils/whatsapp_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/konfirmasi_dialog.dart';
import 'catat_iuran_dialog.dart';

class IuranMatriksScreen extends StatefulWidget {
  const IuranMatriksScreen({super.key});

  @override
  State<IuranMatriksScreen> createState() => _IuranMatriksScreenState();
}

class _IuranMatriksScreenState extends State<IuranMatriksScreen> {
  late int _tahunTerpilih;

  @override
  void initState() {
    super.initState();
    _tahunTerpilih = context.read<DonaturProvider>().tahunAktif;
  }

  void _ubahTahun(int tahunBaru) {
    setState(() => _tahunTerpilih = tahunBaru);
    context.read<DonaturProvider>().muatData(tahun: tahunBaru);
  }

  void _tampilkanDetailIuran(Donatur donatur, Iuran iuran) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Pembayaran Iuran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _barisInfo('Donatur', donatur.namaKeluarga),
            _barisInfo(
              'Periode',
              '${DonaturService.getNamaBulan(iuran.bulan)} ${iuran.tahunAjaran}',
            ),
            _barisInfo('Nominal', formatRupiah(iuran.nominal)),
            _barisInfo(
              'Tanggal Bayar',
              DateFormat('d MMMM yyyy', 'id_ID')
                  .format(DateTime.tryParse(iuran.tanggalBayar) ?? DateTime.now()),
            ),
            const Divider(),
            const Text(
              'Pembayaran ini tercatat otomatis di Kas Bersama.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
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
            label: const Text('Batalkan Iuran'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final konfirmasi = await tampilkanKonfirmasi(
                context: context,
                judul: 'Batalkan Pembayaran?',
                pesan:
                    'Pembayaran ${DonaturService.getNamaBulan(iuran.bulan)} untuk ${donatur.namaKeluarga} akan dihapus dan transaksi masuk kas juga akan ditarik kembali.',
                destruktif: true,
                labelKonfirmasi: 'Ya, Batalkan',
              );

              if (konfirmasi && mounted) {
                try {
                  await context.read<DonaturProvider>().batalkanIuran(iuran.id!);
                  if (mounted) {
                    context.read<KasProvider>().muatData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pembayaran iuran dibatalkan')),
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
            },
          ),
        ],
      ),
    );
  }

  void _tampilkanAksiBelumBayar(Donatur donatur, int bulan) {
    final namaBulan = DonaturService.getNamaBulan(bulan);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donatur.namaKeluarga,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Iuran Bulan $namaBulan $_tahunTerpilih • Belum Bayar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.chat_outlined, color: Color(0xFF2E7D32)),
                ),
                title: const Text(
                  'Kirim Pengingat WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  donatur.nomorTelepon != null && donatur.nomorTelepon!.isNotEmpty
                      ? 'No. WA: ${donatur.nomorTelepon}'
                      : 'Salin template pesan (belum ada nomor WA)',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  WhatsAppHelper.kirimPengingatWa(
                    context: context,
                    donatur: donatur,
                    bulan: bulan,
                    pengaturan: context.read<PengaturanProvider>(),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.add_card_outlined, color: Colors.blue.shade800),
                ),
                title: const Text(
                  'Catat Pembayaran Iuran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Nominal komitmen: ${formatRupiah(donatur.nominalIuran)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final berhasil = await CatatIuranDialog.show(
                    context,
                    donatur: donatur,
                    bulanAwal: bulan,
                    tahunAwal: _tahunTerpilih,
                  );
                  if (berhasil == true && mounted) {
                    context.read<KasProvider>().muatData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Iuran ${donatur.namaKeluarga} bulan $namaBulan berhasil dicatat',
                        ),
                        backgroundColor: Colors.green[800],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
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
            width: 110,
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

  @override
  Widget build(BuildContext context) {
    final donaturProvider = context.watch<DonaturProvider>();
    final daftarDonatur = donaturProvider.daftarDonatur;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matriks Iuran Jan - Des'),
        actions: [
          // Pilihan Tahun Ajaran
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _tahunTerpilih,
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: [
                _tahunTerpilih - 1,
                _tahunTerpilih,
                _tahunTerpilih + 1,
              ].map((th) {
                return DropdownMenuItem(
                  value: th,
                  child: Text(
                    'Tahun $th',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _ubahTahun(val);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: donaturProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : daftarDonatur.isEmpty
              ? const EmptyState(
                  ikon: Icons.people_outline,
                  pesan: 'Belum ada donatur terdaftar',
                  subPesan: 'Daftarkan donatur terlebih dahulu di tab Donatur.',
                )
              : Column(
                  children: [
                    // Panduan Legenda Singkat
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _legendaItem(Colors.green[700]!, 'Lunas (Tap detail)'),
                          _legendaItem(Colors.orange[800]!, 'Belum (Tap bayar)'),
                          _legendaItem(Colors.grey[400]!, 'Berhenti'),
                        ],
                      ),
                    ),

                    // Tabel Matriks
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            headingRowColor: WidgetStateProperty.all(
                              Colors.green.shade50,
                            ),
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'Nama Keluarga',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...List.generate(12, (index) {
                                return DataColumn(
                                  label: Center(
                                    child: Text(
                                      DonaturService.singkatanBulan[index],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }),
                              const DataColumn(
                                label: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: daftarDonatur.map((donatur) {
                              int hitungLunas = 0;

                              final selBulan = List.generate(12, (idx) {
                                final bulan = idx + 1;
                                final iuran = donaturProvider.getIuran(
                                    donatur.id!, bulan);
                                final isLunas = iuran != null;
                                if (isLunas) hitungLunas++;

                                return DataCell(
                                  InkWell(
                                    onTap: () {
                                      if (isLunas) {
                                        _tampilkanDetailIuran(donatur, iuran);
                                      } else if (donatur.statusAktif) {
                                        _tampilkanAksiBelumBayar(donatur, bulan);
                                      }
                                    },
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLunas
                                              ? Colors.green.shade100
                                              : donatur.statusAktif
                                                  ? Colors.orange.shade50
                                                  : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isLunas
                                                ? Colors.green.shade600
                                                : donatur.statusAktif
                                                    ? Colors.orange.shade300
                                                    : Colors.grey.shade400,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isLunas
                                              ? '✓'
                                              : donatur.statusAktif
                                                  ? '-'
                                                  : 'x',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isLunas
                                                ? Colors.green.shade900
                                                : donatur.statusAktif
                                                    ? Colors.orange.shade900
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });

                              return DataRow(
                                color: WidgetStateProperty.resolveWith((states) {
                                  if (!donatur.statusAktif) {
                                    return Colors.grey.shade50;
                                  }
                                  return null;
                                }),
                                cells: [
                                  DataCell(
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              donatur.namaKeluarga,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: donatur.statusAktif
                                                    ? Colors.black87
                                                    : Colors.grey,
                                              ),
                                            ),
                                            if (!donatur.statusAktif) ...[
                                              const SizedBox(width: 4),
                                              const Text(
                                                '(Berhenti)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (donatur.nomorTelepon != null &&
                                            donatur.nomorTelepon!.isNotEmpty)
                                          Text(
                                            donatur.nomorTelepon!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  ...selBulan,
                                  DataCell(
                                    Center(
                                      child: Text(
                                        '$hitungLunas/12',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: hitungLunas == 12
                                              ? Colors.green.shade800
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _legendaItem(Color warna, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
