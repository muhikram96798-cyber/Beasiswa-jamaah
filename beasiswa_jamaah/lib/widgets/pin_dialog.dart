// Widget: PinDialog
// Dialog otentikasi PIN 6-digit dan dialog pembuatan/perubahan PIN pengurus.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/pengaturan_provider.dart';

/// Dialog untuk memverifikasi PIN sebelum membuka data rahasia
class PinAuthDialog extends StatefulWidget {
  final String judul;
  final String pesan;

  const PinAuthDialog({
    super.key,
    this.judul = 'Verifikasi PIN Pengurus',
    this.pesan =
        'Masukkan 6 digit PIN untuk membuka data identitas lengkap anak.',
  });

  /// Helper statis untuk menampilkan dialog dan mengembalikan bool (true jika lolos)
  static Future<bool> verifikasi(
    BuildContext context, {
    String? judul,
    String? pesan,
  }) async {
    final pengaturan = context.read<PengaturanProvider>();
    if (!pengaturan.sudahAdaPin) {
      return true; // Jika PIN belum diatur, langsung izinkan
    }

    final hasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinAuthDialog(
        judul: judul ?? 'Verifikasi PIN Pengurus',
        pesan: pesan ??
            'Masukkan 6 digit PIN untuk membuka data identitas lengkap anak.',
      ),
    );

    return hasil ?? false;
  }

  @override
  State<PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<PinAuthDialog> {
  final _controller = TextEditingController();
  String? _pesanError;

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length != 6) {
      setState(() {
        _pesanError = 'PIN harus terdiri dari 6 digit angka.';
      });
      return;
    }

    final pengaturan = context.read<PengaturanProvider>();
    if (pengaturan.verifikasiPin(pin)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _pesanError = 'PIN salah. Silakan coba lagi.';
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.judul,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.pesan, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 12,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '••••••',
              errorText: _pesanError,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              if (val.trim().length == 6) {
                _submit();
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('Buka'),
        ),
      ],
    );
  }
}

/// Dialog untuk mengatur PIN baru atau mengganti PIN lama
class AturPinDialog extends StatefulWidget {
  const AturPinDialog({super.key});

  @override
  State<AturPinDialog> createState() => _AturPinDialogState();
}

class _AturPinDialogState extends State<AturPinDialog> {
  final _pinLamaCtrl = TextEditingController();
  final _pinBaruCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();

  String? _errorPinLama;
  String? _errorPinBaru;
  String? _errorKonfirmasi;

  @override
  void dispose() {
    _pinLamaCtrl.dispose();
    _pinBaruCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() {
      _errorPinLama = null;
      _errorPinBaru = null;
      _errorKonfirmasi = null;
    });

    final pengaturan = context.read<PengaturanProvider>();
    final sudahAdaPin = pengaturan.sudahAdaPin;

    if (sudahAdaPin) {
      final pinLama = _pinLamaCtrl.text.trim();
      if (!pengaturan.verifikasiPin(pinLama)) {
        setState(() {
          _errorPinLama = 'PIN lama tidak cocok.';
        });
        return;
      }
    }

    final pinBaru = _pinBaruCtrl.text.trim();
    if (pinBaru.length != 6) {
      setState(() {
        _errorPinBaru = 'PIN baru harus 6 digit angka.';
      });
      return;
    }

    final konfirmasi = _konfirmasiCtrl.text.trim();
    if (konfirmasi != pinBaru) {
      setState(() {
        _errorKonfirmasi = 'Konfirmasi PIN tidak sama.';
      });
      return;
    }

    await pengaturan.simpanPin(pinBaru);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengaturan = context.watch<PengaturanProvider>();
    final sudahAdaPin = pengaturan.sudahAdaPin;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text(
            sudahAdaPin ? 'Ganti PIN Pengurus' : 'Atur PIN Keamanan',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PIN 6-digit digunakan untuk memproteksi identitas asli anak '
              'penerima beasiswa dari pihak luar.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            if (sudahAdaPin) ...[
              TextField(
                controller: _pinLamaCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'PIN Lama',
                  errorText: _errorPinLama,
                  counterText: '',
                  prefixIcon: const Icon(Icons.password),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _pinBaruCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: sudahAdaPin ? 'PIN Baru (6 digit)' : 'Buat PIN (6 digit)',
                errorText: _errorPinBaru,
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _konfirmasiCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Ulangi PIN Baru',
                errorText: _errorKonfirmasi,
                counterText: '',
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
              onSubmitted: (_) => _simpan(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('Simpan PIN'),
        ),
      ],
    );
  }
}
