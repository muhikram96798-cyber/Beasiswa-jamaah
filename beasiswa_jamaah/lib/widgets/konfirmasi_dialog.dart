// Widget: KonfirmasiDialog
// Dialog konfirmasi yang digunakan untuk tindakan penting
// (hapus data, cairkan cadangan, impor backup, dll.)

import 'package:flutter/material.dart';

/// Tampilkan dialog konfirmasi standar.
/// Mengembalikan true jika user menekan tombol konfirmasi, false jika batal.
Future<bool> tampilkanKonfirmasi({
  required BuildContext context,
  required String judul,
  required String pesan,
  String labelKonfirmasi = 'Ya, lanjutkan',
  String labelBatal = 'Batal',
  bool destruktif = false,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(labelBatal),
        ),
        FilledButton(
          style: destruktif
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(labelKonfirmasi),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

/// Dialog konfirmasi dengan kolom alasan wajib diisi.
/// Dipakai saat mencairkan dana cadangan.
/// Mengembalikan String alasan jika dikonfirmasi, null jika dibatalkan.
Future<String?> tampilkanKonfirmasiDenganAlasan({
  required BuildContext context,
  required String judul,
  required String pesan,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final hasil = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pesan),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Alasan *',
                hintText: 'Jelaskan alasan menggunakan dana cadangan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Alasan wajib diisi';
                }
                if (v.trim().length < 10) {
                  return 'Alasan terlalu singkat (min. 10 karakter)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
          child: const Text('Cairkan Dana'),
        ),
      ],
    ),
  );
  return hasil;
}
