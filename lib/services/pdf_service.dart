import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<Directory> _getSafeWriteDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      if (docs.path.isNotEmpty) return docs;
    } catch (_) {}

    try {
      final support = await getApplicationSupportDirectory();
      if (support.path.isNotEmpty) return support;
    } catch (_) {}

    final fallback = Directory('${Directory.current.path}/mipypos_data');
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  static Future<void> generateTicket(Uint8List bytes) async {
    final dir = await _getSafeWriteDirectory();
    final file = File('${dir.path}/ticket_mipypos.txt');

    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }
}
