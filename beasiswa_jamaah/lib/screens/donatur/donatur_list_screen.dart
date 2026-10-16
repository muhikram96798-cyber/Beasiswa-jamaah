// Layar: Donatur (placeholder TAHAP 1)
// CRUD donatur dan pencatatan iuran akan diimplementasi di TAHAP 2.

import 'package:flutter/material.dart';

class DonaturListScreen extends StatelessWidget {
  const DonaturListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donatur')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Donatur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Daftar donatur dan pencatatan iuran\nakan tersedia di tahap berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
