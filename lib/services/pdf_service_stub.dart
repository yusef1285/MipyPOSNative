import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<void> generateTicket(Uint8List bytes) async {}

  static Future<File> generateTicketNative({
    required List<Map<String, dynamic>> items,
    required double total,
    required String method,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MipyPOS', style: const pw.TextStyle(fontSize: 28)),
            pw.Divider(),
            pw.Text('Método: $method'),
            pw.Text('Total: \$${total.toStringAsFixed(2)}'),
            pw.SizedBox(height: 20),
            pw.Text('Productos:', style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 10),
            ...items.map(
                (i) => pw.Text('${i['name']} x${i['qty']} = \$${i['price']}')),
          ],
        ),
      ),
    );

    final file = File('${Directory.current.path}/ticket_mipypos.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
