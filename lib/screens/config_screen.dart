// lib/screens/config_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../controllers/auth_controller.dart';
import '../core/session_manager.dart';
import 'login_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String _appMode = 'primary';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mode = DBService.getAppMode();
      setState(() => _appMode = mode);
    } catch (e) {
      setState(() => _error = 'Error cargando configuración: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMode(String mode) async {
    setState(() => _loading = true);
    try {
      await DBService.setAppMode(mode);
      setState(() => _appMode = mode);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Modo cambiado a: $mode')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando modo: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _loading = true);
    try {
      // Llamada segura a DBService como placeholder para iniciar export.
      // Reemplaza por tu ExportService.exportAll() si lo tienes.
      await DBService.getProducts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export iniciado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exportando: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    final session = context.read<SessionManager>();
    try {
      await auth.logout(clearPersist: true);
      session.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cerrando sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          // Botón Exportar siempre visible
          IconButton(
            tooltip: 'Exportar datos',
            icon: const Icon(Icons.file_download),
            onPressed: _loading ? null : _exportData,
          ),
          // Botón Cerrar sesión siempre visible
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _loading ? null : _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('Modo de la aplicación'),
                        subtitle: Text('Modo actual: $_appMode'),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _appMode == 'primary' ? null : () => _setMode('primary'),
                            child: const Text('Primary'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _appMode == 'pro' ? null : () => _setMode('pro'),
                            child: const Text('Pro'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListTile(
                        title: const Text('Usuario actual'),
                        subtitle: Text(auth.user?['user']?.toString() ?? 'No autenticado'),
                      ),
                      const SizedBox(height: 12),
                      // Botón de cerrar sesión dentro del contenido también (si el usuario prefiere)
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final session = context.read<SessionManager>();
                          await session.loadSession();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión recargada')));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recargar sesión'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final cfg = await DBService.getConfig('app_mode');
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Debug config'),
                                content: Text('app_mode: $cfg'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                                ],
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Ver config (debug)'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
