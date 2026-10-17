// Helper: PinHelper
// Menghasilkan hash SHA-256 untuk PIN pengurus (6 digit) dengan salt.
// Mencegah penyimpanan PIN dalam bentuk teks terbuka di database.

import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinHelper {
  static const String _salt = 'beasiswa_jamaah_tetap_v1_salt_secure';

  /// Hash PIN 6 digit menggunakan SHA-256 dan salt
  static String hashPin(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi kecocokan PIN input dengan hash yang tersimpan
  static bool verifikasiPin(String inputPin, String storedHash) {
    if (storedHash.isEmpty) return true; // Belum ada PIN, bebas akses
    return hashPin(inputPin) == storedHash;
  }
}
