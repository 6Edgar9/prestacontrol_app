import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'storage_service.dart';

class AuthService {
  static Future<AuthResponse> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.authRegister);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final auth = AuthResponse.fromJson(jsonDecode(response.body));
      await StorageService.saveAuthData(
        token: auth.token,
        email: auth.email,
        name: auth.nombre,
      );
      return auth;
    } else {
      throw Exception(_extractError(response.body, response.statusCode));
    }
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.authLogin);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final auth = AuthResponse.fromJson(jsonDecode(response.body));
      await StorageService.saveAuthData(
        token: auth.token,
        email: auth.email,
        name: auth.nombre,
      );
      return auth;
    } else {
      throw Exception(_extractError(response.body, response.statusCode));
    }
  }

  static Future<void> logout() async {
    await StorageService.clearAuthData();
  }

  static bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      if (payload.containsKey('exp')) {
        final exp = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
        return DateTime.now().isBefore(exp);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _extractError(String body, int code) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'Error del servidor (código $code)';
  }
}
