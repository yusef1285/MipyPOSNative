import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<void> generateTicket(Uint8List bytes) async {
    final dir = await getDownloadsDirectory();
    final file = File('${dir!.path}/ticket_mipypos.txt');

    // Guardamos como TXT para máxima compatibilidad offline
    await file.writeAsBytes(bytes);
  }
}
