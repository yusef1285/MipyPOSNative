import 'dart:io';
import 'package:hive/hive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'db_service.dart';

class LicenseService {
  static Box? _license;
  static const String _salt = "MIPY_SECRET_2025";

  static Future<void> init() async {
    _license = await Hive.openBox('license');
  }

  /// Genera un ID único del dispositivo para que el instalador cree la licencia
  static Future<String> getDeviceIdentifier() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.model}_${androidInfo.id}".toUpperCase().replaceAll(' ', '');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "IOS_DEVICE";
    }
    return "GENERIC_DEVICE";
  }

  static String? getLicenseCode() {
    return _license?.get('code')?.toString();
  }

  /// Valida si la licencia corresponde a este hardware específico
  static Future<bool> validateLicense(String code) async {
    final deviceId = await getDeviceIdentifier();
    final normalized = code.trim().toUpperCase();
    
    // Algoritmo de validación: La licencia debe contener el ID del dispositivo
    // más un prefijo de seguridad definido por el instalador.
    // Ejemplo de licencia válida: "PRO-MIPY-[DEVICE_ID]"
    if (normalized == "PRO-MIPY-$deviceId") {
      return true;
    }
    return false;
  }

  static Future<void> activatePro(String code) async {
    final isValid = await validateLicense(code);
    if (isValid) {
      await _license?.put('code', code);
      await DBService.setAppMode('pro');
    }
  }

  static bool isProActive() {
    final code = getLicenseCode();
    // Esta verificación es síncrona para la UI, asume que si el código está guardado
    // es porque ya fue validado al insertarse.
    return code != null && code.startsWith('PRO-MIPY-');
  }

  static Future<void> ensureDemoModeIfNoLicense() async {
    if (!isProActive()) {
      await _license?.put('code', '');
      await DBService.setAppMode('demo');
    } else {
      await DBService.setAppMode('pro');
    }
  }
}
