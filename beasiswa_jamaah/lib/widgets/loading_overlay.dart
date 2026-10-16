// Widget: LoadingOverlay
// Tampilan loading yang digunakan di seluruh aplikasi.

import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool sedangMemuat;
  final Widget child;
  final String? pesan;

  const LoadingOverlay({
    super.key,
    required this.sedangMemuat,
    required this.child,
    this.pesan,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (sedangMemuat)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (pesan != null) ...[
                        const SizedBox(height: 16),
                        Text(pesan!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
