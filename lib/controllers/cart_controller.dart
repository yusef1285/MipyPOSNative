// lib/controllers/cart_controller.dart
import 'package:flutter/foundation.dart';
import '../services/db_service.dart';
import '../core/session_manager.dart';

class CartItem {
  final int productId;
  final String name;
  int qty;
  double price;

  CartItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap(int saleId) {
    return {
      'sale_id': saleId,
      'product_id': productId,
      'name': name,
      'quantity': qty,
      'price': price,
      'subtotal': qty * price,
    };
  }

  /// Implementa operador [] para compatibilidad con código que trata items como Map
  dynamic operator [](String key) {
    switch (key) {
      case 'product_id':
        return productId;
      case 'id':
        return productId;
      case 'name':
        return name;
      case 'quantity':
      case 'qty':
        return qty;
      case 'price':
        return price;
      case 'subtotal':
        return qty * price;
      default:
        return null;
    }
  }
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get total => _items.fold(0.0, (s, i) => s + (i.qty * i.price));

  void add(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final name = product['name']?.toString() ?? 'Producto';
    final price = (product['price'] is num) ? (product['price'] as num).toDouble() : double.tryParse('${product['price']}') ?? 0.0;

    final existing = _items.firstWhere((it) => it.productId == id, orElse: () => CartItem(productId: -1, name: '', qty: 0, price: 0.0));
    if (existing.productId != -1) {
      existing.qty += 1;
    } else {
      _items.add(CartItem(productId: id, name: name, qty: 1, price: price));
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Realiza el checkout: crea la venta, inserta items y actualiza stock.
  /// Ahora requiere que el caller pase el sessionId explícito.
  Future<int> checkout({required String method, required String user, required int sessionId}) async {
    if (sessionId == null) {
      throw Exception('No hay sessionId proporcionado para checkout');
    }

    // Crear venta en DBService pasando sessionId explícito
    final saleId = await DBService.createSale(total, method, user, sessionId: sessionId);

    // Insertar items y actualizar stock
    for (var it in _items) {
      final itemMap = it.toMap(saleId);
      await DBService.insertSaleItem(itemMap);
      // Reducir stock
      try {
        await DBService.removeStock(it.productId, it.qty);
      } catch (_) {
        // Si falla el stock, no abortamos la venta; loguear si tienes logger
      }
    }

    // Limpiar carrito
    clear();
    return saleId;
  }

}
