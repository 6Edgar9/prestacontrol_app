import 'package:flutter/material.dart';

class TokenExpirationBanner extends StatelessWidget {
  final DateTime? expirationDate;

  const TokenExpirationBanner({super.key, required this.expirationDate});

  @override
  Widget build(BuildContext context) {
    if (expirationDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final diferencia = expirationDate!.difference(now);

    if (diferencia.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.red.shade100,
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Su token ha vencido. Cierre sesión e inicie de nuevo.',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (diferencia.inHours < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aviso de sesión: el token JWT expira en ${diferencia.inMinutes} minutos.',
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
