// lib/screens/sync_screen_web.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../services/db_service.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  // Ejemplo de datos de productos
  List<Map<String, dynamic>> _dummyProducts() => [
        {'id': 1, 'nombre': 'Café', 'precio': 25.0},
        {'id': 2, 'nombre': 'Pan', 'precio': 10.0},
      ];

  Future<Map<String, dynamic>> _buildExportData() async {
    final productos = await DBService.getProducts();
    final ventas = await DBService.getSalesOfDay();
    final movimientos = await DBService.getMovements();
    final caja = await DBService.getCashSessions();

    return {
      'productos': productos,
      'ventas': ventas,
      'movimientos': movimientos,
      'caja': caja,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  void _exportJson(BuildContext context, Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final blob = html.Blob([jsonString], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'backup_mipypos.json'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void _importJson(BuildContext context, Map<String, dynamic> data) async {
    if (data['productos'] is List) {
      for (final item in List.from(data['productos'])) {
        if (item is Map<String, dynamic>) {
          await DBService.upsertProduct(item);
        } else if (item is Map) {
          await DBService.upsertProduct(Map<String, dynamic>.from(item));
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON importado correctamente')),
    );
  }

  void _openJsonUpload(BuildContext context) {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((event) {
        final content = reader.result as String;
        final data = jsonDecode(content) as Map<String, dynamic>;
        _importJson(context, data);
      });
    });
  }

  Future<void> _exportProductsCsv(BuildContext context) async {
    final products = await DBService.getProducts();
    final buffer = StringBuffer();
    buffer.writeln('id;nombre;stock;price_cash;price_transfer');

    for (final p in products) {
      buffer.writeln(
          '${p['id']};${p['name']};${p['stock']};${p['price_cash']};${p['price_transfer']}');
    }

    final blob = html.Blob([buffer.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'productos_mipypos.csv'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // Exportar CSV de cierre de turno (ejemplo)
  void _exportShiftCsv(BuildContext context) async {
    final cierre = await DBService.getShiftSummary();

    final buffer = StringBuffer();
    buffer.writeln('fecha;ventas;efectivo;tarjeta');
    buffer.writeln(
        '${cierre['fecha']};${cierre['ventas']};${cierre['efectivo']};${cierre['tarjeta']}');

    final blob = html.Blob([buffer.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'cierre_turno_mipypos.csv'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void _importProductsCsvWeb(BuildContext context) {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoadEnd.listen((event) async {
        final content = reader.result as String;
        final lines = content.split('\n');

        for (int i = 1; i < lines.length; i++) {
          final row = lines[i].trim().split(';');
          if (row.length < 4) continue;

          final product = {
            'id': int.tryParse(row[0]) ?? 0,
            'name': row[1],
            'price': double.tryParse(row[2]) ?? 0.0,
            'stock': int.tryParse(row[3]) ?? 0,
          };

          await DBService.upsertProduct(product);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Productos importados correctamente')),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización (Web)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final data = await _buildExportData();
                _exportJson(context, data);
              },
              child: const Text('Exportar JSON (backup)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openJsonUpload(context),
              child: const Text('Importar JSON (restore)'),
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () => _exportProductsCsv(context),
              child: const Text('Exportar productos (CSV)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _exportShiftCsv(context),
              child: const Text('Exportar cierre de turno (CSV)'),
            ),
          ],
        ),
      ),
    );
  }
}
