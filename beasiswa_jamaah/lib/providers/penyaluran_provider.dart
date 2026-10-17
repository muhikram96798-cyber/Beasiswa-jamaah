// Provider: PenyaluranProvider
// State management untuk penyaluran bantuan perlengkapan dan uang saku anak.

import 'package:flutter/foundation.dart';
import '../models/penyaluran.dart';
import '../services/penyaluran_service.dart';

class PenyaluranProvider with ChangeNotifier {
  final PenyaluranService _service;

  PenyaluranProvider({PenyaluranService? service})
      : _service = service ?? PenyaluranService() {
    muatData();
  }

  List<Penyaluran> _daftarSemuaPenyaluran = [];
  Map<int, int> _petaTotalPerAnak = {};
  final Map<int, List<Penyaluran>> _petaRiwayatAnak = {};
  bool _memuat = false;
  String? _pesanError;

  List<Penyaluran> get daftarSemuaPenyaluran => _daftarSemuaPenyaluran;
  Map<int, int> get petaTotalPerAnak => _petaTotalPerAnak;
  bool get memuat => _memuat;
  String? get pesanError => _pesanError;

  /// Total yang sudah disalurkan ke satu anak
  int getTotalPenyaluran(int anakId) {
    return _petaTotalPerAnak[anakId] ?? 0;
  }

  /// Total nominal seluruh penyaluran yang telah dilakukan ke seluruh anak
  int get totalPenyaluranSemua =>
      _petaTotalPerAnak.values.fold(0, (sum, val) => sum + val);

  /// Daftar riwayat penyaluran untuk anak tertentu
  List<Penyaluran> getRiwayatAnak(int anakId) {
    return _petaRiwayatAnak[anakId] ?? [];
  }

  /// Hitung persentase pemenuhan kebutuhan dana per anak
  double hitungPersentasePemenuhan({
    required int anakId,
    required int kebutuhanDanaBersih,
  }) {
    if (kebutuhanDanaBersih <= 0) return 100.0;
    final totalTersalurkan = getTotalPenyaluran(anakId);
    final persen = (totalTersalurkan / kebutuhanDanaBersih) * 100.0;
    return persen;
  }

  /// Muat semua data penyaluran dan peta total per anak
  Future<void> muatData() async {
    _memuat = true;
    _pesanError = null;
    notifyListeners();

    try {
      _daftarSemuaPenyaluran = await _service.getSemuaPenyaluran();
      _petaTotalPerAnak = await _service.getPetaTotalPenyaluranPerAnak();
      
      // Update juga riwayat per anak
      _petaRiwayatAnak.clear();
      for (final p in _daftarSemuaPenyaluran) {
        _petaRiwayatAnak.putIfAbsent(p.anakId, () => []).add(p);
      }
    } catch (e) {
      _pesanError = 'Gagal memuat data penyaluran: ${e.toString()}';
    } finally {
      _memuat = false;
      notifyListeners();
    }
  }

  /// Muat riwayat spesifik untuk anak tertentu
  Future<List<Penyaluran>> muatPenyaluranAnak(int anakId) async {
    try {
      final list = await _service.getPenyaluranByAnak(anakId);
      _petaRiwayatAnak[anakId] = list;
      
      final total = await _service.getTotalPenyaluranByAnak(anakId);
      _petaTotalPerAnak[anakId] = total;
      
      notifyListeners();
      return list;
    } catch (e) {
      _pesanError = 'Gagal memuat penyaluran anak: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Catat penyaluran baru
  Future<int> catatPenyaluran({
    required Penyaluran penyaluran,
    required String namaAnak,
    bool gunakanCadangan = false,
    String? alasanCadangan,
    int persentaseCadangan = 10,
  }) async {
    _memuat = true;
    _pesanError = null;
    notifyListeners();

    try {
      final id = await _service.catatPenyaluran(
        penyaluran: penyaluran,
        namaAnak: namaAnak,
        gunakanCadangan: gunakanCadangan,
        alasanCadangan: alasanCadangan,
        persentaseCadangan: persentaseCadangan,
      );

      await muatData();
      return id;
    } catch (e) {
      _pesanError = e.toString();
      _memuat = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Hapus riwayat penyaluran
  Future<void> hapusPenyaluran(int penyaluranId, int anakId) async {
    _memuat = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.hapusPenyaluran(penyaluranId);
      await muatData();
    } catch (e) {
      _pesanError = 'Gagal menghapus penyaluran: ${e.toString()}';
      _memuat = false;
      notifyListeners();
      rethrow;
    }
  }
}
