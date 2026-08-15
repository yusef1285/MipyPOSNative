import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class SyncService {
  static Future<File> exportToDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final boxes = {
      'users': Hive.box('users').values.toList(),
      'products': Hive.box('products').values.toList(),
      'stockMovements': Hive.box('stockMovements').values.toList(),
      'sales': Hive.box('sales').values.toList(),
      'saleItems': Hive.box('saleItems').values.toList(),
      'cashSessions': Hive.box('cashSessions').values.toList(),
      'syncLog': Hive.box('syncLog').values.toList(),
    };
    final jsonFile = File('${dir.path}/mipypos_backup.json');
    await jsonFile.writeAsString(jsonEncode(boxes));
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      final dest = File('${downloadsDir.path}/mipypos_backup.json');
      await jsonFile.copy(dest.path);
      return dest;
    }
    return jsonFile;
  }

  static Future<void> importFromFile(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    await Hive.box('users').clear();
    await Hive.box('products').clear();
    // ... (same as in sync_screen)
  }
}