// Service: BackupService
// Menangani pembuatan cadangan (ekspor file .db) dan pemulihan data (restore file .db)
// Menjamin keamanan data pengurus dan integritas file SQLite.

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class BackupService {
  static const String _dbName = 'beasiswa_jamaah.db';

  /// Lokasi file database aktif di perangkat
  static Future<String> getDatabasePath() async {
    final dir = await getDatabasesPath();
    return join(dir, _dbName);
  }

  /// Ekspor cadangan file database SQLite dan bagikan via Share Sheet
  static Future<File> eksporCadangan() async {
    // 1. Pastikan semua transaksi WAL ditulis ke file utama
    final db = await DatabaseService.instance.database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('File database utama tidak ditemukan.');
    }

    // 2. Buat file salinan di folder sementara dengan timestamp
    final tempDir = await getTemporaryDirectory();
    final formatWaktu = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final namaBackup = 'Backup_Beasiswa_Jamaah_$formatWaktu.db';
    final targetFile = File(join(tempDir.path, namaBackup));

    await dbFile.copy(targetFile.path);

    // 3. Bagikan file menggunakan Share Sheet bawaan OS (WA/Drive/Email/Simpan ke File)
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            targetFile.path,
            mimeType: 'application/x-sqlite3',
            name: namaBackup,
          ),
        ],
        text: 'File Cadangan Database Beasiswa Jamaah Tetap ($formatWaktu)',
        subject: namaBackup,
      ),
    );

    return targetFile;
  }

  /// Pulihkan database dari file cadangan yang dipilih pengurus
  static Future<bool> pulihkanCadangan() async {
    // 1. Buka File Picker
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isEmpty) {
      return false; // Pengguna membatalkan
    }

    final pathDipilih = files.first.path;
    if (pathDipilih == null) {
      throw Exception('Path file yang dipilih tidak dapat diakses.');
    }

    final fileSumber = File(pathDipilih);
    if (!await fileSumber.exists()) {
      throw Exception('File yang dipilih tidak ditemukan.');
    }

    // 2. Validasi Header SQLite ("SQLite format 3")
    final ukuran = await fileSumber.length();
    if (ukuran < 16) {
      throw Exception('Ukuran file terlalu kecil dan bukan database yang sah.');
    }
    final bytes = await fileSumber.openRead(0, 16).first;
    const headerSqlite = [
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00
    ];
    if (bytes.length < 16) {
      throw Exception('Ukuran file terlalu kecil dan bukan database yang sah.');
    }
    for (int i = 0; i < 16; i++) {
      if (bytes[i] != headerSqlite[i]) {
        throw Exception(
          'File yang dipilih bukan cadangan database SQLite yang valid.',
        );
      }
    }

    // 3. Validasi Keberadaan Tabel Utama Beasiswa Jamaah
    Database? dbUji;
    try {
      dbUji = await openReadOnlyDatabase(pathDipilih);
      final tabel = await dbUji.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('pengaturan', 'anak', 'donatur', 'transaksi_kas')",
      );
      if (tabel.length < 4) {
        throw Exception(
          'File SQLite ini bukan cadangan Beasiswa Jamaah (struktur tabel tidak lengkap).',
        );
      }
    } finally {
      await dbUji?.close();
    }

    // 4. Tutup koneksi database aktif
    await DatabaseService.instance.close();

    final targetPath = await getDatabasePath();

    // 5. Hapus file WAL dan SHM lama jika ada untuk mencegah konflik
    final walFile = File('$targetPath-wal');
    if (await walFile.exists()) await walFile.delete();
    final shmFile = File('$targetPath-shm');
    if (await shmFile.exists()) await shmFile.delete();

    // 5. Salin dan timpa database utama dengan file cadangan
    await fileSumber.copy(targetPath);

    // 6. Buka kembali database untuk memastikan koneksi pulih
    await DatabaseService.instance.database;

    return true;
  }
}
