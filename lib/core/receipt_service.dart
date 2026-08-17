import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReceiptService {
  static Future<File> generateReceipt({
    required List items,
    required double total,
    required String method,
    required int saleId,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("MIPYPOS", style: const pw.TextStyle(fontSize: 20)),
              pw.Text("Ticket #$saleId"),
              pw.Text("Método: $method"),
              pw.Divider(),
              ...items.map((i) =>
                  pw.Text("${i['name']} x${i['quantity']}  \$${i['price']}")),
              pw.Divider(),
              pw.Text("TOTAL: \$${total.toStringAsFixed(2)}"),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/ticket_$saleId.pdf");

    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
