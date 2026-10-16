// Layar: Kas (placeholder TAHAP 1)
// Pencatatan kas dan saldo akan diimplementasi di TAHAP 3.

import 'package:flutter/material.dart';

class KasScreen extends StatelessWidget {
  const KasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kas Bersama')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Kas Bersama',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Saldo, pemasukan, dan pengeluaran\nakan tersedia di tahap berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
