// Service: DatabaseService
// Singleton yang mengelola koneksi SQLite dan migrasi skema.
// Versi database: 1

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/pengaturan.dart';

class DatabaseService {
  static const String _dbName = 'beasiswa_jamaah.db';
  static const int _dbVersion = 3;

  // Singleton
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Aktifkan foreign key support
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  // ─── Migrasi Database ─────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesV1(db);
    await _seedPengaturan(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE anak ADD COLUMN buruh_tani INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE donatur ADD COLUMN nomor_telepon TEXT',
        );
      } catch (_) {}
    }
  }

  Future<void> _createTablesV1(Database db) async {
    // Tabel pengaturan (key-value)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pengaturan (
        kunci TEXT PRIMARY KEY,
        nilai TEXT NOT NULL
      )
    ''');

    // Tabel donatur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS donatur (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_keluarga TEXT NOT NULL,
        nomor_telepon TEXT,
        nominal_iuran INTEGER NOT NULL,
        status_aktif INTEGER NOT NULL DEFAULT 1,
        tanggal_daftar TEXT NOT NULL,
        keterangan TEXT
      )
    ''');

    // Tabel transaksi_kas (dibuat sebelum iuran dan penyaluran karena jadi FK)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaksi_kas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        tipe TEXT NOT NULL,
        kategori TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        sumber_id INTEGER,
        menggunakan_cadangan INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabel iuran
    await db.execute('''
      CREATE TABLE IF NOT EXISTS iuran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        donatur_id INTEGER NOT NULL REFERENCES donatur(id) ON DELETE CASCADE,
        bulan INTEGER NOT NULL,
        tahun_ajaran INTEGER NOT NULL,
        nominal INTEGER NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        transaksi_kas_id INTEGER REFERENCES transaksi_kas(id),
        UNIQUE(donatur_id, bulan, tahun_ajaran)
      )
    ''');

    // Tabel anak
    await db.execute('''
      CREATE TABLE IF NOT EXISTS anak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_anak TEXT NOT NULL UNIQUE,
        nama_lengkap TEXT NOT NULL,
        nama_samaran TEXT NOT NULL,
        jenjang TEXT NOT NULL,
        kelas INTEGER NOT NULL,
        status_yatim TEXT NOT NULL,
        jumlah_saudara INTEGER NOT NULL,
        kondisi_ekonomi TEXT NOT NULL,
        status_pip TEXT NOT NULL,
        buruh_tani INTEGER NOT NULL DEFAULT 0,
        nama_wali TEXT,
        tanggal_masuk TEXT NOT NULL,
        aktif INTEGER NOT NULL DEFAULT 1,
        keterangan TEXT
      )
    ''');

    // Tabel penyaluran
    await db.execute('''
      CREATE TABLE IF NOT EXISTS penyaluran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anak_id INTEGER NOT NULL REFERENCES anak(id) ON DELETE CASCADE,
        tanggal TEXT NOT NULL,
        jenis TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        penerima TEXT,
        transaksi_kas_id INTEGER REFERENCES transaksi_kas(id)
      )
    ''');

    // Indeks untuk performa query
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iuran_donatur ON iuran(donatur_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iuran_tahun_bulan ON iuran(tahun_ajaran, bulan)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal ON transaksi_kas(tanggal)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_penyaluran_anak ON penyaluran(anak_id)',
    );
  }

  /// Isi nilai default pengaturan (hanya jika kunci belum ada)
  Future<void> _seedPengaturan(Database db) async {
    final batch = db.batch();
    PengaturanKey.defaults.forEach((kunci, nilai) {
      batch.insert(
        'pengaturan',
        {'kunci': kunci, 'nilai': nilai},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
    await batch.commit(noResult: true);
  }

  // ─── Helper umum ──────────────────────────────────────────────────────────

  /// Reset database (hanya untuk keperluan test/dev)
  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = OFF');
    for (final tabel in [
      'penyaluran',
      'iuran',
      'transaksi_kas',
      'anak',
      'donatur',
      'pengaturan',
    ]) {
      await db.delete(tabel);
    }
    await db.execute('PRAGMA foreign_keys = ON');
    await _seedPengaturan(db);
  }

  /// Tutup koneksi (biasanya tidak perlu dipanggil manual)
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
