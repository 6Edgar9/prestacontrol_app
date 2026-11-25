import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/prestamo.dart';
import '../services/prestamo_service.dart';

class PrestamoFormScreen extends StatefulWidget {
  final Prestamo? prestamoExistente;

  const PrestamoFormScreen({super.key, this.prestamoExistente});

  bool get esEdicion => prestamoExistente != null;

  @override
  State<PrestamoFormScreen> createState() => _PrestamoFormScreenState();
}

class _PrestamoFormScreenState extends State<PrestamoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _clienteController;
  late TextEditingController _dniController;
  late TextEditingController _montoController;
  late TextEditingController _interesController;

  DateTime? _fechaVencimientoSeleccionada;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.prestamoExistente;
    _clienteController = TextEditingController(text: p?.cliente ?? '');
    _dniController = TextEditingController(text: p?.dni ?? '');
    _montoController = TextEditingController(text: p != null ? p.monto.toStringAsFixed(2) : '');
    _interesController = TextEditingController(text: p != null ? p.interes.toStringAsFixed(2) : '10.00');

    if (p != null && p.fechaVencimiento.isNotEmpty) {
      try {
        _fechaVencimientoSeleccionada = DateTime.parse(p.fechaVencimiento);
      } catch (_) {
        _fechaVencimientoSeleccionada = DateTime.now().add(const Duration(days: 30));
      }
    } else {
      _fechaVencimientoSeleccionada = DateTime.now().add(const Duration(days: 30));
    }

    _montoController.addListener(() => setState(() {}));
    _interesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _dniController.dispose();
    _montoController.dispose();
    _interesController.dispose();
    super.dispose();
  }

  double get _totalCalculado {
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final interes = double.tryParse(_interesController.text) ?? 0.0;
    final ganancia = monto * (interes / 100.0);
    return monto + ganancia;
  }

  Future<void> _seleccionarFecha() async {
    final inicial = _fechaVencimientoSeleccionada ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _fechaVencimientoSeleccionada = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaVencimientoSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor elija una fecha de vencimiento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaVencimientoSeleccionada!);
    final cliente = _clienteController.text.trim();
    final dni = _dniController.text.trim();
    final monto = double.parse(_montoController.text);
    final interes = double.parse(_interesController.text);

    try {
      if (widget.esEdicion) {
        await PrestamoService.updatePrestamo(
          id: widget.prestamoExistente!.id,
          cliente: cliente,
          dni: dni,
          monto: monto,
          interes: interes,
          fechaVencimiento: fechaStr,
        );
      } else {
        await PrestamoService.createPrestamo(
          cliente: cliente,
          dni: dni,
          monto: monto,
          interes: interes,
          fechaVencimiento: fechaStr,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.esEdicion ? 'Préstamo actualizado' : 'Préstamo registrado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar Préstamo' : 'Nuevo Préstamo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
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
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _clienteController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo del Cliente *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        helperText: 'Persona que recibe el dinero prestado',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'El nombre del cliente es obligatorio';
                        }
                        if (val.trim().length > 100) {
                          return 'Máximo 100 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'DNI del Cliente (8 dígitos) *',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'El DNI es obligatorio';
                        }
                        if (val.trim().length != 8) {
                          return 'El DNI debe tener exactamente 8 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _montoController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Monto Prestado (S/) *',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingrese el monto';
                              }
                              final numVal = double.tryParse(val);
                              if (numVal == null || numVal <= 0) {
                                return 'Debe ser mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _interesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Interés (%) *',
                              prefixIcon: Icon(Icons.percent),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingrese el % de interés';
                              }
                              final numVal = double.tryParse(val);
                              if (numVal == null || numVal < 0) {
                                return 'No puede ser negativo';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tarjeta cálculo en tiempo real
                    Card(
                      color: theme.colorScheme.primaryContainer.withAlpha(100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total a cobrar estimado:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'S/ ${_totalCalculado.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Selector de fecha
                    InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Vencimiento *',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _fechaVencimientoSeleccionada != null
                              ? dateFormat.format(_fechaVencimientoSeleccionada!)
                              : 'Seleccione fecha',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _guardar,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          widget.esEdicion ? 'Actualizar Préstamo' : 'Registrar Préstamo',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Conectando con el servidor, puede tardar unos segundos...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
