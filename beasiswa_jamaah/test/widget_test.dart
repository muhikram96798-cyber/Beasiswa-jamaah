// Test widget dasar — memastikan antarmuka utama dapat dirender.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/app.dart';

void main() {
  testWidgets('App dapat dirender dengan navigasi 5 tab', (WidgetTester tester) async {
    await tester.pumpWidget(const BeasiswaJamaahApp());
    await tester.pumpAndSettle();

    // Verifikasi navigasi bawah (NavigationBar) tampil dengan 5 destinasi tab
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    // Verifikasi 5 label navigasi utama ada di antarmuka
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Donatur'), findsWidgets);
    expect(find.text('Kas'), findsWidgets);
    expect(find.text('Anak'), findsWidgets);
    expect(find.text('Laporan'), findsWidgets);
  });
}
