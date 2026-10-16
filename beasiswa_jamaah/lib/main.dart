// Entry point aplikasi Beasiswa Jamaah Tetap
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi format tanggal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);
  runApp(const BeasiswaJamaahApp());
}
