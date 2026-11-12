// Service: PenyaluranService
// Mengelola penyaluran bantuan perlengkapan dan uang saku anak.
// Setiap penyaluran otomatis memotong kas bersama (pengeluaran kas).

import '../models/penyaluran.dart';
import '../models/transaksi_kas.dart';
import 'database_service.dart';
import 'kas_service.dart';

class PenyaluranService {
  final DatabaseService _dbService;

  PenyaluranService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  /// Catat penyaluran bantuan baru dan otomatis catat pengeluaran di kas.
  /// Memeriksa saldo kas agar tidak menjadi negatif.
  Future<int> catatPenyaluran({
    required Penyaluran penyaluran,
    required String namaAnak,
    bool gunakanCadangan = false,
    String? alasanCadangan,
    int persentaseCadangan = 10,
  }) async {
    final db = await _dbService.database;

    return await db.transaction<int>((txn) async {
      // 1. Validasi saldo kas saat ini
      final mapsKas = await txn.query('transaksi_kas');
      final listTransaksi =
          mapsKas.map((e) => TransaksiKas.fromMap(e)).toList();
      final ringkasan = RingkasanKas.hitung(
        listTransaksi,
        persentaseCadangan: persentaseCadangan,
      );

      // Total kas tidak boleh negatif sama sekali
      if (penyaluran.nominal > ringkasan.totalSaldo) {
        throw StateError(
          'Saldo total kas tidak mencukupi untuk penyaluran ini. '
          'Dibutuhkan: ${penyaluran.nominal}, total kas saat ini: ${ringkasan.totalSaldo}.',
        );
      }

      // Jika melebihi saldo yang bisa dipakai, harus menggunakan cadangan dengan konfirmasi
      if (penyaluran.nominal > ringkasan.saldoBisaDipakai && !gunakanCadangan) {
        throw StateError(
          'Penyaluran melebihi saldo yang bisa dipakai (${ringkasan.saldoBisaDipakai}). '
          'Memerlukan persetujuan penggunaan dana cadangan.',
        );
      }

      // 2. Buat keterangan transaksi kas otomatis
      final String ketKas;
      final KategoriTransaksi kategoriKas;

      if (penyaluran.jenis == JenisPenyaluran.uangSaku) {
        kategoriKas = KategoriTransaksi.uangSaku;
        final detailKet = penyaluran.keterangan.isNotEmpty ? ' (${penyaluran.keterangan})' : '';
        ketKas =
            'Uang Saku ($namaAnak) - Penerima: ${penyaluran.penerima ?? 'Wali/Ortu'}$detailKet';
      } else {
        kategoriKas = KategoriTransaksi.perlengkapan;
        final detailKet = penyaluran.keterangan.isNotEmpty ? ' (${penyaluran.keterangan})' : '';
        ketKas =
            'Perlengkapan [${penyaluran.jenis.label}] ($namaAnak) - Toko: ${penyaluran.penerima ?? '-'}$detailKet';
      }

      final transaksiKas = TransaksiKas(
        tanggal: penyaluran.tanggal,
        tipe: TipeTransaksi.keluar,
        kategori: kategoriKas,
        keterangan: ketKas,
        nominal: penyaluran.nominal,
        menggunakanCadangan: gunakanCadangan,
      );

      final transaksiId = await txn.insert(
        'transaksi_kas',
        transaksiKas.toMap(),
      );

      // 3. Simpan data penyaluran dengan relasi ke transaksi_kas
      final penyaluranData = penyaluran.copyWith(transaksiKasId: transaksiId);
      final penyaluranId = await txn.insert(
        'penyaluran',
        penyaluranData.toMap(),
      );

      // 4. Update transaksi_kas dengan sumber_id = penyaluranId untuk integritas 2 arah
      await txn.update(
        'transaksi_kas',
        {'sumber_id': penyaluranId},
        where: 'id = ?',
        whereArgs: [transaksiId],
      );

      return penyaluranId;
    });
  }

  /// Hapus penyaluran dan otomatis batalkan pengeluaran kas terkait
  Future<void> hapusPenyaluran(int penyaluranId) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // Ambil transaksi kas ID terkait
      final maps = await txn.query(
        'penyaluran',
        where: 'id = ?',
        whereArgs: [penyaluranId],
        limit: 1,
      );

      final transaksiKasId =
          maps.isNotEmpty ? maps.first['transaksi_kas_id'] as int? : null;

      // 1. Hapus penyaluran terlebih dahulu agar foreign key constraint terlepas
      await txn.delete(
        'penyaluran',
        where: 'id = ?',
        whereArgs: [penyaluranId],
      );

      // 2. Hapus transaksi kas terkait
      if (transaksiKasId != null) {
        await txn.delete(
          'transaksi_kas',
          where: 'id = ?',
          whereArgs: [transaksiKasId],
        );
      }
    });
  }

  /// Batalkan penyaluran dana (salah catat/salah input) dan kembalikan pengeluaran kas terkait
  Future<void> batalkanPenyaluran(int penyaluranId) async {
    await hapusPenyaluran(penyaluranId);
  }

  /// Ambil riwayat penyaluran untuk anak tertentu
  Future<List<Penyaluran>> getPenyaluranByAnak(int anakId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penyaluran',
      where: 'anak_id = ?',
      whereArgs: [anakId],
      orderBy: 'tanggal DESC, id DESC',
    );
    return maps.map((e) => Penyaluran.fromMap(e)).toList();
  }

  /// Ambil semua penyaluran
  Future<List<Penyaluran>> getSemuaPenyaluran() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penyaluran',
      orderBy: 'tanggal DESC, id DESC',
    );
    return maps.map((e) => Penyaluran.fromMap(e)).toList();
  }

  /// Total nominal yang sudah disalurkan ke satu anak
  Future<int> getTotalPenyaluranByAnak(int anakId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT SUM(nominal) as total FROM penyaluran WHERE anak_id = ?',
      [anakId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Ambil peta total penyaluran seluruh anak (anak_id -> total)
  Future<Map<int, int>> getPetaTotalPenyaluranPerAnak() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT anak_id, SUM(nominal) as total FROM penyaluran GROUP BY anak_id',
    );
    final map = <int, int>{};
    for (final row in result) {
      final anakId = row['anak_id'] as int?;
      final total = row['total'] as int?;
      if (anakId != null && total != null) {
        map[anakId] = total;
      }
    }
    return map;
  }
}
