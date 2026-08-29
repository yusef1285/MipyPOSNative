import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/db_service.dart';

class ShiftCloseScreen extends StatelessWidget {
  final int sessionId;
  final Map<String, dynamic> resumen;

  const ShiftCloseScreen({
    super.key,
    required this.sessionId,
    required this.resumen,
  });

  Future<void> exportShiftCSV(
      Map<String, dynamic> resumen, double contado) async {
    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/cierre_turno_mipypos.csv');

    final buffer = StringBuffer();
    buffer.writeln("fecha,ventas,efectivo,transferencia,contado,diferencia");

    buffer.writeln("${resumen['fecha']},"
        "${resumen['ventas']},"
        "${resumen['efectivo']},"
        "${resumen['transferencia']},"
        "$contado,"
        "${contado - (resumen['efectivo'] + resumen['transferencia'])}");

    await file.writeAsString(buffer.toString());
  }

  Future<void> exportShiftExcel(
      Map<String, dynamic> resumen, double contado) async {
    final excel = Excel.createExcel();
    final sheet = excel['Cierre'];

    sheet.appendRow([
      "Fecha",
      "Ventas",
      "Efectivo",
      "Transferencia",
      "Contado",
      "Diferencia"
    ]);

    sheet.appendRow([
      resumen['fecha'],
      resumen['ventas'],
      resumen['efectivo'],
      resumen['transferencia'],
      contado,
      contado - (resumen['efectivo'] + resumen['transferencia']),
    ]);

    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/cierre_turno_mipypos.xlsx');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(excel.encode()!);
  }

  Future<void> exportShiftPDF(
      Map<String, dynamic> resumen, double contado) async {
    final pdf = pw.Document();

    final efectivo = resumen['efectivo'];
    final transferencia = resumen['transferencia'];
    final ventas = resumen['ventas'];
    final diferencia = contado - (efectivo + transferencia);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Cierre de turno MipyPOS",
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text("Fecha: ${resumen['fecha']}"),
              pw.Text("Ventas totales: \$${ventas.toStringAsFixed(2)}"),
              pw.Text("Efectivo: \$${efectivo.toStringAsFixed(2)}"),
              pw.Text("Transferencia: \$${transferencia.toStringAsFixed(2)}"),
              pw.SizedBox(height: 20),
              pw.Text("Monto contado: \$${contado.toStringAsFixed(2)}"),
              pw.Text("Diferencia: \$${diferencia.toStringAsFixed(2)}"),
            ],
          );
        },
      ),
    );

    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/cierre_turno_mipypos.pdf');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final efectivo = resumen['efectivo'];
    final transferencia = resumen['transferencia'];
    final ventas = resumen['ventas'];

    final totalEsperado = efectivo + transferencia;

    final cierreCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Cerrar turno")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ventas del turno:",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text("Efectivo: \$${efectivo.toStringAsFixed(2)}"),
            Text("Transferencia: \$${transferencia.toStringAsFixed(2)}"),
            Text("Total: \$${ventas.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            Text("Monto contado en caja:",
                style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: cierreCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto contado",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Confirmar cierre"),
              onPressed: () async {
                final contado = double.tryParse(cierreCtrl.text) ?? 0.0;

                await DBService.closeCash(
                  sessionId,
                  contado,
                  totalEsperado,
                );

                await exportShiftCSV(resumen, contado);
                await exportShiftExcel(resumen, contado);
                await exportShiftPDF(resumen, contado);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Turno cerrado. Diferencia: \$${(contado - totalEsperado).toStringAsFixed(2)}",
                    ),
                  ),
                );

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
