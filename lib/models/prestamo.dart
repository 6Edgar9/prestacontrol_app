class Prestamo {
  final int id;
  final String cliente;
  final String dni;
  final double monto;
  final double interes;
  final double montoInteres;
  final double totalCobrar;
  final String fechaPrestamo;
  final String fechaVencimiento;
  final bool pagado;
  final bool vencido;

  Prestamo({
    required this.id,
    required this.cliente,
    required this.dni,
    required this.monto,
    required this.interes,
    required this.montoInteres,
    required this.totalCobrar,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    required this.pagado,
    required this.vencido,
  });

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    return Prestamo(
      id: json['id'] as int? ?? 0,
      cliente: json['cliente'] as String? ?? '',
      dni: json['dni'] as String? ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      interes: (json['interes'] as num?)?.toDouble() ?? 0.0,
      montoInteres: (json['montoInteres'] as num?)?.toDouble() ?? 0.0,
      totalCobrar: (json['totalCobrar'] as num?)?.toDouble() ?? 0.0,
      fechaPrestamo: json['fechaPrestamo'] as String? ?? '',
      fechaVencimiento: json['fechaVencimiento'] as String? ?? '',
      pagado: json['pagado'] as bool? ?? false,
      vencido: json['vencido'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJsonForCreate() => {
        'cliente': cliente,
        'dni': dni,
        'monto': monto,
        'interes': interes,
        'fechaVencimiento': fechaVencimiento,
      };

  Map<String, dynamic> toJsonForUpdate({bool? marcarPagado}) {
    final map = <String, dynamic>{
      'cliente': cliente,
      'dni': dni,
      'monto': monto,
      'interes': interes,
      'fechaVencimiento': fechaVencimiento,
    };
    if (marcarPagado != null) {
      map['pagado'] = marcarPagado;
    }
    return map;
  }
}
