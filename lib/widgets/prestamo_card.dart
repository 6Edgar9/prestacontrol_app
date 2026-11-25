import 'package:flutter/material.dart';
import '../models/prestamo.dart';

class PrestamoCard extends StatelessWidget {
  final Prestamo prestamo;
  final VoidCallback onTogglePago;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PrestamoCard({
    super.key,
    required this.prestamo,
    required this.onTogglePago,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esVencido = prestamo.vencido;
    final cardBg = esVencido ? Colors.red.shade50.withAlpha(120) : Colors.white;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esVencido ? Colors.red.shade700 : Colors.grey.shade300,
          width: esVencido ? 1.8 : 0.8,
        ),
      ),
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prestamo.cliente,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'DNI: ${prestamo.dni}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (esVencido)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VENCIDO',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (prestamo.pagado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'COBRADO',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PENDIENTE',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto Prestado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('S/ ${prestamo.monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Interés', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('${prestamo.interes.toStringAsFixed(1)}% (+S/ ${prestamo.montoInteres.toStringAsFixed(2)})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total a Cobrar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      'S/ ${prestamo.totalCobrar.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: esVencido ? Colors.red : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${prestamo.fechaVencimiento}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: esVencido ? FontWeight.bold : FontWeight.normal,
                    color: esVencido ? Colors.red.shade900 : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    prestamo.pagado ? Icons.undo : Icons.check_circle_outline,
                    color: prestamo.pagado ? Colors.orange : Colors.green,
                  ),
                  tooltip: prestamo.pagado ? 'Marcar pendiente' : 'Marcar cobrado',
                  onPressed: onTogglePago,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
