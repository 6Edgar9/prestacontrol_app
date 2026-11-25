import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'prestamos_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();

  // Controladores Login
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  // Controladores Registro
  final _nombreRegController = TextEditingController();
  final _emailRegController = TextEditingController();
  final _passwordRegController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _nombreRegController.dispose();
    _emailRegController.dispose();
    _passwordRegController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKeyLogin.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.login(
        email: _emailLoginController.text.trim(),
        password: _passwordLoginController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PrestamosListScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKeyRegister.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.register(
        nombre: _nombreRegController.text.trim(),
        email: _emailRegController.text.trim(),
        password: _passwordRegController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PrestamosListScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showServerSettingsDialog() {
    final urlController = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuración del Servidor API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione o ingrese la URL donde se ejecuta la API REST:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Base de la API',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud_queue),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Celular USB (localhost:8080)'),
                  onPressed: () => urlController.text = ApiConfig.defaultWebLocalUrl,
                ),
                ActionChip(
                  label: const Text('WiFi Local (10.18.44.92:8080)'),
                  onPressed: () => urlController.text = 'http://10.18.44.92:8080',
                ),
                ActionChip(
                  label: const Text('Render'),
                  onPressed: () => urlController.text = ApiConfig.defaultRenderUrl,
                ),
                ActionChip(
                  label: const Text('Emulador Android (10.0.2.2)'),
                  onPressed: () => urlController.text = ApiConfig.defaultLocalUrl,
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await StorageService.saveBaseUrl(newUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL actualizada a: $newUrl')),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PrestaControl'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar URL de la API',
            onPressed: _showServerSettingsDialog,
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Control de Préstamos',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Gestión segura para prestamistas con JWT',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Iniciar Sesión'),
                          Tab(text: 'Registrarse'),
                        ],
                        onTap: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 290,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: LOGIN
                            Form(
                              key: _formKeyLogin,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailLoginController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo Electrónico',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingrese su correo';
                                      }
                                      if (!val.contains('@')) {
                                        return 'Correo no válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordLoginController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Ingrese su contraseña';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Entrar', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TAB 2: REGISTRO
                            Form(
                              key: _formKeyRegister,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nombreRegController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre Completo',
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingrese su nombre';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailRegController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo Electrónico',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingrese su correo';
                                      }
                                      if (!val.contains('@')) {
                                        return 'Correo no válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordRegController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña (mínimo 6 caracteres)',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.length < 6) {
                                        return 'Mínimo 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Crear Cuenta', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
