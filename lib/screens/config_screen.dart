import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../services/license_service.dart';
import '../controllers/auth_controller.dart';
import '../core/session_manager.dart';
import 'login_screen.dart';

import 'package:qr_flutter/qr_flutter.dart';
import '../services/sync_service.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String _appMode = 'demo';
  bool _loading = true;
  String? _error;
  String? _localIp;
  String _deviceId = "Cargando...";
  final TextEditingController _licenseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final id = await LicenseService.getDeviceIdentifier();
    final mode = DBService.getAppMode();
    final license = LicenseService.getLicenseCode() ?? '';
    _licenseCtrl.text = license;

    if (mounted) {
      setState(() {
        _deviceId = id;
        _appMode = mode;
        _loading = false;
      });
    }

    _initSync();
  }

  Future<void> _initSync() async {
    final auth = context.read<AuthController>();
    if (auth.isAdmin) {
      final ip = await SyncService().startServer();
      if (mounted) setState(() => _localIp = ip);
    }
  }

  void _scanQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final ip = barcode.rawValue;
              if (ip != null) {
                SyncService().connectToMaster(ip);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vinculado a: $ip')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showQR() {
    if (_localIp == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor de Sincronización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escanea desde los dispositivos empleados:'),
            const SizedBox(height: 20),
            QrImageView(data: _localIp!, size: 200.0),
            Text(
              'IP: $_localIp',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyLicense() async {
    final code = _licenseCtrl.text.trim();
    await LicenseService.activatePro(code);
    final isPro = LicenseService.isProActive();

    if (mounted) {
      setState(() => _appMode = DBService.getAppMode());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPro
                ? '¡App Activada! Modo PRO habilitado.'
                : 'Licencia inválida para este dispositivo.',
          ),
          backgroundColor: isPro ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _setMode(String mode) async {
    await DBService.setAppMode(mode);
    if (mounted) {
      setState(() => _appMode = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración y Licencia'),
        actions: [
          if (auth.isAdmin && _localIp != null)
            IconButton(icon: const Icon(Icons.qr_code_2), onPressed: _showQR),
          if (!auth.isAdmin)
            IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanQR),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: _appMode == 'pro'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _appMode == 'pro'
                                        ? Icons.verified
                                        : Icons.warning,
                                    color: _appMode == 'pro'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Estado: ${_appMode.toUpperCase()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const Text('ID de Dispositivo (Entregar al instalador):'),
                              SelectableText(
                                _deviceId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextField(
                                controller: _licenseCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Código de Activación',
                                  border: OutlineInputBorder(),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _applyLicense,
                                  child: const Text('ACTIVAR MODO PRO'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (!auth.isAdmin)
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: const Text('Vincular con Caja Principal'),
                          subtitle: const Text('Escanea el QR del Administrador'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _scanQR,
                        ),

                      const SizedBox(height: 20),

                      ListTile(
                        title: const Text('Modo de la aplicación'),
                        subtitle: Text('Modo actual: $_appMode'),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed:
                                _appMode == 'demo' ? null : () => _setMode('demo'),
                            child: const Text('Demo'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                _appMode == 'pro' ? null : () => _setMode('pro'),
                            child: const Text('Pro'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: _licenseCtrl,
                        decoration: InputDecoration(
                          labelText: 'Licencia',
                          hintText: 'PRO-MIPYPOS-2026',
                          prefixIcon: const Icon(Icons.verified_user),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: _applyLicense,
                          ),
                        ),
                      ),

                      const Divider(height: 24),

                      ListTile(
                        title: const Text('Usuario actual'),
                        subtitle: Text(
                          auth.user?['user']?.toString() ?? 'No autenticado',
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final session = context.read<SessionManager>();
                          await session.loadSession();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sesión recargada')),
                            );
                          }
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
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cerrar'),
                                  ),
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
