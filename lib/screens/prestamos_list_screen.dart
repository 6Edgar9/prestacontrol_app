import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_response.dart';
import '../models/prestamo.dart';
import '../models/resumen_cartera.dart';
import '../services/auth_service.dart';
import '../services/prestamo_service.dart';
import '../services/storage_service.dart';
import '../widgets/prestamo_card.dart';
import '../widgets/resumen_cartera_card.dart';
import '../widgets/token_expiration_banner.dart';
import 'auth_screen.dart';
import 'prestamo_form_screen.dart';

class PrestamosListScreen extends StatefulWidget {
  const PrestamosListScreen({super.key});

  @override
  State<PrestamosListScreen> createState() => _PrestamosListScreenState();
}

class _PrestamosListScreenState extends State<PrestamosListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Prestamo> _todosPrestamos = [];
  ResumenCartera? _resumen;
  bool _isLoading = true;
  String? _errorMessage;

  String _userName = '';
  String _userEmail = '';
  DateTime? _tokenExpiration;
  Timer? _expirationTimer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _cargarDatosUsuario();
    _cargarDatos();

    _expirationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    final token = await StorageService.getToken();

    DateTime? exp;
    if (token != null) {
      final auth = AuthResponse(
        token: token,
        tipo: 'Bearer',
        nombre: name ?? '',
        email: email ?? '',
        rol: 'USER',
      );
      exp = auth.expirationDateTime;
    }

    if (mounted) {
      setState(() {
        _userName = name ?? 'Prestamista';
        _userEmail = email ?? '';
        _tokenExpiration = exp;
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        PrestamoService.getPrestamos(),
        PrestamoService.getResumen(),
      ]);

      if (mounted) {
        setState(() {
          _todosPrestamos = results[0] as List<Prestamo>;
          _resumen = results[1] as ResumenCartera;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cambiarEstadoPago(Prestamo prestamo) async {
    final nuevoEstado = !prestamo.pagado;
    final accion = nuevoEstado ? 'marcar como pagado' : 'marcar como pendiente';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Desea $accion este préstamo?'),
        content: Text('Cliente: ${prestamo.cliente}\nTotal: S/ ${prestamo.totalCobrar.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await PrestamoService.updatePrestamo(id: prestamo.id, pagado: nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado ? 'Préstamo marcado como cobrado' : 'Préstamo vuelto a pendiente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _anularPrestamo(Prestamo prestamo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Préstamo?'),
        content: Text('Se eliminará el registro de "${prestamo.cliente}" por S/ ${prestamo.totalCobrar.toStringAsFixed(2)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await PrestamoService.deletePrestamo(prestamo.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préstamo eliminado exitosamente'), backgroundColor: Colors.green),
      );
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de que desea salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );

    if (confirmar == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  List<Prestamo> _filtrar(List<Prestamo> lista, {required bool cobrar}) {
    return lista.where((p) {
      final cumpleEstado = cobrar ? !p.pagado : p.pagado;
      if (!cumpleEstado) return false;
      if (_searchQuery.isEmpty) return true;
      return p.cliente.toLowerCase().contains(_searchQuery) || p.dni.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendientes = _filtrar(_todosPrestamos, cobrar: true);
    final cobrados = _filtrar(_todosPrestamos, cobrar: false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PrestaControl', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _userName.isNotEmpty ? 'Prestamista: $_userName ($_userEmail)' : 'Cartera de Préstamos',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: _cargarDatos),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar Sesión', onPressed: _cerrarSesion),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TokenExpirationBanner(expirationDate: _tokenExpiration),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Conectando con el servidor, puede tardar unos segundos...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off, size: 56, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _cargarDatos,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: NestedScrollView(
                            headerSliverBuilder: (ctx, innerBoxScrolled) => [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_resumen != null) ResumenCarteraCard(resumen: _resumen!),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Buscar por cliente o DNI...',
                                          prefixIcon: const Icon(Icons.search),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () => _searchController.clear(),
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _SliverTabBarDelegate(
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: theme.colorScheme.primary,
                                    indicatorColor: theme.colorScheme.primary,
                                    tabs: [
                                      Tab(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('Por cobrar'),
                                            const SizedBox(width: 6),
                                            Badge.count(count: pendientes.length),
                                          ],
                                        ),
                                      ),
                                      Tab(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('Cobrados'),
                                            const SizedBox(width: 6),
                                            Badge.count(count: cobrados.length),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ],
                            body: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLista(pendientes, 'No hay préstamos por cobrar pendientes'),
                                _buildLista(cobrados, 'Aún no se han cobrado préstamos'),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PrestamoFormScreen()),
          );
          if (res == true) _cargarDatos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Préstamo'),
      ),
    );
  }

  Widget _buildLista(List<Prestamo> lista, String mensajeVacio) {
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(mensajeVacio, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final p = lista[i];
        return PrestamoCard(
          prestamo: p,
          onTogglePago: () => _cambiarEstadoPago(p),
          onEdit: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => PrestamoFormScreen(prestamoExistente: p)),
            );
            if (res == true) _cargarDatos();
          },
          onDelete: () => _anularPrestamo(p),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, this.backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
