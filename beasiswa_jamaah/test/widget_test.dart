// Test widget dasar — hanya memastikan app bisa dirender tanpa crash.
// Pengujian logika bisnis ada di file test terpisah per modul.

import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/app.dart';

void main() {
  testWidgets('App dapat dirender tanpa crash', (WidgetTester tester) async {
    await tester.pumpWidget(const BeasiswaJamaahApp());
    // Verifikasi navigasi bawah tampil dengan 5 tab
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Donatur'), findsOneWidget);
    expect(find.text('Kas'), findsOneWidget);
    expect(find.text('Anak'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
}
