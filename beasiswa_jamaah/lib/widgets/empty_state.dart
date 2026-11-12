// Widget: EmptyState
// Tampilan ketika daftar kosong. Dipakai di semua layar daftar.

import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData ikon;
  final String pesan;
  final String? subPesan;
  final Widget? tombol;

  const EmptyState({
    super.key,
    required this.ikon,
    required this.pesan,
    this.subPesan,
    this.tombol,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 64, color: tema.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            if (subPesan != null) ...[
              const SizedBox(height: 8),
              Text(
                subPesan!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.outlineVariant,
                ),
              ),
            ],
            if (tombol != null) ...[
              const SizedBox(height: 20),
              tombol!,
            ],
          ],
        ),
      ),
    );
  }
}
