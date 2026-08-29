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

import '../services/sync_service.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  // ... (código existente)

  Future<int> checkout({String? method, required String user, required int sessionId, List<Map<String, dynamic>>? payments}) async {
    final saleMethod = (payments != null && payments.isNotEmpty) ? 'Mixto' : (method ?? 'Efectivo');
    final totalAmount = total;

    final saleId = await DBService.createSale(totalAmount, saleMethod, user, sessionId: sessionId, payments: payments);

    // Sincronización P2P: Notificar a otros dispositivos
    SyncService().syncSale({
      'total': totalAmount,
      'method': saleMethod,
      'user': user,
      'sessionId': sessionId,
      'payments': payments,
    });

    for (var it in _items) {
      // ... (restante del código de items y stock)

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
