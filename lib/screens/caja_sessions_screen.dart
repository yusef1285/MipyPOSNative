// lib/screens/caja_sessions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../controllers/auth_controller.dart';
import '../core/session_manager.dart';
import 'caja_wizard_screen.dart';
import 'manager_confirmation_screen.dart';
import 'reopen_sample_screen.dart';

class CajaSessionsScreen extends StatefulWidget {
  const CajaSessionsScreen({super.key});

  @override
  State<CajaSessionsScreen> createState() => _CajaSessionsScreenState();
}

class _CajaSessionsScreenState extends State<CajaSessionsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    // Cargar sesiones desde DB al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => loadSessions());
  }

  Future<void> loadSessions() async {
    setState(() => loading = true);
    try {
      sessions = await DBService.getCashSessions();
    } catch (e) {
      sessions = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openSession() async {
    final fundCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abrir nueva caja'),
        content: TextField(
          controller: fundCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Fondo inicial'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final fund = double.tryParse(fundCtrl.text) ?? 0.0;

    // Usar la instancia provista de SessionManager para abrir la sesión
    final sessionManager = context.read<SessionManager>();
    try {
      await sessionManager.openSession(fund);
      // Asegurar que la UI recargue la lista de sesiones desde DB
      await loadSessions();
      // Notificar al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caja abierta correctamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error abriendo caja: $e')));
      }
    }
  }

  void openWizard(Map<String, dynamic> session) async {
    final ventas = await DBService.getSalesOfSession(session['id']);

    double efectivo = 0.0;
    double transferencia = 0.0;

    for (var v in ventas) {
      final method = (v['method'] ?? '').toString().toLowerCase();
      final total = (v['total'] ?? 0) is num ? (v['total'] as num).toDouble() : double.tryParse('${v['total']}') ?? 0.0;
      if (method.contains('efectivo')) {
        efectivo += total;
      } else if (method.contains('transferencia') || method.contains('tarjeta')) {
        transferencia += total;
      }
    }

    final resumen = {
      'efectivo': efectivo,
      'transferencia': transferencia,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CajaWizardScreen(
          sessionId: session['id'],
          resumenVentas: resumen,
        ),
      ),
    ).then((_) => loadSessions());
  }

  void openManagerConfirmation(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerConfirmationScreen(sessionId: session['id']),
      ),
    ).then((_) => loadSessions());
  }

  void openReopenSample(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReopenSampleScreen(sessionId: session['id']),
      ),
    ).then((_) => loadSessions());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final role = (auth.user?['role'] ?? '').toString().toLowerCase();
    final bool isManager = role == 'admin' || role == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones de caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openSession,
            tooltip: 'Abrir nueva caja',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSessions,
            tooltip: 'Actualizar sesiones',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text('No hay sesiones de caja'))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    final abierta = s['close'] == null;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          abierta ? Icons.lock_open : Icons.lock,
                          color: abierta ? Colors.green : Colors.grey,
                        ),
                        title: Text('Caja #${s['id']}'),
                        subtitle: Text(
                          'Abierta: ${s['open']}\n'
                          'Cerrada: ${s['close'] ?? '---'}\n'
                          'Fondo: ${s['fund']}',
                        ),
                        trailing: abierta
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => openWizard(s),
                                    child: const Text('Cerrar turno'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isManager)
                                    OutlinedButton(
                                      onPressed: () => openManagerConfirmation(s),
                                      child: const Text('Confirmar'),
                                    ),
                                  if (isManager) const SizedBox(width: 8),
                                  if (isManager)
                                    IconButton(
                                      tooltip: 'Reapertura (muestreo 10%)',
                                      icon: const Icon(Icons.refresh_outlined),
                                      onPressed: () => openReopenSample(s),
                                    ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('Cerrada', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
