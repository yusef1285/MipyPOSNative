// lib/controllers/product_repository.dart
// Repositorio ligero que expone utilidades sobre productos para la UI y servicios.

import '../services/db_service.dart';

class ProductRepository {
  ProductRepository._();

  /// Devuelve todos los productos (lista de mapas).
  static Future<List<Map<String, dynamic>>> getAll() async {
    return await DBService.getProducts();
  }

  /// Devuelve un mapa nombre -> stock inicial (usa DBService.getProductsStockMapStart).
  static Future<Map<String, dynamic>> getStockStartMap() async {
    // Llamada a DBService.getProductsStockMapStart (método añadido en DBService)
    return await DBService.getProductsStockMapStart();
  }

  /// Devuelve un mapa nombre -> stock final (por defecto toma el stock actual).
  static Future<Map<String, dynamic>> getStockEndMap() async {
    final products = await getAll();
    final map = <String, dynamic>{};
    for (var p in products) {
      final name = p['name']?.toString() ?? '';
      map[name] = p['stock'] ?? 0;
    }
    return map;
  }

  /// Devuelve una muestra aleatoria de hasta 10 productos (para muestreo 10%).
  static Future<List<Map<String, dynamic>>> getRandomSample10() async {
    final all = await getAll();
    if (all.length <= 10) return all;
    all.shuffle();
    return all.sublist(0, 10);
  }
}
