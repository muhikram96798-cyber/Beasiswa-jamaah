// Provider: KasProvider
// Mengelola state kas bersama: pemasukan, pengeluaran, saldo otomatis,
// dan pemisahan pos dana cadangan 10%.

import 'package:flutter/foundation.dart';
import '../models/transaksi_kas.dart';
import '../services/kas_service.dart';

class KasProvider extends ChangeNotifier {
  final KasService _service;

  KasProvider({KasService? service}) : _service = service ?? KasService();

  List<TransaksiKas> _daftarTransaksi = [];
  RingkasanKas _ringkasan = const RingkasanKas(
    totalPemasukan: 0,
    totalPengeluaran: 0,
    totalSaldo: 0,
    danaCadanganWajib: 0,
    danaCadanganTerpakai: 0,
    danaCadanganTersedia: 0,
    saldoBisaDipakai: 0,
  );

  bool _loading = false;
  String? _pesanError;

  List<TransaksiKas> get daftarTransaksi => _daftarTransaksi;
  RingkasanKas get ringkasan => _ringkasan;
  bool get loading => _loading;
  String? get pesanError => _pesanError;

  List<TransaksiKas> get daftarPemasukan => _daftarTransaksi
      .where((t) => t.tipe == TipeTransaksi.masuk)
      .toList();

  List<TransaksiKas> get daftarPengeluaran => _daftarTransaksi
      .where((t) => t.tipe == TipeTransaksi.keluar)
      .toList();

  /// Muat riwayat transaksi dan hitung ulang saldo serta dana cadangan
  Future<void> muatData({int persentaseCadangan = 10}) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      _daftarTransaksi = await _service.getSemuaTransaksi();
      _ringkasan = RingkasanKas.hitung(
        _daftarTransaksi,
        persentaseCadangan: persentaseCadangan,
      );
    } catch (e) {
      _pesanError = 'Gagal memuat kas: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Tambah transaksi kas baru
  Future<void> tambahTransaksi(
    TransaksiKas transaksi, {
    int persentaseCadangan = 10,
  }) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.tambahTransaksi(
        transaksi,
        persentaseCadangan: persentaseCadangan,
      );
      await muatData(persentaseCadangan: persentaseCadangan);
    } catch (e) {
      _pesanError = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Hapus transaksi kas
  Future<void> hapusTransaksi(
    int id, {
    int persentaseCadangan = 10,
  }) async {
    _loading = true;
    _pesanError = null;
    notifyListeners();

    try {
      await _service.hapusTransaksi(id);
      await muatData(persentaseCadangan: persentaseCadangan);
    } catch (e) {
      _pesanError = 'Gagal menghapus transaksi: ${e.toString()}';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
