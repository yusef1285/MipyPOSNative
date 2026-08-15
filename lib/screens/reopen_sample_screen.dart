// lib/screens/reopen_sample_screen.dart
import 'package:flutter/material.dart';
import '../controllers/cierre_service.dart';
import '../controllers/product_repository.dart';
import '../services/db_service.dart';

class ReopenSampleScreen extends StatefulWidget {
  final int sessionId;

  const ReopenSampleScreen({super.key, required this.sessionId});

  @override
  State<ReopenSampleScreen> createState() => _ReopenSampleScreenState();
}

class _ReopenSampleScreenState extends State<ReopenSampleScreen> {
  bool loading = true;
  bool requesting = false;
  List<Map<String, dynamic>> sample = [];
  Map<int, bool> verified = {};

  @override
  void initState() {
    super.initState();
    _loadSample();
  }

  Future<void> _loadSample() async {
    setState(() => loading = true);
    try {
      final stored = await CierreService().getReopenSample(widget.sessionId);
      if (stored != null) {
        final list = List<Map<String, dynamic>>.from(stored['sample'] ?? []);
        sample = list;
      } else {
        final s = await CierreService().reopenWithSample(widget.sessionId);
        sample = s;
      }
      verified = {for (var p in sample) p['id'] as int: false};
    } catch (e) {
      sample = [];
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleVerify(int id) async {
    setState(() => verified[id] = !(verified[id] ?? false));
  }

  Future<void> _finishVerification() async {
    final notVerified = verified.entries.where((e) => e.value == false).map((e) => e.key).toList();
    if (notVerified.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Productos sin verificar'),
          content: Text('Quedan ${notVerified.length} productos sin verificar. ¿Deseas continuar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    final key = 'reopen_verified_${widget.sessionId}';
    final result = {
      'verified_at': DateTime.now().toIso8601String(),
      'verified_ids': verified.entries.where((e) => e.value).map((e) => e.key).toList(),
      'not_verified_ids': verified.entries.where((e) => !e.value).map((e) => e.key).toList(),
    };
    await DBService.putConfig(key, result);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verificación guardada.')));
    }
    Navigator.pop(context);
  }

  Widget _buildList() {
    if (sample.isEmpty) {
      return const Center(child: Text('No hay productos en el muestreo.'));
    }

    return ListView.builder(
      itemCount: sample.length,
      itemBuilder: (_, i) {
        final p = sample[i];
        final id = p['id'] as int;
        final name = p['name'] ?? '';
        final stock = p['stock'] ?? 0;
        final isVerified = verified[id] ?? false;

        return Card(
          child: ListTile(
            title: Text(name),
            subtitle: Text('Stock sugerido: $stock'),
            trailing: Checkbox(
              value: isVerified,
              onChanged: (_) => _toggleVerify(id),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reapertura - Muestreo 10%'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSample),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : _buildList(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: sample.isEmpty ? null : _finishVerification,
          child: const Text('Finalizar verificación'),
        ),
      ),
    );
  }
}
