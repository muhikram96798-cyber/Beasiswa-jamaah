// Layar: Anak (placeholder TAHAP 1)
// CRUD anak penerima dan seleksi akan diimplementasi di TAHAP 4.

import 'package:flutter/material.dart';

class AnakListScreen extends StatelessWidget {
  const AnakListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anak Penerima')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Anak Penerima',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Daftar anak penerima beasiswa\nakan tersedia di tahap berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
