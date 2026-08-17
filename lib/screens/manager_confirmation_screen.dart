import 'package:flutter/material.dart';
import '../controllers/cierre_service.dart';
import '../services/db_service.dart';

class ManagerConfirmationScreen extends StatefulWidget {
  final int sessionId;

  const ManagerConfirmationScreen({super.key, required this.sessionId});

  @override
  State<ManagerConfirmationScreen> createState() => _ManagerConfirmationScreenState();
}

class _ManagerConfirmationScreenState extends State<ManagerConfirmationScreen> {
  bool loading = true;
  bool confirming = false;
  Map<String, dynamic>? provisional;

  @override
  void initState() {
    super.initState();
    _loadProvisional();
  }

  Future<void> _loadProvisional() async {
    setState(() => loading = true);
    try {
      provisional = await CierreService().getProvisionalClose(widget.sessionId);
    } catch (e) {
      provisional = null;
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _confirm() async {
    if (provisional == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cierre'),
        content: const Text('¿Confirmar y aplicar cierre final para esta sesión? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => confirming = true);
    try {
      await CierreService().confirmProvisionalCloseLocally(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cierre confirmado y aplicado.')));
      }
      await _loadProvisional();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al confirmar: $e')));
      }
    } finally {
      setState(() => confirming = false);
    }
  }

  Widget _buildProvisionalView() {
    if (provisional == null) {
      return const Center(child: Text('No hay cierre provisional para esta sesión.'));
    }

    final productsStart = Map<String, dynamic>.from(provisional!['products_start'] ?? {});
    final productsEnd = Map<String, dynamic>.from(provisional!['products_end'] ?? {});
    final cashCount = Map<String, dynamic>.from(provisional!['cash_count'] ?? {});
    final transferCount = Map<String, dynamic>.from(provisional!['transfer_count'] ?? {});
    final fund = provisional!['fund'] ?? 0.0;
    final finalCash = provisional!['final_cash'] ?? 0.0;
    final expectedCash = provisional!['expected_cash'] ?? 0.0;
    final notes = provisional!['notes'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guardado: ${provisional!['saved_at'] ?? '---'}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Notas: $notes'),
          const Divider(),
          const Text('Productos (inicio → final)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...productsStart.keys.map((k) {
            final start = productsStart[k];
            final end = productsEnd[k] ?? 0;
            return ListTile(
              dense: true,
              title: Text(k),
              subtitle: Text('Inicio: $start  •  Final: $end'),
            );
          }).toList(),
          const Divider(),
          const Text('Conteo de efectivo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Fondo inicial: \$${(fund).toStringAsFixed(2)}'),
          Text('Efectivo contado: \$${(finalCash).toStringAsFixed(2)}'),
          Text('Efectivo esperado: \$${(expectedCash).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          const Text('Denominaciones', style: TextStyle(fontWeight: FontWeight.bold)),
          ...cashCount.keys.map((k) => Text('$k : ${cashCount[k]}')),
          const Divider(),
          const Text('Transferencias', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Total: \$${(transferCount['total'] ?? 0).toString()}'),
          Text('Referencia: ${transferCount['reference'] ?? ''}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: confirming ? null : _confirm,
              icon: confirming ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
              label: Text(confirming ? 'Confirmando...' : 'Confirmar cierre (Jefe)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación del Jefe'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProvisional),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : _buildProvisionalView(),
    );
  }
}
