import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/db_service.dart';
import '../widgets/branding_widgets.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Versión'),
            subtitle: Text('MipyPOS 1.0 — Desktop / Web listo'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Vaciar base de datos'),
            subtitle: const Text('Eliminar productos, ventas y caja'),
            onTap: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirmar"),
                  content: const Text("¿Vaciar toda la base de datos?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar")),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Sí, borrar")),
                  ],
                ),
              );

              if (confirm == true) {
                await DBService.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Base de datos vaciada")),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: () {
              context.read<AuthController>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CopyrightText(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
