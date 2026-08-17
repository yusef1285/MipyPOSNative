import 'package:hive/hive.dart';
import 'db_service.dart';

class LicenseService {
  static late Box _license;

  static Future<void> init() async {
    _license = await Hive.openBox('license');
  }

  static String? getLicenseCode() {
    return _license.get('code');
  }

  static Future<void> setLicenseCode(String code) async {
    await _license.put('code', code);
  }

  static bool isProActive() {
    final code = getLicenseCode();
    if (code == null) return false;
    return code.startsWith('PRO-');
  }

  static Future<void> applyModeFromLicense() async {
    if (isProActive()) {
      await DBService.setAppMode('pro');
    } else {
      await DBService.setAppMode('primary');
    }
  }
}
