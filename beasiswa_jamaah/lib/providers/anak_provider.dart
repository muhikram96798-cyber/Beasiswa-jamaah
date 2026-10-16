// Provider: AnakProvider
// Mengelola state daftar anak penerima beasiswa, perhitungan skor seleksi,
// dan total kebutuhan dana program.

import 'package:flutter/foundation.dart';
import '../models/anak.dart';
import '../services/anak_service.dart';
import '../utils/skor_seleksi.dart';
import 'pengaturan_provider.dart';

class AnakProvider extends ChangeNotifier {
  final AnakService _service;

  AnakProvider({AnakService? service}) : _service = service ?? AnakService();

  List<Anak> _daftarAnak = [];
  bool _loading = false;
  String? _pesanError;

  List<Anak> get daftarAnak => _daftarAnak;
  bool get loading => _loading;
  String? get pesanError => _pesanError;

  List<Anak> get anakAktif => _daftarAnak.where((a) => a.aktif).toList();
  List<Anak> get anakSelesai => _daftarAnak.where((a) => !a.aktif).toList();

  int get totalAnak => _daftarAnak.length;
  int get totalAnakAktif => anakAktif.length;

  Future<void> muatData() async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      _daftarAnak = await _service.getSemuaAnak();
    } catch (e) {
      _pesanError = 'Gagal memuat data anak: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> getKodeBaru() async {
    return await _service.generateKodeBaru();
  }

  Future<void> tambahAnak(Anak anak) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.tambahAnak(anak);
      await muatData();
    } catch (e) {
      _pesanError = 'Gagal menambah anak: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> perbaruiAnak(Anak anak) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.updateAnak(anak);
      await muatData();
    } catch (e) {
      _pesanError = 'Gagal memperbarui anak: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleStatusAnak(Anak anak) async {
    final updated = anak.copyWith(aktif: !anak.aktif);
    await perbaruiAnak(updated);
  }

  Future<void> hapusAnak(int id) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.hapusAnak(id);
      await muatData();
    } catch (e) {
      _pesanError = 'Gagal menghapus anak: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Menghitung total kebutuhan dana beasiswa untuk seluruh anak aktif
  int hitungTotalKebutuhan(PengaturanProvider pengaturan) {
    int total = 0;
    for (final anak in anakAktif) {
      total += hitungKebutuhanDana(
        jenjang: anak.jenjang,
        statusPip: anak.statusPip,
        biayaSd: pengaturan.biayaSd,
        biayaSmp: pengaturan.biayaSmp,
        biayaSma: pengaturan.biayaSma,
        pipSd: pengaturan.pipSd,
        pipSmp: pengaturan.pipSmp,
        pipSma: pengaturan.pipSma,
      );
    }
    return total;
  }
}
