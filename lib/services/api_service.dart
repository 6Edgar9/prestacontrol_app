import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  static const String _coldStartMessage =
      'Conectando con el servidor, puede tardar unos segundos... Si el servidor en Render está iniciando, esto puede tomar hasta 1 minuto.';

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
    try {
      final url = Uri.parse(ApiConfig.authRegister);
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'nombre': nombre,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

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
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.authLogin);
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

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
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
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
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamos);
      final response = await http.get(url, headers: _headers(token)).timeout(ApiConfig.requestTimeout);

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
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }

  static Future<ResumenCartera> getResumen() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamosResumen);
      final response = await http.get(url, headers: _headers(token)).timeout(ApiConfig.requestTimeout);

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
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }

  static Future<Prestamo> getPrestamo(int id) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamoById(id));
      final response = await http.get(url, headers: _headers(token)).timeout(ApiConfig.requestTimeout);

      _check401(response.statusCode);

      if (response.statusCode == 200) {
        return Prestamo.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }

  static Future<Prestamo> createPrestamo({
    required String cliente,
    required String dni,
    required double monto,
    required double interes,
    required String fechaVencimiento,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamos);
      final response = await http
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode({
              'cliente': cliente,
              'dni': dni,
              'monto': monto,
              'interes': interes,
              'fechaVencimiento': fechaVencimiento,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      _check401(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Prestamo.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
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
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamoById(id));

      final Map<String, dynamic> body = {};
      if (cliente != null) body['cliente'] = cliente;
      if (dni != null) body['dni'] = dni;
      if (monto != null) body['monto'] = monto;
      if (interes != null) body['interes'] = interes;
      if (fechaVencimiento != null) body['fechaVencimiento'] = fechaVencimiento;
      if (pagado != null) body['pagado'] = pagado;

      final response = await http
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);

      _check401(response.statusCode);

      if (response.statusCode == 200) {
        return Prestamo.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }

  static Future<void> deletePrestamo(int id) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiConfig.prestamoById(id));
      final response = await http.delete(url, headers: _headers(token)).timeout(ApiConfig.requestTimeout);

      _check401(response.statusCode);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      throw ApiException(408, 'Tiempo de espera agotado (60s). $_coldStartMessage');
    } on SocketException {
      throw ApiException(503, 'Error de conexión a internet o el servidor está iniciando.');
    }
  }
}
