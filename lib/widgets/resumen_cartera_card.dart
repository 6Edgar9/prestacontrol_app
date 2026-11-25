import 'package:flutter/material.dart';
import '../models/resumen_cartera.dart';

class ResumenCarteraCard extends StatelessWidget {
  final ResumenCartera resumen;

  const ResumenCarteraCard({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen de Cartera',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${resumen.totalPrestamos} Préstamos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _item('Capital Prestado', 'S/ ${resumen.capitalPrestado.toStringAsFixed(2)}', Colors.blue.shade700),
                ),
                Expanded(
                  child: _item('Total por Cobrar', 'S/ ${resumen.totalPorCobrar.toStringAsFixed(2)}', Colors.orange.shade800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _item('Ganancia Esperada', 'S/ ${resumen.gananciaEsperada.toStringAsFixed(2)}', Colors.green.shade700),
                ),
                Expanded(
                  child: _item('Total Cobrado', 'S/ ${resumen.totalCobrado.toStringAsFixed(2)}', Colors.purple.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
