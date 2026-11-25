import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/prestamo.dart';
import '../models/resumen_cartera.dart';
import 'storage_service.dart';

class PrestamoService {
  static Function()? onUnauthorized;

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  static void _handleResponseCode(int statusCode) {
    if (statusCode == 401) {
      StorageService.clearAuthData();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
  }

  static String _extractError(String body, int code) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'Error en la petición (código $code)';
  }

  static Future<List<Prestamo>> getPrestamos() async {
    final token = await StorageService.getToken();
    final response = await http.get(Uri.parse(ApiConfig.prestamos), headers: _headers(token));

    _handleResponseCode(response.statusCode);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Prestamo.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_extractError(response.body, response.statusCode));
  }

  static Future<ResumenCartera> getResumen() async {
    final token = await StorageService.getToken();
    final response = await http.get(Uri.parse(ApiConfig.prestamosResumen), headers: _headers(token));

    _handleResponseCode(response.statusCode);

    if (response.statusCode == 200) {
      return ResumenCartera.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractError(response.body, response.statusCode));
  }

  static Future<Prestamo> createPrestamo({
    required String cliente,
    required String dni,
    required double monto,
    required double interes,
    required String fechaVencimiento,
  }) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.prestamos),
      headers: _headers(token),
      body: jsonEncode({
        'cliente': cliente,
        'dni': dni,
        'monto': monto,
        'interes': interes,
        'fechaVencimiento': fechaVencimiento,
      }),
    );

    _handleResponseCode(response.statusCode);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Prestamo.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractError(response.body, response.statusCode));
  }

  static Future<Prestamo> updatePrestamo({
    required int id,
    String? cliente,
    String? dni,
    double? monto,
    double? interes,
    String? fechaVencimiento,
    bool? pagado,
  }) async {
    final token = await StorageService.getToken();
    final Map<String, dynamic> body = {};
    if (cliente != null) body['cliente'] = cliente;
    if (dni != null) body['dni'] = dni;
    if (monto != null) body['monto'] = monto;
    if (interes != null) body['interes'] = interes;
    if (fechaVencimiento != null) body['fechaVencimiento'] = fechaVencimiento;
    if (pagado != null) body['pagado'] = pagado;

    final response = await http.put(
      Uri.parse(ApiConfig.prestamoById(id)),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    _handleResponseCode(response.statusCode);

    if (response.statusCode == 200) {
      return Prestamo.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractError(response.body, response.statusCode));
  }

  static Future<void> deletePrestamo(int id) async {
    final token = await StorageService.getToken();
    final response = await http.delete(
      Uri.parse(ApiConfig.prestamoById(id)),
      headers: _headers(token),
    );

    _handleResponseCode(response.statusCode);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response.body, response.statusCode));
    }
  }
}
