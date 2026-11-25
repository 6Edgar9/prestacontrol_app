import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_response.dart';
import '../models/prestamo.dart';
import '../models/resumen_cartera.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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

    // Timer para revisar expiración periódicamente
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
      final prestamosFuture = ApiService.getPrestamos();
      final resumenFuture = ApiService.getResumen();

      final results = await Future.wait([prestamosFuture, resumenFuture]);

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
        content: Text(
          'Cliente: ${prestamo.cliente}\nTotal: S/ ${prestamo.totalCobrar.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.updatePrestamo(
        id: prestamo.id,
        pagado: nuevoEstado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado ? 'Préstamo cobrado' : 'Préstamo vuelto a pendiente'),
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
        title: const Text('¿Anular / Eliminar Préstamo?'),
        content: Text(
          'Se anulará el préstamo de "${prestamo.cliente}" por S/ ${prestamo.totalCobrar.toStringAsFixed(2)}. Esta acción no se puede deshacer.',
        ),
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
      await ApiService.deletePrestamo(prestamo.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préstamo anulado con éxito'), backgroundColor: Colors.green),
      );
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al anular: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de que desea salir de su cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await ApiService.logout();
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

  Widget _buildResumenCard(ThemeData theme) {
    if (_resumen == null) return const SizedBox.shrink();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Cartera',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_resumen!.totalPrestamos} Préstamos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Capital Prestado',
                    'S/ ${_resumen!.capitalPrestado.toStringAsFixed(2)}',
                    Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total por Cobrar',
                    'S/ ${_resumen!.totalPorCobrar.toStringAsFixed(2)}',
                    Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Ganancia Esperada',
                    'S/ ${_resumen!.gananciaEsperada.toStringAsFixed(2)}',
                    Colors.green.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total Cobrado',
                    'S/ ${_resumen!.totalCobrado.toStringAsFixed(2)}',
                    Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTokenExpirationBanner(ThemeData theme) {
    if (_tokenExpiration == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final diferencia = _tokenExpiration!.difference(now);

    if (diferencia.isNegative) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.shade100,
        child: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Su token ha vencido. Por favor cierre sesión e inicie de nuevo.',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (diferencia.inHours < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'El token expira en ${diferencia.inMinutes} minutos.',
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrestamoCard(Prestamo p, ThemeData theme) {
    final esVencido = p.vencido;
      final cardBg = esVencido ? Colors.red.shade50.withAlpha(100) : Colors.white;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esVencido ? Colors.red : Colors.grey.shade300,
          width: esVencido ? 1.8 : 0.8,
        ),
      ),
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Cliente y estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.cliente,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'DNI: ${p.dni}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (esVencido)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VENCIDO',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (p.pagado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'COBRADO',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PENDIENTE',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(height: 18),
            // Detalle montos y fechas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto Prestado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      'S/ ${p.monto.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Interés', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '${p.interes.toStringAsFixed(1)}% (+S/ ${p.montoInteres.toStringAsFixed(2)})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total a Cobrar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      'S/ ${p.totalCobrar.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: esVencido ? Colors.red : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${p.fechaVencimiento}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: esVencido ? FontWeight.bold : FontWeight.normal,
                    color: esVencido ? Colors.red : Colors.black87,
                  ),
                ),
                const Spacer(),
                // Acciones rápidas
                IconButton(
                  icon: Icon(
                    p.pagado ? Icons.undo : Icons.check_circle_outline,
                    color: p.pagado ? Colors.orange : Colors.green,
                  ),
                  tooltip: p.pagado ? 'Marcar pendiente' : 'Marcar cobrado',
                  onPressed: () => _cambiarEstadoPago(p),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  tooltip: 'Editar',
                  onPressed: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrestamoFormScreen(prestamoExistente: p),
                      ),
                    );
                    if (res == true) _cargarDatos();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Anular / Eliminar',
                  onPressed: () => _anularPrestamo(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Prestamo> lista, String vacioTexto) {
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                vacioTexto,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lista.length,
      itemBuilder: (ctx, i) => _buildPrestamoCard(lista[i], Theme.of(context)),
    );
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTokenExpirationBanner(theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                                      _buildResumenCard(theme),
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
                                _buildTabContent(pendientes, 'No hay préstamos por cobrar pendientes'),
                                _buildTabContent(cobrados, 'Aún no se han cobrado préstamos'),
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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
