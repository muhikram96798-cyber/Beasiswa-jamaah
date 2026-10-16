// App: BeasiswaJamaahApp
// Mendefinisikan MaterialApp dengan tema Material 3 hijau tenang,
// navigasi bawah 5 tab, dan routing dasar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/donatur_provider.dart';
import 'providers/kas_provider.dart';
import 'providers/pengaturan_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'Beasiswa Jamaah Tetap',
        debugShowCheckedModeBanner: false,
        locale: const Locale('id', 'ID'),
        theme: _buatTema(),
        home: const MainNavigationShell(),
      ),
    );
  }

  ThemeData _buatTema() {
    // Warna utama: hijau tenang (Material 3)
    const seedColor = Color(0xFF2E7D32); // Green 800

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      // Ukuran font cukup besar untuk pengurus yang awam teknologi
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 15),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // Card
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // Input
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Tombol utama
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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

  final List<Widget> _layar = const [
    BerandaScreen(),
    DonaturListScreen(),
    KasScreen(),
    AnakListScreen(),
    LaporanScreen(),
  ];

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
        onDestinationSelected: (i) => setState(() => _indexAktif = i),
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
