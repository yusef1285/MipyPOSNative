// lib/native_bridge.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'services/db_service.dart';

class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel('com.mipypos.app/logic');

  /// Debe llamarse temprano desde `main()` después de inicializar servicios (Hive, DBService, etc.)
  static void setup() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getProductsCount':
          try {
            final products = await DBService.getProducts();
            return products.length;
          } catch (e) {
            return 0;
          }
        case 'ping':
          return 'pong';
        default:
          throw PlatformException(
              code: 'NOT_IMPLEMENTED',
              message: 'Method not implemented: ${call.method}');
      }
    });
  }
}
