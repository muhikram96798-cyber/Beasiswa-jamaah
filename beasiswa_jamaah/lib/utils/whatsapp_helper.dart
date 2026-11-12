// Helper: WhatsApp & Pengingat Iuran
// Mengelola penyusunan template pesan tagihan yang ramah,
// normalisasi nomor WhatsApp Indonesia, pembukaan aplikasi WhatsApp via url_launcher,
// dan penyalinan otomatis ke clipboard sebagai pencadangan pesan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donatur.dart';
import '../providers/pengaturan_provider.dart';
import '../services/donatur_service.dart';
import 'rupiah_formatter.dart';

class WhatsAppHelper {
  WhatsAppHelper._();

  /// Bersihkan dan normalisasi format nomor HP Indonesia ke kode negara 62.
  /// Contoh: '08123456789' -> '628123456789'
  ///         '+62 812-3456-789' -> '628123456789'
  static String? normalisasiNomorWa(String? rawPhone) {
    if (rawPhone == null) return null;
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('0')) {
      return '62${digits.substring(1)}';
    } else if (digits.startsWith('62')) {
      return digits;
    } else {
      return '62$digits';
    }
  }

  /// Susun teks pesan tagihan iuran yang santun, lengkap dengan identitas masjid,
  /// rincian rekening, dan petunjuk transfer/QRIS.
  static String buatPesanTagihan({
    required Donatur donatur,
    required int bulan,
    required PengaturanProvider pengaturan,
  }) {
    final namaBulan = DonaturService.getNamaBulan(bulan);
    final nominalStr = formatRupiah(donatur.nominalIuran);

    return '''
Assalamu'alaikum Warahmatullahi Wabarakatuh.
Yth. ${donatur.namaKeluarga},

Semoga Bapak/Ibu sekeluarga senantiasa dalam lindungan dan rahmat Allah SWT.

Kami dari Pengurus Beasiswa Jamaah Tetap (${pengaturan.namaMasjid}) bermaksud menginformasikan iuran program beasiswa yatim & dhuafa untuk bulan $namaBulan sebesar $nominalStr.

Iuran dapat disalurkan secara tunai atau melalui transfer / scan QRIS:
• Bank: ${pengaturan.namaBank}
• No. Rekening: ${pengaturan.nomorRekening} (a.n. ${pengaturan.atasNamaRekening})
• Petunjuk: ${pengaturan.catatanQris}

Jazakumullahu khairan katsiran atas sedekah dan keistiqomahan Bapak/Ibu. Semoga menjadi amal jariyah yang berlipat ganda. Aamiin ya Rabbal 'Alamin.
'''.trim();
  }

  /// Kirim pengingat tagihan iuran ke donatur:
  /// 1. Salin pesan ke Clipboard.
  /// 2. Buka aplikasi WhatsApp via link wa.me jika nomor donatur tersedia (atau wa.me umum jika belum).
  /// 3. Beri umpan balik visual (SnackBar).
  static Future<void> kirimPengingatWa({
    required BuildContext context,
    required Donatur donatur,
    required int bulan,
    required PengaturanProvider pengaturan,
  }) async {
    final pesan = buatPesanTagihan(
      donatur: donatur,
      bulan: bulan,
      pengaturan: pengaturan,
    );

    // 1. Selalu salin pesan ke clipboard terlebih dahulu
    await Clipboard.setData(ClipboardData(text: pesan));

    // 2. Format URL WhatsApp
    final nomorClean = normalisasiNomorWa(donatur.nomorTelepon);
    final encodedText = Uri.encodeComponent(pesan);

    final String urlString;
    if (nomorClean != null && nomorClean.length >= 9) {
      urlString = 'https://wa.me/$nomorClean?text=$encodedText';
    } else {
      // Jika nomor HP belum diisi, buka WA share umum
      urlString = 'https://wa.me/?text=$encodedText';
    }

    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!context.mounted) return;

      if (launched) {
        final adaNomor = nomorClean != null && nomorClean.length >= 9;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adaNomor
                  ? 'Membuka WhatsApp untuk ${donatur.namaKeluarga} (${donatur.nomorTelepon})...'
                  : 'Pesan pengingat disalin ke clipboard! (Donatur belum memiliki No. WhatsApp)',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
            action: !adaNomor
                ? SnackBarAction(
                    label: 'TUTUP',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teks pengingat ${donatur.namaKeluarga} disalin ke clipboard. (Aplikasi WhatsApp tidak dapat dibuka otomatis)',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teks pengingat disalin ke clipboard. Terjadi kesalahan membuka WhatsApp: $e',
          ),
          backgroundColor: Colors.orange[900],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
