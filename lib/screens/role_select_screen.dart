import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'home_shell.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Rol')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Selecciona tu rol',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Administrador'),
              onPressed: () {
                auth.login({'role': 'admin'});
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeShell()),
                );
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.supervisor_account),
              label: const Text('Supervisor'),
              onPressed: () {
                auth.login({'role': 'supervisor'});
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeShell()),
                );
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Cajero'),
              onPressed: () {
                auth.login({'role': 'cajero'});
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeShell()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
