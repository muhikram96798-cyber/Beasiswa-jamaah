// Provider: PengaturanProvider
// Membaca dan menyimpan nilai konfigurasi dari tabel pengaturan.

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pengaturan.dart';
import '../services/database_service.dart';

class PengaturanProvider extends ChangeNotifier {
  final Map<String, String> _data = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Muat semua pengaturan dari database
  Future<void> muat() async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query('pengaturan');
      _data.clear();
      for (final row in rows) {
        _data[row['kunci'] as String] = row['nilai'] as String;
      }
      _loaded = true;
    } catch (_) {
      // Fallback ke nilai default jika database belum diinisialisasi (misal saat widget testing)
      _data.clear();
      _data.addAll(PengaturanKey.defaults);
      _loaded = true;
    }
    notifyListeners();
  }

  /// Baca nilai sebagai String
  String get(String kunci, {String defaultValue = ''}) =>
      _data[kunci] ?? defaultValue;

  /// Baca nilai sebagai int
  int getInt(String kunci, {int defaultValue = 0}) =>
      int.tryParse(_data[kunci] ?? '') ?? defaultValue;

  /// Simpan satu nilai ke database dan memory
  Future<void> set(String kunci, String nilai) async {
    final db = await DatabaseService.instance.database;
    await db.insert(
      'pengaturan',
      {'kunci': kunci, 'nilai': nilai},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _data[kunci] = nilai;
    notifyListeners();
  }

  // ─── Getter shortcut untuk nilai yang sering dipakai ─────────────────────

  int get biayaSd => getInt(PengaturanKey.biayaSd, defaultValue: 2310000);
  int get biayaSmp => getInt(PengaturanKey.biayaSmp, defaultValue: 3575000);
  int get biayaSma => getInt(PengaturanKey.biayaSma, defaultValue: 4785000);

  int get pipSd => getInt(PengaturanKey.pipSd, defaultValue: 450000);
  int get pipSmp => getInt(PengaturanKey.pipSmp, defaultValue: 750000);
  int get pipSma => getInt(PengaturanKey.pipSma, defaultValue: 1800000);

  int get iuranMin => getInt(PengaturanKey.iuranMin, defaultValue: 20000);
  int get iuranMax => getInt(PengaturanKey.iuranMax, defaultValue: 30000);
  int get pctCadangan => getInt(PengaturanKey.pctCadangan, defaultValue: 10);
  int get persentaseCadangan => pctCadangan;

  int get bobotEkonomi => getInt(PengaturanKey.bobotEkonomi, defaultValue: 40);
  int get bobotYatim => getInt(PengaturanKey.bobotYatim, defaultValue: 30);
  int get bobotSaudara => getInt(PengaturanKey.bobotSaudara, defaultValue: 15);
  int get bobotKip => getInt(PengaturanKey.bobotKip, defaultValue: 15);

  int get putusSekolah => getInt(PengaturanKey.putusSekolah, defaultValue: 0);

  Future<void> setPutusSekolah(int nilai) async {
    await set(PengaturanKey.putusSekolah, '$nilai');
  }

  int get tahunAjaranAktif =>
      getInt(PengaturanKey.tahunAjaranAktif, defaultValue: DateTime.now().year);

  String get pinHash => get(PengaturanKey.pinHash);
  bool get sudahAdaPin => pinHash.isNotEmpty;
}
