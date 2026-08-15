import 'package:flutter/material.dart';
import '../services/db_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;

  final roles = ['admin', 'supervisor', 'seller', 'storekeeper'];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
    users = await DBService.getUsers();
    setState(() => loading = false);
  }

  void createUser() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'seller';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            DropdownButtonFormField<String>(
              initialValue: role,
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: 'Rol'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBService.upsertUser({
                'user': userCtrl.text.trim(),
                'pass': passCtrl.text.trim(),
                'role': role,
              });

              Navigator.pop(context);
              loadUsers();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void editUser(Map<String, dynamic> u) {
    final passCtrl = TextEditingController(text: u['pass']);
    String role = u['role'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar usuario: ${u['user']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            DropdownButtonFormField<String>(
              initialValue: role,
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: 'Rol'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBService.upsertUser({
                'user': u['user'],
                'pass': passCtrl.text.trim(),
                'role': role,
              });

              Navigator.pop(context);
              loadUsers();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void deleteUser(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar usuario "${u['user']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBService.deleteUser(u['user']);
              Navigator.pop(context);
              loadUsers();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createUser,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(u['user']),
                    subtitle: Text('Rol: ${u['role']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => editUser(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteUser(u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
