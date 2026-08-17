// lib/services/pdf_service_web.dart
import 'dart:html' as html;
import 'dart:typed_data';

class PdfService {
  /// Genera y descarga un PDF en Web usando Blob + AnchorElement.
  static Future<void> generateTicket(Uint8List bytes) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'ticket.pdf'
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
