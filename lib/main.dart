import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/prestamos_list_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar URL base personalizada guardada
  await StorageService.loadBaseUrl();

  // Configurar callback global cuando la API devuelva 401
  ApiService.onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  };

  // Sesion persistente: si ya existe token en almacenamiento seguro, va directo a la lista
  final token = await StorageService.getToken();
  final bool tieneSesion = token != null && token.isNotEmpty;

  runApp(PrestaControlApp(inicioConSesion: tieneSesion));
}

class PrestaControlApp extends StatelessWidget {
  final bool inicioConSesion;

  const PrestaControlApp({super.key, required this.inicioConSesion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PrestaControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 1,
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: inicioConSesion ? const PrestamosListScreen() : const AuthScreen(),
    );
  }
}
