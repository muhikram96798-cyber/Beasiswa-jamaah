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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 72, color: tema.colorScheme.outlineVariant),
            const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              tombol!,
            ],
          ],
        ),
      ),
    );
  }
}
