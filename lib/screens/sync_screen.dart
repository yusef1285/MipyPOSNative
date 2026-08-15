import 'package:flutter/material.dart';
import '../services/db_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool syncing = false;

  Future<void> syncProducts() async {
    setState(() => syncing = true);

    // Simulación de sincronización offline-first
    final sampleProducts = [
      {
        'name': 'Café Americano',
        'stock': 20,
        'price_cash': 50,
        'price_transfer': 60,
      },
      {
        'name': 'Pan con tortilla',
        'stock': 15,
        'price_cash': 40,
        'price_transfer': 50,
      },
    ];

    for (var p in sampleProducts) {
      await DBService.upsertProduct(p);
    }

    setState(() => syncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sincronización completada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sincronización")),
      body: Center(
        child: syncing
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text("Sincronizar productos"),
                onPressed: syncProducts,
              ),
      ),
    );
  }
}
