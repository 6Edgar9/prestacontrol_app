import 'dart:convert';

class AuthResponse {
  final String token;
  final String tipo;
  final int? id;
  final String nombre;
  final String email;
  final String rol;
  final int? expiraEn;

  AuthResponse({
    required this.token,
    required this.tipo,
    this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.expiraEn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'Bearer',
      id: json['id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'USER',
      expiraEn: json['expiraEn'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'tipo': tipo,
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'expiraEn': expiraEn,
      };

  DateTime? get expirationDateTime {
    if (expiraEn != null && expiraEn! > 0) {
      return DateTime.fromMillisecondsSinceEpoch(expiraEn!);
    }
    // Si no vino expiraEn, intentar decodificar desde el payload JWT
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        String normalized = base64Url.normalize(parts[1]);
        String payloadString = utf8.decode(base64Url.decode(normalized));
        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        if (payload.containsKey('exp')) {
          final expSec = payload['exp'] as int;
          return DateTime.fromMillisecondsSinceEpoch(expSec * 1000);
        }
      }
    } catch (_) {}
    return null;
  }

  bool get isExpired {
    final exp = expirationDateTime;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }
}
