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
      await _config.put('app_mode', 'demo');
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

  static Future<void> clearAll() async {
    try {
      await _users.clear();
      await _products.clear();
      await _sales.clear();
      await _saleItems.clear();
      await _cashSessions.clear();
      await _areas.clear();
      await _movements.clear();
      await _config.clear();
      await _config.put('app_mode', 'demo');
      await seedUsers();
    } catch (_) {
      final usersBox = await Hive.openBox('users');
      final productsBox = await Hive.openBox('products');
      final salesBox = await Hive.openBox('sales');
      final saleItemsBox = await Hive.openBox('sale_items');
      final cashSessionsBox = await Hive.openBox('cash_sessions');
      final areasBox = await Hive.openBox('areas');
      final movementsBox = await Hive.openBox('movements');
      final configBox = await Hive.openBox('config');

      try {
        await usersBox.clear();
        await productsBox.clear();
        await salesBox.clear();
        await saleItemsBox.clear();
        await cashSessionsBox.clear();
        await areasBox.clear();
        await movementsBox.clear();
        await configBox.clear();
        await configBox.put('app_mode', 'demo');
      } finally {
        await usersBox.close();
        await productsBox.close();
        await salesBox.close();
        await saleItemsBox.close();
        await cashSessionsBox.close();
        await areasBox.close();
        await movementsBox.close();
        await configBox.close();
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
      final value = _config.get('app_mode', defaultValue: 'demo');
      final mode = value?.toString() ?? 'demo';
      return (mode == 'pro' || mode == 'demo') ? mode : 'demo';
    } catch (_) {
      return 'demo';
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
      v['subcategory'] = (v['subcategory'] ?? '').toString();
      v['foto'] = (v['foto'] ?? '').toString();
      list.add(v);
    }
    return list;
  }

  static Future<void> insertProduct(Map<String, dynamic> p) async {
    final id = _products.length;
    await _products.put(id, {
      'name': p['name'] ?? 'Producto ${id + 1}',
      'subcategory': (p['subcategory'] ?? '').toString(),
      'stock': (p['stock'] is int ? p['stock'] : int.tryParse('${p['stock']}') ?? 0),
      'price_cash': (p['price_cash'] is num ? (p['price_cash'] as num).toDouble() : double.tryParse('${p['price_cash']}') ?? 0.0),
      'price_transfer': (p['price_transfer'] is num ? (p['price_transfer'] as num).toDouble() : double.tryParse('${p['price_transfer']}') ?? 0.0),
      'foto': (p['foto'] ?? '').toString(),
    });
  }

  static Future<void> upsertProduct(Map<String, dynamic> p) async {
    final name = (p['name'] ?? '').toString();
    if (name.isEmpty) return;

    final existingIndex = _products.keys.firstWhere(
      (key) {
        final raw = _products.get(key);
        final item = _toMapSafe(raw);
        return (item['name'] ?? '').toString() == name;
      },
      orElse: () => null,
    );

    if (existingIndex != null) {
      final current = _toMapSafe(_products.get(existingIndex));
      final updated = <String, dynamic>{
        ...current,
        'name': name,
        'subcategory': (p['subcategory'] ?? current['subcategory'] ?? '').toString(),
        'stock': (p['stock'] is int ? p['stock'] : int.tryParse('${p['stock']}') ?? (current['stock'] ?? 0)),
        'price_cash': (p['price_cash'] is num ? (p['price_cash'] as num).toDouble() : double.tryParse('${p['price_cash']}') ?? (current['price_cash'] ?? 0.0)),
        'price_transfer': (p['price_transfer'] is num ? (p['price_transfer'] as num).toDouble() : double.tryParse('${p['price_transfer']}') ?? (current['price_transfer'] ?? 0.0)),
        'foto': (p['foto'] ?? current['foto'] ?? '').toString(),
      };
      await _products.put(existingIndex, updated);
      return;
    }

    await insertProduct(p);
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> p) async {
    final existingRaw = _products.get(id);
    final existing = _toMapSafe(existingRaw);
    existing.addAll({
      'name': p['name'] ?? existing['name'],
      'subcategory': (p['subcategory'] ?? existing['subcategory'] ?? '').toString(),
      'stock': (p['stock'] is int ? p['stock'] : int.tryParse('${p['stock']}') ?? existing['stock'] ?? 0),
      'price_cash': (p['price_cash'] is num ? (p['price_cash'] as num).toDouble() : double.tryParse('${p['price_cash']}') ?? existing['price_cash'] ?? 0.0),
      'price_transfer': (p['price_transfer'] is num ? (p['price_transfer'] as num).toDouble() : double.tryParse('${p['price_transfer']}') ?? existing['price_transfer'] ?? 0.0),
      'foto': (p['foto'] ?? existing['foto'] ?? '').toString(),
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

  static Future<List<Map<String, dynamic>>> getMovements() async {
    return getMovementsOfDay();
  }

  static Future<double> todaySales() async {
    final sales = await getSalesOfDay();
    double total = 0;
    for (final sale in sales) {
      total += (sale['total'] is num ? (sale['total'] as num).toDouble() : double.tryParse('${sale['total']}') ?? 0.0);
    }
    return total;
  }

  static Future<List<Map<String, dynamic>>> topProducts() async {
    final items = await getSaleItems();
    final map = <String, Map<String, dynamic>>{};

    for (final item in items) {
      final productId = item['product_id'];
      final product = await getProducts();
      final productName = product.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => {'name': 'Desconocido'},
      )['name'] ?? 'Desconocido';

      final qty = (item['quantity'] is int) ? item['quantity'] as int : int.tryParse('${item['quantity']}') ?? 0;
      final entry = map.putIfAbsent(productName, () => {'name': productName, 'total_qty': 0});
      entry['total_qty'] = (entry['total_qty'] as int? ?? 0) + qty;
    }

    final result = map.values.toList();
    result.sort((a, b) => ((b['total_qty'] as int?) ?? 0).compareTo((a['total_qty'] as int?) ?? 0));
    return result;
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
    List<Map<String, dynamic>>? payments,
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
      'payments': payments ?? [],
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

  static double _toSaleAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Future<Map<String, double>> getSessionPaymentSummary(int sessionId) async {
    final summary = <String, double>{
      'ventas': 0.0,
      'efectivo': 0.0,
      'transferencia': 0.0,
      'tarjeta': 0.0,
      'total': 0.0,
    };

    final sales = await getSalesOfSession(sessionId);
    for (final sale in sales) {
      final total = _toSaleAmount(sale['total']);
      summary['ventas'] = (summary['ventas'] ?? 0.0) + total;
      summary['total'] = (summary['total'] ?? 0.0) + total;

      final rawPayments = sale['payments'];
      final payments = rawPayments is List ? rawPayments : const <dynamic>[];
      if (payments.isNotEmpty) {
        for (final payment in payments) {
          final paymentMap = _toMapSafe(payment);
          final method = (paymentMap['method'] ?? '').toString().toLowerCase();
          final amount = _toSaleAmount(paymentMap['amount']);
          if (method.contains('efectivo')) {
            summary['efectivo'] = (summary['efectivo'] ?? 0.0) + amount;
          } else if (method.contains('transferencia') || method.contains('tarjeta')) {
            summary['transferencia'] = (summary['transferencia'] ?? 0.0) + amount;
          }
        }
        continue;
      }

      final method = (sale['method'] ?? '').toString().toLowerCase();
      if (method.contains('mixto')) {
        summary['efectivo'] = (summary['efectivo'] ?? 0.0) + total * 0.5;
        summary['transferencia'] = (summary['transferencia'] ?? 0.0) + total * 0.5;
      } else if (method.contains('efectivo')) {
        summary['efectivo'] = (summary['efectivo'] ?? 0.0) + total;
      } else if (method.contains('transferencia') || method.contains('tarjeta')) {
        summary['transferencia'] = (summary['transferencia'] ?? 0.0) + total;
      }
    }

    return summary;
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

  static Future<List<Map<String, dynamic>>> getSalesOfOpenSession() async {
    final open = await getOpenCash();
    if (open == null) return const <Map<String, dynamic>>[];

    final sessionId = (open['id'] is int) ? open['id'] as int : int.tryParse('${open['id']}') ?? -1;
    if (sessionId < 0) return const <Map<String, dynamic>>[];

    return getSalesOfSession(sessionId);
  }

  static Future<Map<String, int>> getProductSalesQtyOfDay() async {
    final sales = await getSalesOfOpenSession();
    final saleItems = await getSaleItems();
    final products = await getProducts();
    final productNameById = <int, String>{
      for (final product in products)
        ((product['id'] is int) ? product['id'] as int : int.tryParse('${product['id']}') ?? -1):
            (product['name'] ?? '').toString(),
    };
    final map = <String, int>{};

    for (final item in saleItems) {
      final saleId = item['sale_id'];
      final sale = sales.firstWhere(
        (entry) => (entry['id'] ?? -1) == saleId,
        orElse: () => <String, dynamic>{},
      );
      if (sale.isEmpty) continue;

      final productId = (item['product_id'] is int)
          ? item['product_id'] as int
          : int.tryParse('${item['product_id']}') ?? -1;
      final productName = productNameById[productId] ?? (item['name'] ?? '').toString();
      if (productName.isEmpty) continue;

      final qty = (item['quantity'] is int) ? item['quantity'] as int : int.tryParse('${item['quantity']}') ?? 0;
      map[productName] = (map[productName] ?? 0) + qty;
    }

    return map;
  }

  static Future<Map<String, int>> getProductEntriesQtyOfDay() async {
    final map = <String, int>{};
    final movements = await getMovementsOfDay();
    final today = DateTime.now();

    for (final movement in movements) {
      final date = DateTime.tryParse(movement['date'] ?? '');
      if (date == null || date.year != today.year || date.month != today.month || date.day != today.day) continue;

      final type = (movement['type'] ?? '').toString().toLowerCase();
      if (type != 'entrada') continue;

      final productName = (movement['product_name'] ?? '').toString();
      if (productName.isEmpty) continue;

      final qty = (movement['qty'] is int) ? movement['qty'] as int : int.tryParse('${movement['qty']}') ?? 0;
      map[productName] = (map[productName] ?? 0) + qty;
    }

    return map;
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
    String type = 'transfer',
    String? productName,
    String? note,
  }) async {
    final id = _movements.length;
    await _movements.put(id, {
      'id': id,
      'type': type,
      'product_index': productIndex,
      'product_name': productName ?? '',
      'from_area': fromAreaId,
      'to_area': toAreaId,
      'qty': qty,
      'from_user': fromUser,
      'to_user': toUser,
      'confirmed_by_seller': confirmedBySeller,
      'note': note ?? '',
      'date': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> recordProductEntry({
    required String productName,
    required int qty,
    String user = 'admin',
    String note = 'Entrada manual',
  }) async {
    if (qty <= 0) return;

    final products = await getProducts();
    final matchIndex = products.indexWhere((p) => (p['name'] ?? '').toString().toLowerCase() == productName.trim().toLowerCase());

    if (matchIndex >= 0) {
      final existing = products[matchIndex];
      final currentStock = (existing['stock'] is int) ? existing['stock'] as int : int.tryParse('${existing['stock']}') ?? 0;
      await updateProduct(matchIndex, {
        ...existing,
        'stock': currentStock + qty,
      });
    } else {
      await insertProduct({
        'name': productName,
        'subcategory': '',
        'stock': qty,
        'price_cash': 0.0,
        'price_transfer': 0.0,
        'foto': '',
      });
    }

    final productList = await getProducts();
    final product = productList.firstWhere(
      (p) => (p['name'] ?? '').toString().toLowerCase() == productName.trim().toLowerCase(),
      orElse: () => {'id': -1, 'name': productName},
    );
    final productId = (product['id'] is int) ? product['id'] as int : int.tryParse('${product['id']}') ?? -1;

    await createMovement(
      productIndex: productId,
      fromAreaId: -1,
      toAreaId: -1,
      qty: qty,
      fromUser: user,
      toUser: user,
      confirmedBySeller: true,
      type: 'entrada',
      productName: productName,
      note: note,
    );
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
    final productsSnapshot = <String, dynamic>{};
    for (final product in await getProducts()) {
      final name = (product['name'] ?? '').toString();
      if (name.isEmpty) continue;
      productsSnapshot[name] = (product['stock'] is int) ? product['stock'] as int : int.tryParse('${product['stock']}') ?? 0;
    }

    await _cashSessions.put(id, {
      'id': id,
      'open': DateTime.now().toIso8601String(),
      'close': null,
      'fund': fund,
      'final_cash': 0.0,
      'expected_cash': 0.0,
      'products_start': productsSnapshot,
    });
    return id;
  }

  static Future<Map<String, dynamic>?> getCashSessionById(int sessionId) async {
    for (var k in _cashSessions.keys) {
      final vRaw = _cashSessions.get(k);
      final v = _toMapSafe(vRaw);
      final id = (v['id'] is int) ? v['id'] as int : int.tryParse('${v['id']}') ?? k;
      if (id == sessionId) return v;
    }
    return null;
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

  static Future<int> openCash(double fund) async {
    return openCashSession(fund);
  }

  static Future<void> closeCash(int id, double finalCash, double expectedCash) async {
    await closeCashSession(
      id,
      finalCash: finalCash,
      expectedCash: expectedCash,
    );
  }
}
