import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/prestamo.dart';
import '../models/resumen_cartera.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Function()? onUnauthorized;

  static Map<String, String> _headers([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static void _check401(int statusCode) {
    if (statusCode == 401) {
      StorageService.clearAuthData();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
  }

  static String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('message') && decoded['message'] != null) {
          return decoded['message'].toString();
        }
        if (decoded.containsKey('error') && decoded['error'] != null) {
          return decoded['error'].toString();
        }
      }
    } catch (_) {}
    return 'Error del servidor (código $statusCode)';
  }

  // --- AUTENTICACIÓN ---

  static Future<AuthResponse> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.authRegister);
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final auth = AuthResponse.fromJson(data);
      await StorageService.saveAuthData(
        token: auth.token,
        email: auth.email,
        name: auth.nombre,
      );
      return auth;
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.authLogin);
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final auth = AuthResponse.fromJson(data);
      await StorageService.saveAuthData(
        token: auth.token,
        email: auth.email,
        name: auth.nombre,
      );
      return auth;
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<void> logout() async {
    await StorageService.clearAuthData();
    if (onUnauthorized != null) {
      onUnauthorized!();
    }
  }

  // --- PRÉSTAMOS ---

  static Future<List<Prestamo>> getPrestamos() async {
    final token = await StorageService.getToken();
    final url = Uri.parse(ApiConfig.prestamos);
    final response = await http.get(url, headers: _headers(token));

    _check401(response.statusCode);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Prestamo.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<ResumenCartera> getResumen() async {
    final token = await StorageService.getToken();
    final url = Uri.parse(ApiConfig.prestamosResumen);
    final response = await http.get(url, headers: _headers(token));

    _check401(response.statusCode);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ResumenCartera.fromJson(data as Map<String, dynamic>);
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<Prestamo> getPrestamo(int id) async {
    final token = await StorageService.getToken();
    final url = Uri.parse(ApiConfig.prestamoById(id));
    final response = await http.get(url, headers: _headers(token));

    _check401(response.statusCode);

    if (response.statusCode == 200) {
      return Prestamo.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<Prestamo> createPrestamo({
    required String cliente,
    required String dni,
    required double monto,
    required double interes,
    required String fechaVencimiento,
  }) async {
    final token = await StorageService.getToken();
    final url = Uri.parse(ApiConfig.prestamos);
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({
        'cliente': cliente,
        'dni': dni,
        'monto': monto,
        'interes': interes,
        'fechaVencimiento': fechaVencimiento,
      }),
    );

    _check401(response.statusCode);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Prestamo.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
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
    final url = Uri.parse(ApiConfig.prestamoById(id));

    final Map<String, dynamic> body = {};
    if (cliente != null) body['cliente'] = cliente;
    if (dni != null) body['dni'] = dni;
    if (monto != null) body['monto'] = monto;
    if (interes != null) body['interes'] = interes;
    if (fechaVencimiento != null) body['fechaVencimiento'] = fechaVencimiento;
    if (pagado != null) body['pagado'] = pagado;

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    _check401(response.statusCode);

    if (response.statusCode == 200) {
      return Prestamo.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }

  static Future<void> deletePrestamo(int id) async {
    final token = await StorageService.getToken();
    final url = Uri.parse(ApiConfig.prestamoById(id));
    final response = await http.delete(url, headers: _headers(token));

    _check401(response.statusCode);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(response.body, response.statusCode),
      );
    }
  }
}
