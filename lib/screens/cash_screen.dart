import 'package:flutter/material.dart';
import '../services/db_service.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final openingController = TextEditingController();
  final closingController = TextEditingController();
  final _formKeyOpen = GlobalKey<FormState>();
  final _formKeyClose = GlobalKey<FormState>();

  Map<String, dynamic>? session;
  double today = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    openingController.dispose();
    closingController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      session = await DBService.getOpenCash();
      today = await DBService.todaySales();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar caja: $e')),
        );
      }
    }
    setState(() => loading = false);
  }

  Future<void> openCash() async {
    if (!_formKeyOpen.currentState!.validate()) return;

    try {
      final amount = double.parse(openingController.text);
      await DBService.openCash(amount);
      openingController.clear();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Caja abierta exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> closeCash() async {
    if (!_formKeyClose.currentState!.validate()) return;

    // Confirmación antes de cerrar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar caja?'),
        content: const Text(
          'Una vez cerrada, no podrá modificar esta sesión. '
          'Verifique que el dinero contado sea correcto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cerrar caja'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final closing = double.parse(closingController.text);
      final expected = (session!['opening'] as num).toDouble() + today;
      final difference = closing - expected;

      await DBService.closeCash(session!['id'], closing, expected);
      closingController.clear();
      await load();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Caja cerrada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esperado: \$${expected.toStringAsFixed(2)}'),
                Text('Contado: \$${closing.toStringAsFixed(2)}'),
                const Divider(),
                Text(
                  'Diferencia: \$${difference.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference >= 0 ? Colors.green : Colors.red,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  difference == 0
                      ? 'Caja cuadrada perfectamente.'
                      : difference > 0
                          ? 'Sobrante en caja.'
                          : 'Faltante en caja.',
                  style: TextStyle(
                    color: difference >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: load,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : session == null
              ? _buildOpenCashForm()
              : _buildCloseCashForm(),
    );
  }

  Widget _buildOpenCashForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeyOpen,
        child: Column(
          children: [
            const Icon(Icons.lock_open, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No hay caja abierta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Ingrese el monto inicial para comenzar el día.'),
            const SizedBox(height: 30),
            TextFormField(
              controller: openingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto inicial (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingrese un monto válido mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: openCash,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Caja', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseCashForm() {
    final opening = (session!['opening'] as num).toDouble();
    final expected = opening + today;
    final openedAt = session!['opened_at'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeyClose,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Caja abierta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (openedAt.isNotEmpty)
              Text(
                'Desde: ${openedAt.toString().substring(0, 19)}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 20),

            // Tarjeta de resumen
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Monto inicial', '\$${opening.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildInfoRow('Ventas del día', '\$${today.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildInfoRow(
                      'Total esperado',
                      '\$${expected.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo para dinero contado
            TextFormField(
              controller: closingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Dinero contado (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                helperText: 'Cuente físicamente el dinero y anótelo aquí',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el dinero contado';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Ingrese un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: closeCash,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cerrar Caja', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}