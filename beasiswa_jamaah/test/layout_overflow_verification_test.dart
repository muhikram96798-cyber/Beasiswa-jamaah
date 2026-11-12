import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/app.dart';
import 'package:beasiswa_jamaah/screens/pengaturan/pengaturan_screen.dart';

void main() {
  testWidgets('Semua 5 tab navigasi bebas dari RenderFlex overflow pada layar sempit (360x640)',
      (WidgetTester tester) async {
    // Set ukuran layar sempit standar Android (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const BeasiswaJamaahApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Beasiswa Jamaah'), findsWidgets);

    // 2. Tab Donatur
    await tester.tap(find.text('Donatur'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3. Tab Kas
    await tester.tap(find.text('Kas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 4. Tab Anak
    await tester.tap(find.text('Anak'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 5. Tab Laporan
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PengaturanScreen dapat dibuka dan dirender tanpa exception',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const BeasiswaJamaahApp());
    await tester.pumpAndSettle();

    // Buka Pengaturan via icon button pengaturan di Beranda
    final tombolPengaturan = find.byTooltip('Pengaturan & Keamanan');
    expect(tombolPengaturan, findsOneWidget);
    await tester.tap(tombolPengaturan);
    await tester.pumpAndSettle();

    expect(find.byType(PengaturanScreen), findsOneWidget);
    expect(find.text('Keamanan Data & PIN Pengurus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
