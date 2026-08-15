import 'package:flutter/material.dart';
import '../services/export_service.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportando...")),
    );

    await action();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportación completada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exportar reportes")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ElevatedButton(
            onPressed: () => _run(context, ExportService.exportVentasDia),
            child: const Text("Exportar ventas del día"),
          ),
          ElevatedButton(
            onPressed: () => _run(context, ExportService.exportMovimientosDia),
            child: const Text("Exportar movimientos del día"),
          ),
          ElevatedButton(
            onPressed: () => _run(context, ExportService.exportInventario),
            child: const Text("Exportar inventario"),
          ),
          ElevatedButton(
            onPressed: () => _run(context, ExportService.exportProductosVendidos),
            child: const Text("Exportar productos vendidos"),
          ),
          ElevatedButton(
            onPressed: () => _run(context, ExportService.exportTodo),
            child: const Text("Exportar TODO"),
          ),
        ],
      ),
    );
  }
}
