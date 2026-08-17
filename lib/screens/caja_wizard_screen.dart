// lib/screens/caja_wizard_screen.dart
import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../controllers/product_repository.dart';
import '../core/session_manager.dart';
import '../widgets/cash_count_widget.dart';

class CajaWizardScreen extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> resumenVentas;

  const CajaWizardScreen({
    super.key,
    required this.sessionId,
    required this.resumenVentas,
  });

  @override
  State<CajaWizardScreen> createState() => _CajaWizardScreenState();
}

class _CajaWizardScreenState extends State<CajaWizardScreen> {
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  double ventasEfectivo = 0.0;
  double ventasTransferencia = 0.0;
  double fondoInicial = 0.0;

  double efectivoContado = 0.0;
  Map<String, int> cashCountMap = {};

  double transferTotalInput = 0.0;
  String transferReference = '';

  List<Map<String, dynamic>> productos = [];
  Map<String, dynamic> stockStart = {};
  Map<String, dynamic> stockFinalInput = {};
  Map<String, dynamic> entradasDelDia = {};

  Map<String, dynamic> productsEnd = {};
  Map<String, dynamic> productsDiff = {};

  @override
  void initState() {
    super.initState();
    ventasEfectivo = widget.resumenVentas['efectivo'] ?? 0.0;
    ventasTransferencia = widget.resumenVentas['transferencia'] ?? 0.0;
    _loadInitialData();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);

    productos = await ProductRepository.getAll();
    stockStart = await ProductRepository.getStockStartMap();
    entradasDelDia = await _calculateEntriesOfDay();

    for (var p in productos) {
      final name = p['name'] ?? '';
      final current = _toDouble(p['stock']);
      stockFinalInput[name] = current;
    }

    setState(() => _loading = false);
  }

  Future<Map<String, double>> _calculateEntriesOfDay() async {
    final map = <String, double>{};
    final movements = await DBService.getMovementsOfDay();
    for (var m in movements) {
      final productIndex = m['product_index'];
      final qty = _toDouble(m['qty']);
      if (productIndex == null) continue;
      final product = productos.firstWhere(
        (p) => p['id'] == productIndex,
        orElse: () => {'name': 'Desconocido'},
      );
      final name = product['name'] ?? 'Desconocido';
      map[name] = (map[name] ?? 0.0) + qty;
    }
    return map;
  }

  void _next() {
    if (_step < 5) setState(() => _step += 1);
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  Future<void> _saveProvisionalClose() async {
    setState(() => _saving = true);

    productsEnd = {};
    for (var p in productos) {
      final name = p['name'] ?? '';
      final finalStock = _toDouble(stockFinalInput[name]);
      productsEnd[name] = finalStock;
    }

    final expectedCash = fondoInicial + ventasEfectivo;

    final cashCountForDb = <String, int>{};
    cashCountMap.forEach((k, v) => cashCountForDb[k] = v);

    final transferCountForDb = {
      'total': transferTotalInput,
      'reference': transferReference,
    };

    try {
      final key = 'provisional_close_${widget.sessionId}';
      final provisional = {
        'saved_at': DateTime.now().toIso8601String(),
        'products_start': stockStart,
        'products_end': productsEnd,
        'cash_count': cashCountForDb,
        'transfer_count': transferCountForDb,
        'fund': fondoInicial,
        'final_cash': efectivoContado,
        'expected_cash': expectedCash,
        'notes': '',
        'confirmed_by_manager': false,
        'confirmed_at': null,
      };

      await DBService.putConfig(key, provisional);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cierre provisional guardado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando cierre: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Map<String, Map<String, dynamic>> _computeProductDifferences() {
    final diffs = <String, Map<String, dynamic>>{};
    for (var p in productos) {
      final name = p['name'] ?? '';
      final initial = _toDouble(stockStart[name]);
      final entries = _toDouble(entradasDelDia[name]);
      final finalStock = _toDouble(stockFinalInput[name]);

      final expected = initial + entries;
      final difference = expected - finalStock;

      diffs[name] = {
        'initial': initial,
        'entries': entries,
        'expected': expected,
        'final': finalStock,
        'difference': difference,
      };
    }
    return diffs;
  }

  Widget _stepHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Resumen de ventas'),
            Text('Ventas efectivo: \$${ventasEfectivo.toStringAsFixed(2)}'),
            Text('Ventas transferencia: \$${ventasTransferencia.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('Fondo inicial'),
            TextFormField(
              initialValue: fondoInicial.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => fondoInicial = double.tryParse(v) ?? 0.0,
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Denominaciones'),
            CashCountWidget(
              onChanged: (total, breakdown) {
                setState(() {
                  efectivoContado = total;
                  cashCountMap = breakdown;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Efectivo contado: \$${efectivoContado.toStringAsFixed(2)}'),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Transferencias'),
            TextFormField(
              initialValue: transferTotalInput.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto total transferencias'),
              onChanged: (v) => transferTotalInput = double.tryParse(v) ?? 0.0,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: transferReference,
              decoration: const InputDecoration(labelText: 'Referencia / notas'),
              onChanged: (v) => transferReference = v,
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Conteo físico por producto'),
            const Text('Ingrese el stock final contado para cada producto'),
            const SizedBox(height: 8),
            ...productos.map((p) {
              final name = p['name'] ?? '';
              final start = _toDouble(stockStart[name]);
              final entries = _toDouble(entradasDelDia[name]);
              final suggested = (p['stock'] ?? 0).toString();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(name)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Inicio: ${start.toStringAsFixed(0)}'),
                          Text('Entradas: ${entries.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: suggested,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Final'),
                          onChanged: (v) {
                            stockFinalInput[name] = double.tryParse(v) ?? 0.0;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );

      case 4:
        final diffs = _computeProductDifferences();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Diferencias por producto'),
            const Text('Se calcula: stock inicial + entradas del día - stock final'),
            const SizedBox(height: 8),
            ...diffs.keys.map((name) {
              final d = diffs[name]!;
              final diff = d['difference'] as double;
              return ListTile(
                title: Text(name),
                subtitle: Text('Esperado: ${d['expected'].toStringAsFixed(0)} • Final: ${d['final'].toStringAsFixed(0)}'),
                trailing: Text(
                  diff.toStringAsFixed(0),
                  style: TextStyle(color: diff == 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
        );

      case 5:
        final expectedCash = fondoInicial + ventasEfectivo;
        final difference = efectivoContado - expectedCash;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('Resumen final y cierre provisional'),
            Text('Fondo inicial: \$${fondoInicial.toStringAsFixed(2)}'),
            Text('Ventas efectivo: \$${ventasEfectivo.toStringAsFixed(2)}'),
            Text('Efectivo esperado: \$${expectedCash.toStringAsFixed(2)}'),
            Text('Efectivo contado: \$${efectivoContado.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Diferencia: \$${difference.toStringAsFixed(2)}',
              style: TextStyle(color: difference == 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveProvisionalClose,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar cierre provisional'),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Resumen ventas',
      'Denominaciones',
      'Transferencias',
      'Conteo físico',
      'Diferencias',
      'Resumen',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar caja - Wizard')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: (_step + 1) / steps.length)),
                const SizedBox(width: 12),
                Text('${_step + 1}/${steps.length}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(steps[_step], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: _buildStepContent())),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton.icon(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Anterior'),
                  ),
                const Spacer(),
                if (_step < steps.length - 1)
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
