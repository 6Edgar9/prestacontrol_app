class ApiConfig {
  // Preset de URLs comunes
  static const String defaultLocalUrl = 'http://10.0.2.2:8080'; // Emulador Android
  static const String defaultWebLocalUrl = 'http://localhost:8080'; // Web / Desktop
  static const String defaultRenderUrl = 'https://prestamoservice-cohc.onrender.com'; // Nube Render Producción

  // URL base activa por defecto apuntando al backend en producción de Render
  static String baseUrl = defaultRenderUrl;

  // Timeout para peticiones HTTP (60s para soportar el arranque en frío del plan gratuito de Render)
  static const Duration requestTimeout = Duration(seconds: 60);

  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      baseUrl = url.substring(0, url.length - 1);
    } else {
      baseUrl = url;
    }
  }

  // Endpoints
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogin => '$baseUrl/auth/login';
  static String get prestamos => '$baseUrl/prestamos';
  static String get prestamosResumen => '$baseUrl/prestamos/resumen';
  static String prestamoById(int id) => '$baseUrl/prestamos/$id';
}
