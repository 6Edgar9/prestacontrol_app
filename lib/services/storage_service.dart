import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'jwt_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyBaseUrl = 'api_base_url';

  // Guardar token y datos del usuario
  static Future<void> saveAuthData({
    required String token,
    required String email,
    required String name,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserName, value: name);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  // Eliminar sesión al cerrar o recibir 401
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserName);
  }

  // Guardar y recuperar preferencia de URL base del servidor
  static Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url);
    ApiConfig.setBaseUrl(url);
  }

  static Future<String> loadBaseUrl() async {
    final saved = await _storage.read(key: _keyBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      ApiConfig.setBaseUrl(saved);
      return saved;
    }
    return ApiConfig.baseUrl;
  }
}
