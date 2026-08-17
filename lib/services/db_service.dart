// lib/services/db_service.dart
// Servicio central de acceso a datos (Hive). Incluye métodos públicos usados por la app.
// Llamar a `await DBService.init()` desde main() después de `Hive.initFlutter()`.

import 'package:hive/hive.dart';

class DBService {
  DBService._();

  static late Box _users;
  static late Box _products;
  static late Box _sales;
  static late Box _saleItems;
  static late Box _cashSessions;
  static late Box _areas;
  static late Box _movements;
  static late Box _config;

  /// Inicializa las cajas. Llamar desde main() tras Hive.initFlutter().
  static Future<void> init() async {
    // Abrir boxes con nombres simples
    _users = await Hive.openBox('users');
    _products = await Hive.openBox('products');
    _sales = await Hive.openBox('sales');
    _saleItems = await Hive.openBox('sale_items');
    _cashSessions = await Hive.openBox('cash_sessions');
    _areas = await Hive.openBox('areas');
    _movements = await Hive.openBox('movements');
    _config = await Hive.openBox('config');

    // Inicializar modo si no existe
    if (_config.get('app_mode') == null) {
      await _config.put('app_mode', 'primary');
    }

    // Seed users si no existen
    await seedUsers();
  }

  // -------------------------
  // UTIL: convertir a Map<String, dynamic> de forma segura
  // -------------------------
  static Map<String, dynamic> _toMapSafe(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
    }
    // Si es otro tipo (JSObject en web), intentar convertir vía cast dinámico
    try {
      return Map<String, dynamic>.from(raw as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // -------------------------
  // SEED USERS
  // -------------------------
  static Future<void> seedUsers() async {
    try {
      if (_users.isEmpty) {
        await _users.put('admin', {'user': 'admin', 'pass': '1234', 'role': 'admin'});
        await _users.put('cajero', {'user': 'cajero', 'pass': '1234', 'role': 'seller'});
        await _users.put('almacenero', {'user': 'almacenero', 'pass': '1234', 'role': 'storekeeper'});
        await _users.put('invitado', {'user': 'invitado', 'pass': '1234', 'role': 'guest'});
      }
    } catch (_) {
      // Fallback: abrir temporalmente si init no fue llamada
      final box = await Hive.openBox('users');
      try {
        if (box.isEmpty) {
          await box.put('admin', {'user': 'admin', 'pass': '1234', 'role': 'admin'});
        }
      } finally {
        await box.close();
      }
    }
  }

  // -------------------------
  // CONFIG (API pública)
  // -------------------------
  static Future<void> putConfig(String key, dynamic value) async {
    try {
      await _config.put(key, value);
    } catch (_) {
      final box = await Hive.openBox('config');
      try {
        await box.put(key, value);
      } finally {
        await box.close();
      }
    }
  }

  static Future<dynamic> getConfig(String key) async {
    try {
      return _config.get(key);
    } catch (_) {
      final box = await Hive.openBox('config');
      try {
        return box.get(key);
      } finally {
        await box.close();
      }
    }
  }

  static Future<void> deleteConfig(String key) async {
    try {
      await _config.delete(key);
    } catch (_) {
      final box = await Hive.openBox('config');
      try {
        await box.delete(key);
      } finally {
        await box.close();
      }
    }
  }

  static String getAppMode() {
    try {
      return _config.get('app_mode', defaultValue: 'primary') as String;
    } catch (_) {
      return 'primary';
    }
  }

  static Future<void> setAppMode(String mode) async {
    await putConfig('app_mode', mode);
  }

  // -------------------------
  // LOGIN
  // -------------------------
  /// Devuelve Map<String,dynamic> del usuario si credenciales coinciden, null si no.
  /// Implementación robusta para Web y Desktop.
  static Future<Map<String, dynamic>?> login(String username, String pass) async {
    try {
      final raw = _users.get(username);
      if (raw == null) return null;
      final map = _toMapSafe(raw);
      final storedPass = map['pass']?.toString() ?? '';
      if (storedPass != pass) return null;
      return map;
    } catch (e) {
      // Fallback seguro: intentar abrir box temporalmente
      try {
        final box = await Hive.openBox('users');
        try {
          final raw = box.get(username);
          if (raw == null) return null;
          final map = _toMapSafe(raw);
          final storedPass = map['pass']?.toString() ?? '';
          if (storedPass != pass) return null;
          return map;
        } finally {
          await box.close();
        }
      } catch (_) {
        return null;
      }
    }
  }

  // -------------------------
  // USERS
  // -------------------------
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _users.keys) {
      final vRaw = _users.get(k);
      final v = _toMapSafe(vRaw);
      list.add(v);
    }
    return list;
  }

