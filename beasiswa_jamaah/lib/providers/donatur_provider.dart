// Provider: DonaturProvider
// Mengelola state daftar donatur, status pembayaran iuran per bulan (matriks),
// dan daftar donatur yang belum membayar bulan berjalan.

import 'package:flutter/foundation.dart';
import '../models/donatur.dart';
import '../models/iuran.dart';
import '../services/donatur_service.dart';

class DonaturProvider extends ChangeNotifier {
  final DonaturService _service;

  DonaturProvider({DonaturService? service})
      : _service = service ?? DonaturService();

  List<Donatur> _daftarDonatur = [];
  // Struktur: [donaturId][bulan] = Iuran
  final Map<int, Map<int, Iuran>> _matriksIuran = {};

  int _tahunAktif = DateTime.now().year;
  bool _loading = false;
  String? _pesanError;

  List<Donatur> get daftarDonatur => _daftarDonatur;
  Map<int, Map<int, Iuran>> get matriksIuran => _matriksIuran;
  int get tahunAktif => _tahunAktif;
  bool get loading => _loading;
  String? get pesanError => _pesanError;

  List<Donatur> get donaturAktif =>
      _daftarDonatur.where((d) => d.statusAktif).toList();

  List<Donatur> get donaturBerhenti =>
      _daftarDonatur.where((d) => !d.statusAktif).toList();

  int get totalDonatur => _daftarDonatur.length;
  int get totalDonaturAktif => donaturAktif.length;

  /// Memuat data donatur dan semua iuran pada tahun aktif
  Future<void> muatData({int? tahun}) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      if (tahun != null) {
        _tahunAktif = tahun;
      }
      _daftarDonatur = await _service.getSemuaDonatur();

      final listIuran = await _service.getIuranByTahun(_tahunAktif);
      _matriksIuran.clear();

      for (final iuran in listIuran) {
        _matriksIuran.putIfAbsent(iuran.donaturId, () => {})[iuran.bulan] =
            iuran;
      }
    } catch (e) {
      _pesanError = 'Gagal memuat data donatur: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cek apakah donatur sudah bayar pada bulan tertentu
  bool sudahBayar(int donaturId, int bulan) {
    return _matriksIuran[donaturId]?.containsKey(bulan) ?? false;
  }

  /// Ambil objek Iuran jika sudah bayar
  Iuran? getIuran(int donaturId, int bulan) {
    return _matriksIuran[donaturId]?[bulan];
  }

  /// Daftar donatur aktif yang belum membayar pada bulan tertentu (1-12)
  List<Donatur> getDonaturBelumBayar(int bulan) {
    return donaturAktif.where((d) => !sudahBayar(d.id!, bulan)).toList();
  }

  /// Daftar donatur aktif yang belum bayar bulan berjalan
  List<Donatur> get donaturBelumBayarBulanIni {
    final bulanSekarang = DateTime.now().month;
    return getDonaturBelumBayar(bulanSekarang);
  }

  /// Total penerimaan iuran yang sudah tercatat di tahun aktif
  int get totalPenerimaanTahunIni {
    int total = 0;
    for (final mapBulan in _matriksIuran.values) {
      for (final iuran in mapBulan.values) {
        total += iuran.nominal;
      }
    }
    return total;
  }

  // ─── Tindakan CRUD Donatur ────────────────────────────────────────────────

  Future<void> tambahDonatur(Donatur donatur) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.tambahDonatur(donatur);
      await muatData(tahun: _tahunAktif);
    } catch (e) {
      _pesanError = 'Gagal menambah donatur: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> perbaruiDonatur(Donatur donatur) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.updateDonatur(donatur);
      await muatData(tahun: _tahunAktif);
    } catch (e) {
      _pesanError = 'Gagal memperbarui donatur: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleStatusDonatur(Donatur donatur) async {
    final updated = donatur.copyWith(statusAktif: !donatur.statusAktif);
    await perbaruiDonatur(updated);
  }

  Future<void> hapusDonatur(int id) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.hapusDonatur(id);
      await muatData(tahun: _tahunAktif);
    } catch (e) {
      _pesanError = 'Gagal menghapus donatur: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─── Tindakan Iuran ───────────────────────────────────────────────────────

  Future<void> catatIuran({
    required int donaturId,
    required int bulan,
    required int nominal,
    required String tanggalBayar,
    int? tahun,
  }) async {
    final targetTahun = tahun ?? _tahunAktif;
    _tahunAktif = targetTahun;
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.catatIuran(
        donaturId: donaturId,
        bulan: bulan,
        tahunAjaran: targetTahun,
        nominal: nominal,
        tanggalBayar: tanggalBayar,
      );
      await muatData(tahun: targetTahun);
    } catch (e) {
      _pesanError = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> batalkanIuran(int iuranId) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.batalIuran(iuranId);
      await muatData(tahun: _tahunAktif);
    } catch (e) {
      _pesanError = 'Gagal membatalkan iuran: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
