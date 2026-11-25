class ResumenCartera {
  final double capitalPrestado;
  final double totalPorCobrar;
  final double gananciaEsperada;
  final double totalCobrado;
  final int totalPrestamos;
  final int pendientes;
  final int cobrados;
  final int vencidos;

  ResumenCartera({
    required this.capitalPrestado,
    required this.totalPorCobrar,
    required this.gananciaEsperada,
    required this.totalCobrado,
    required this.totalPrestamos,
    required this.pendientes,
    required this.cobrados,
    required this.vencidos,
  });

  factory ResumenCartera.fromJson(Map<String, dynamic> json) {
    return ResumenCartera(
      capitalPrestado: (json['capitalPrestado'] as num?)?.toDouble() ?? 0.0,
      totalPorCobrar: (json['totalPorCobrar'] as num?)?.toDouble() ?? 0.0,
      gananciaEsperada: (json['gananciaEsperada'] as num?)?.toDouble() ?? 0.0,
      totalCobrado: (json['totalCobrado'] as num?)?.toDouble() ?? 0.0,
      totalPrestamos: (json['totalPrestamos'] as num?)?.toInt() ?? 0,
      pendientes: (json['pendientes'] as num?)?.toInt() ?? 0,
      cobrados: (json['cobrados'] as num?)?.toInt() ?? 0,
      vencidos: (json['vencidos'] as num?)?.toInt() ?? 0,
    );
  }
}