  static Future<void> upsertUser(Map<String, dynamic> user) async {
    final key = user['user']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _users.put(key, user);
  }

  static Future<void> deleteUser(String username) async {
    await _users.delete(username);
  }
  /// Devuelve el usuario por username sin validar contraseña (útil para restore local)
  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      final raw = _users.get(username);
      if (raw == null) return null;
      return _toMapSafe(raw);
    } catch (_) {
      try {
        final box = await Hive.openBox('users');
        try {
          final raw = box.get(username);
          if (raw == null) return null;
          return _toMapSafe(raw);
        } finally {
          await box.close();
        }
      } catch (_) {
        return null;
      }
    }
  }

  // -------------------------
  // AREAS
  // -------------------------
  static Future<List<Map<String, dynamic>>> getAreas() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _areas.keys) {
      final vRaw = _areas.get(k);
      final v = _toMapSafe(vRaw);
      v['id'] = k;
      list.add(v);
    }
    return list;
  }

  static Future<void> addArea(String name) async {
    final id = _areas.length;
    await _areas.put(id, {'id': id, 'name': name});
  }

  // -------------------------
  // PRODUCTS
  // -------------------------
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _products.keys) {
      final raw = _products.get(k);
      final v = _toMapSafe(raw);
      v['id'] = k;
      // Normalizar tipos
      v['stock'] = (v['stock'] is int) ? v['stock'] as int : int.tryParse('${v['stock']}') ?? 0;
      v['price_cash'] = (v['price_cash'] is num) ? (v['price_cash'] as num).toDouble() : double.tryParse('${v['price_cash']}') ?? 0.0;
      v['price_transfer'] = (v['price_transfer'] is num) ? (v['price_transfer'] as num).toDouble() : double.tryParse('${v['price_transfer']}') ?? 0.0;
      list.add(v);
    }
    return list;
  }

  static Future<void> insertProduct(Map<String, dynamic> p) async {
    final id = _products.length;
    await _products.put(id, {
      'name': p['name'] ?? 'Producto ${id + 1}',
      'stock': (p['stock'] is int ? p['stock'] : int.tryParse('${p['stock']}') ?? 0),
      'price_cash': (p['price_cash'] is num ? (p['price_cash'] as num).toDouble() : double.tryParse('${p['price_cash']}') ?? 0.0),
      'price_transfer': (p['price_transfer'] is num ? (p['price_transfer'] as num).toDouble() : double.tryParse('${p['price_transfer']}') ?? 0.0),
      'foto': p['foto'] ?? '',
    });
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> p) async {
    final existingRaw = _products.get(id);
    final existing = _toMapSafe(existingRaw);
    existing.addAll({
      'name': p['name'] ?? existing['name'],
      'stock': (p['stock'] is int ? p['stock'] : int.tryParse('${p['stock']}') ?? existing['stock'] ?? 0),
      'price_cash': (p['price_cash'] is num ? (p['price_cash'] as num).toDouble() : double.tryParse('${p['price_cash']}') ?? existing['price_cash'] ?? 0.0),
      'price_transfer': (p['price_transfer'] is num ? (p['price_transfer'] as num).toDouble() : double.tryParse('${p['price_transfer']}') ?? existing['price_transfer'] ?? 0.0),
      'foto': p['foto'] ?? existing['foto'] ?? '',
    });
    await _products.put(id, existing);
  }

  static Future<void> addStock(int productId, int qty) async {
    final productRaw = _products.get(productId);
    final product = _toMapSafe(productRaw);
    final current = (product['stock'] ?? 0) is int ? product['stock'] as int : int.tryParse('${product['stock']}') ?? 0;
    product['stock'] = current + qty;
    await _products.put(productId, product);
  }

  static Future<void> removeStock(int productId, int qty) async {
    final pRaw = _products.get(productId);
    final p = _toMapSafe(pRaw);
    final current = (p['stock'] ?? 0) is int ? p['stock'] as int : int.tryParse('${p['stock']}') ?? 0;
    p['stock'] = (current - qty).clamp(0, current);
    await _products.put(productId, p);
  }

  /// Devuelve un mapa nombre -> stock inicial (útil para cierres)
  static Future<Map<String, dynamic>> getProductsStockMapStart() async {
    final map = <String, dynamic>{};
    final products = await getProducts();
    for (var p in products) {
      final name = p['name']?.toString() ?? '';
      final stock = p['stock'] ?? 0;
      map[name] = stock;
    }
    return map;
  }

  // -------------------------
  // SALES
  // -------------------------
  static Future<int> createSale(
    double total,
    String method,
    String user, {
    int? sessionId,
  }) async {
    int? sid = sessionId;
    if (sid == null) {
      final session = await getOpenCash();
      if (session == null) {
        throw Exception("No hay caja abierta");
      }
      sid = (session['id'] is int) ? session['id'] as int : int.tryParse('${session['id']}');
    }

    final id = _sales.length;
    await _sales.put(id, {
      'id': id,
      'total': total,
      'method': method,
      'user': user,
      'date': DateTime.now().toIso8601String(),
      'session_id': sid,
    });

    return id;
  }

  static Future<void> insertSaleItem(Map<String, dynamic> item) async {
    final id = _saleItems.length;
    await _saleItems.put(id, item);
  }

  static Future<List<Map<String, dynamic>>> getSaleItems() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _saleItems.keys) {
      final vRaw = _saleItems.get(k);
      final v = _toMapSafe(vRaw);
      list.add(v);
    }
    return list;
  }

  static Future<List<Map<String, dynamic>>> getSalesOfSession(int sessionId) async {
    final list = <Map<String, dynamic>>[];
    for (var k in _sales.keys) {
      final vRaw = _sales.get(k);
      final v = _toMapSafe(vRaw);
      final sid = (v['session_id'] ?? v['cash_session_id']);
      final sidInt = (sid is int) ? sid : int.tryParse('$sid');
      if (sidInt == sessionId) {
        list.add(v);
      }
    }
    return list;
  }

  static Future<List<Map<String, dynamic>>> getSalesOfDay() async {
    final list = <Map<String, dynamic>>[];
    final today = DateTime.now();

    for (var k in _sales.keys) {
      final vRaw = _sales.get(k);
      final v = _toMapSafe(vRaw);
      final date = DateTime.tryParse(v['date'] ?? '');
      if (date != null && date.year == today.year && date.month == today.month && date.day == today.day) {
        list.add(v);
      }
    }

    return list;
  }

  // -------------------------
  // MOVEMENTS
  // -------------------------
  static Future<void> createMovement({
    required int productIndex,
    required int fromAreaId,
    required int toAreaId,
    required int qty,
    required String fromUser,
    required String toUser,
    required bool confirmedBySeller,
  }) async {
    final id = _movements.length;
    await _movements.put(id, {
      'id': id,
      'product_index': productIndex,
      'from_area': fromAreaId,
      'to_area': toAreaId,
      'qty': qty,
      'from_user': fromUser,
      'to_user': toUser,
      'confirmed_by_seller': confirmedBySeller,
      'date': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMovementsOfDay() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _movements.keys) {
      final vRaw = _movements.get(k);
      final v = _toMapSafe(vRaw);
      v['id'] = k;
      list.add(v);
    }
    return list;
  }

  // -------------------------
  // CASH SESSIONS
  // -------------------------
  static Future<int> openCashSession(double fund) async {
    final id = _cashSessions.length;
    await _cashSessions.put(id, {
      'id': id,
      'open': DateTime.now().toIso8601String(),
      'close': null,
      'fund': fund,
      'final_cash': 0.0,
      'expected_cash': 0.0,
    });
    return id;
  }

  static Future<Map<String, dynamic>?> getOpenCash() async {
    for (var k in _cashSessions.keys) {
      final vRaw = _cashSessions.get(k);
      final v = _toMapSafe(vRaw);
      if (v['close'] == null) {
        // Normalizar id a int si es posible
        v['id'] = (v['id'] is int) ? v['id'] as int : int.tryParse('${v['id']}') ?? k;
        return v;
      }
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getCashSessions() async {
    final list = <Map<String, dynamic>>[];
    for (var k in _cashSessions.keys) {
      final vRaw = _cashSessions.get(k);
      final v = _toMapSafe(vRaw);
      v['id'] = k;
      list.add(v);
    }
    return list;
  }

  static Future<void> closeCashSession(
    int id, {
    Map<String, dynamic>? productsStart,
    Map<String, dynamic>? productsEnd,
    Map<String, int>? cashCount,
    Map<String, dynamic>? transferCount,
    double? fund,
    double? finalCash,
    double? expectedCash,
  }) async {
    final vRaw = _cashSessions.get(id);
    if (vRaw == null) throw Exception('Sesión no encontrada');
    final v = _toMapSafe(vRaw);
    v['close'] = DateTime.now().toIso8601String();
    if (finalCash != null) v['final_cash'] = finalCash;
    if (expectedCash != null) v['expected_cash'] = expectedCash;
    if (fund != null) v['fund'] = fund;
    if (productsStart != null) v['products_start'] = productsStart;
    if (productsEnd != null) v['products_end'] = productsEnd;
    if (cashCount != null) v['cash_count'] = cashCount;
    if (transferCount != null) v['transfer_count'] = transferCount;
    await _cashSessions.put(id, v);
  }
}
