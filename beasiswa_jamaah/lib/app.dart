// App: BeasiswaJamaahApp
// Mendefinisikan MaterialApp dengan tema Material 3 hijau tenang,
// navigasi bawah 5 tab, dan routing dasar.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/anak_provider.dart';
import 'providers/donatur_provider.dart';
import 'providers/kas_provider.dart';
import 'providers/pengaturan_provider.dart';
import 'providers/penyaluran_provider.dart';
import 'screens/beranda/beranda_screen.dart';
import 'screens/donatur/donatur_list_screen.dart';
import 'screens/kas/kas_screen.dart';
import 'screens/anak/anak_list_screen.dart';
import 'screens/laporan/laporan_screen.dart';

class BeasiswaJamaahApp extends StatelessWidget {
  const BeasiswaJamaahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PengaturanProvider()),
        ChangeNotifierProvider(create: (_) => DonaturProvider()),
        ChangeNotifierProvider(create: (_) => KasProvider()),
        ChangeNotifierProvider(create: (_) => AnakProvider()),
        ChangeNotifierProvider(create: (_) => PenyaluranProvider()),
      ],
      child: MaterialApp(
        title: 'Beasiswa Jamaah Tetap',
        debugShowCheckedModeBanner: false,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buatTema(),
        home: const MainNavigationShell(),
      ),
    );
  }

  ThemeData _buatTema() {
    // Warna utama: Hijau Emerald Islami yang ramah, bersih, dan berwibawa
    const primaryGreen = Color(0xFF166534); // Forest Emerald Green
    const primaryLight = Color(0xFFDCFCE7); // Soft Mint Light
    const amberAccent = Color(0xFFD97706); // Warm Amber Gold

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: const Color(0xFF14532D),
        secondary: const Color(0xFF0F766E),
        tertiary: amberAccent,
        surface: const Color(0xFFF8FAFC),
        surfaceContainerHighest: const Color(0xFFEEF2F6),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F8F6),
      // Ukuran font ramah untuk pengurus DKM yang awam teknologi
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
        bodyMedium: TextStyle(fontSize: 15, color: Color(0xFF334155)),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      // AppBar bernuansa hijau kokoh dengan teks putih beresolusi tinggi
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      // Card modern dengan lekukan halus dan bayangan lembut
      cardTheme: CardThemeData(
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      // Navigasi bawah modern Material 3
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black12,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      // Input form yang ramah dan jelas
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Tombol utama
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─── Shell navigasi bawah ─────────────────────────────────────────────────

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _indexAktif = 0;

  late final List<Widget> _layar = [
    BerandaScreen(onPindahTab: _pindahKeTab),
    const DonaturListScreen(),
    const KasScreen(),
    const AnakListScreen(),
    const LaporanScreen(),
  ];

  void _pindahKeTab(int index) {
    setState(() => _indexAktif = index);
    if (!mounted) return;
    final p = context.read<PengaturanProvider>();
    switch (index) {
      case 0: // Beranda
        context.read<KasProvider>().muatData(persentaseCadangan: p.persentaseCadangan);
        context.read<DonaturProvider>().muatData(tahun: p.tahunAjaranAktif);
        context.read<AnakProvider>().muatData();
        context.read<PenyaluranProvider>().muatData();
        break;
      case 1: // Donatur
        context.read<DonaturProvider>().muatData(tahun: p.tahunAjaranAktif);
        break;
      case 2: // Kas
        context.read<KasProvider>().muatData(persentaseCadangan: p.persentaseCadangan);
        break;
      case 3: // Anak
        context.read<AnakProvider>().muatData();
        context.read<PenyaluranProvider>().muatData();
        break;
      case 4: // Laporan
        context.read<DonaturProvider>().muatData(tahun: p.tahunAjaranAktif);
        context.read<KasProvider>().muatData(persentaseCadangan: p.persentaseCadangan);
        context.read<AnakProvider>().muatData();
        context.read<PenyaluranProvider>().muatData();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // Muat pengaturan saat aplikasi pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PengaturanProvider>().muat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indexAktif,
        children: _layar,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexAktif,
        onDestinationSelected: _pindahKeTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Donatur',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Kas',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Anak',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
