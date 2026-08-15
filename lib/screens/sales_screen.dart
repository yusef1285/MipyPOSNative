// lib/screens/sales_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import '../core/session_manager.dart';
import '../services/db_service.dart';
import '../services/pdf_service.dart';
import '../widgets/branding_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool loadingProducts = true;
  bool processingSale = false;

  String selectedPayment = 'Efectivo';
  final TextEditingController searchController = TextEditingController();

  final List<String> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  @override
  void initState() {
    super.initState();
    loadProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterProducts);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() => loadingProducts = true);
    try {
      products = await DBService.getProducts();
      _filterProducts();
    } catch (e) {
      products = [];
      filteredProducts = [];
    } finally {
      if (mounted) setState(() => loadingProducts = false);
    }
  }

  void _filterProducts() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> checkout() async {
    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();
    final sessionManager = context.read<SessionManager>();

    if (cart.items.isEmpty || processingSale) return;

    // Validar turno abierto en memoria
    if (!sessionManager.isOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No hay caja abierta. Abra caja en Dashboard.')),
        );
      }
      return;
    }

    // Snapshot de items antes de hacer checkout (checkout limpia el carrito)
    final itemsSnapshot = cart.items.map((it) {
      return {
        'name': it.name,
        'qty': it.qty,
        'price': it.price,
      };
    }).toList();

    // Confirmación antes de cobrar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: Text(
          'Total: \$${cart.total.toStringAsFixed(2)}\n'
          'Método: $selectedPayment\n'
          'Usuario: ${auth.user?['user'] ?? 'desconocido'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cobrar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => processingSale = true);

    try {
      // Antes de procesar, validar en la DB que la caja sigue abierta y que coincide con la sesión en memoria
      final openSession = await DBService.getOpenCash();
      final sidMemory = sessionManager.sessionId;
      if (openSession == null) {
        // La caja fue cerrada en la DB entre la confirmación y el cobro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ La caja fue cerrada. No se puede procesar la venta.')),
          );
        }
        return;
      }
      final sidDb = (openSession['id'] is int) ? openSession['id'] as int : int.tryParse('${openSession['id']}');
      if (sidMemory == null || sidDb != sidMemory) {
        // Desincronización: recargar sesión en memoria y avisar
        await sessionManager.loadSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Sesión de caja desincronizada. Recargue y vuelva a intentar.')),
          );
        }
        return;
      }

      // Preparar texto del ticket usando snapshot y conversiones seguras
      final ticketTextBuffer = StringBuffer();
      ticketTextBuffer.writeln('MipyPOS - Ticket de Venta');
      ticketTextBuffer.writeln('-------------------------');
      ticketTextBuffer.writeln('Método: $selectedPayment');
      ticketTextBuffer.writeln('Usuario: ${auth.user?['user'] ?? 'desconocido'}');
      ticketTextBuffer.writeln('Total: \$${cart.total.toStringAsFixed(2)}');
      ticketTextBuffer.writeln('');
      ticketTextBuffer.writeln('Productos:');

      for (var it in itemsSnapshot) {
        final name = it['name']?.toString() ?? 'Producto';
        final qty = (it['qty'] is int) ? it['qty'] as int : int.tryParse('${it['qty']}') ?? 0;
        final price = (it['price'] is num) ? (it['price'] as num).toDouble() : double.tryParse('${it['price']}') ?? 0.0;
        final lineTotal = price * qty;
        ticketTextBuffer.writeln('- $name x$qty = \$${lineTotal.toStringAsFixed(2)}');
      }

      // Ejecutar checkout pasando sessionId explícito
      final saleId = await cart.checkout(
        method: selectedPayment,
        user: auth.user?['user'] ?? 'desconocido',
        sessionId: sidMemory!,
      );

      // Generar ticket (PDF o archivo) a partir del texto
      final Uint8List ticketBytes = Uint8List.fromList(ticketTextBuffer.toString().codeUnits);
      await PdfService.generateTicket(ticketBytes);

      // Recargar productos para reflejar cambios de stock
      await loadProducts();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Venta exitosa'),
            content: Text('Venta registrada: $saleId\nTicket generado.'),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar venta: $e')));
      }
    } finally {
      if (mounted) setState(() => processingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final sessionManager = context.watch<SessionManager>();

    final bool canSell = sessionManager.isOpen && !processingSale && cart.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 28),
            SizedBox(width: 12),
            Text(
              'MipyPOS',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadProducts, tooltip: 'Actualizar productos'),
        ],
      ),
      body: loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(labelText: 'Buscar producto', prefixIcon: Icon(Icons.search)),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text('No se encontraron productos.'))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, i) {
                            final p = filteredProducts[i];
                            final stock = (p['stock'] is int) ? p['stock'] as int : int.tryParse('${p['stock']}') ?? 0;

                            final priceValue = selectedPayment == 'Efectivo'
                                ? (p['price_cash'] ?? p['price_transfer'] ?? 0.0)
                                : (p['price_transfer'] ?? p['price_cash'] ?? 0.0);

                            final price = (priceValue is num) ? (priceValue as num).toDouble() : double.tryParse('$priceValue') ?? 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              child: ListTile(
                                leading: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                                title: Text(p['name'] ?? ''),
                                subtitle: Text('Stock: $stock • \$${price.toStringAsFixed(2)}'),
                                trailing: ElevatedButton(
                                  onPressed: stock > 0
                                      ? () {
                                          context.read<CartController>().add({
                                            'id': p['id'],
                                            'name': p['name'],
                                            'price': price,
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Añadido: ${p['name']}')));
                                        }
                                      : null,
                                  child: const Text('Agregar'),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // CARRITO + COBRAR
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      if (cart.items.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            itemCount: cart.items.length,
                            itemBuilder: (_, i) {
                              final item = cart.items[i];
                              return Card(
                                margin: const EdgeInsets.only(right: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shopping_cart, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text('${item.name} x${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => context.read<CartController>().remove(item.productId),
                                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Text('Método:'),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: selectedPayment,
                              items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => selectedPayment = v!),
                            ),
                            const Spacer(),
                            Text('Total: \$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canSell ? Colors.green : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: canSell ? checkout : null,
                            icon: processingSale
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.payment),
                            label: Text(processingSale ? 'Procesando...' : 'COBRAR'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
