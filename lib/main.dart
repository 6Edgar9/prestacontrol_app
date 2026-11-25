import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/prestamos_list_screen.dart';
import 'services/auth_service.dart';
import 'services/prestamo_service.dart';
import 'services/storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar URL base configurada
  await StorageService.loadBaseUrl();

  // Callback global para 401: redirige limpiando historial
  PrestamoService.onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  };

  // Persistencia de sesión con validación de JWT
  final token = await StorageService.getToken();
  final bool sesionValida = AuthService.isTokenValid(token);

  runApp(PrestaControlApp(inicioConSesion: sesionValida));
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
