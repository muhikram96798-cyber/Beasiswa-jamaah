// Layar: PratinjauLaporanScreen
// Menampilkan pratinjau PDF interaktif menggunakan package printing.
// Dilengkapi tombol cetak fisik (printer) dan bagikan file (WhatsApp/Telegram/Email).

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/anak.dart';
import '../../models/donatur.dart';
import '../../models/iuran.dart';
import '../../models/penyaluran.dart';
import '../../models/transaksi_kas.dart';
import '../../services/laporan_pdf_service.dart';

class PratinjauLaporanScreen extends StatelessWidget {
  final int tahunAjaran;
  final PeriodeLaporan periode;
  final List<Donatur> daftarDonatur;
  final Map<int, Map<int, Iuran>> matriksIuran;
  final List<Anak> daftarAnak;
  final List<Penyaluran> daftarPenyaluran;
  final List<TransaksiKas> daftarTransaksiKas;
  final int persentaseCadangan;
  final int biayaSd;
  final int biayaSmp;
  final int biayaSma;
  final int pipSd;
  final int pipSmp;
  final int pipSma;
  final int putusSekolah;

  const PratinjauLaporanScreen({
    super.key,
    required this.tahunAjaran,
    required this.periode,
    required this.daftarDonatur,
    required this.matriksIuran,
    required this.daftarAnak,
    required this.daftarPenyaluran,
    required this.daftarTransaksiKas,
    required this.persentaseCadangan,
    required this.biayaSd,
    required this.biayaSmp,
    required this.biayaSma,
    required this.pipSd,
    required this.pipSmp,
    required this.pipSma,
    required this.putusSekolah,
  });

  @override
  Widget build(BuildContext context) {
    final namaFile =
        'Laporan_Beasiswa_Jamaah_${tahunAjaran}_${periode.name}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pratinjau ${periode.label}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: PdfPreview(
        build: (format) => LaporanPdfService.generateLaporanPdf(
          tahunAjaran: tahunAjaran,
          periode: periode,
          daftarDonatur: daftarDonatur,
          matriksIuran: matriksIuran,
          daftarAnak: daftarAnak,
          daftarPenyaluran: daftarPenyaluran,
          daftarTransaksiKas: daftarTransaksiKas,
          persentaseCadangan: persentaseCadangan,
          biayaSd: biayaSd,
          biayaSmp: biayaSmp,
          biayaSma: biayaSma,
          pipSd: pipSd,
          pipSmp: pipSmp,
          pipSma: pipSma,
          putusSekolah: putusSekolah,
        ),
        pdfFileName: namaFile,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Menyusun Dokumen Laporan...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Menghitung matriks kas, donatur, dan perlindungan privasi anak.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
