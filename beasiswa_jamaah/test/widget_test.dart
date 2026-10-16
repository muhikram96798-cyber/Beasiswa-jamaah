// Test widget dasar — memastikan antarmuka utama dapat dirender.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beasiswa_jamaah/app.dart';

void main() {
  testWidgets('App dapat dirender dengan navigasi 5 tab', (WidgetTester tester) async {
    await tester.pumpWidget(const BeasiswaJamaahApp());
    await tester.pumpAndSettle();

    // Verifikasi navigasi bawah (NavigationBar) tampil
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verifikasi 5 ikon navigasi ada
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
