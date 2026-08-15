import 'package:flutter/material.dart';
import '../services/db_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> movements = [];
  bool loading = true;
  int _selectedTab = 0; // 0 = Productos, 1 = Movimientos

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 🆕 Esto fuerza la recarga cada vez que la pantalla se vuelve visible (por ejemplo, al volver de Productos)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final prods = await DBService.getProducts();
      final movs = await DBService.getMovements();
      setState(() {
        products = List<Map<String, dynamic>>.from(prods);
        movements = List<Map<String, dynamic>>.from(movs);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _showStockDialog(
      Map<String, dynamic> product, String type) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type == "IN" ? "Agregar" : "Quitar"} stock'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Producto: ${product['name']}'),
              Text('Stock actual: ${product['stock']}'),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una cantidad';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Cantidad no válida';
                  }
                  if (type == 'OUT' && qty > (product['stock'] ?? 0)) {
                    return 'No hay stock suficiente';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, int.parse(controller.text));
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        if (type == 'IN') {
          await DBService.addStock(product['id'], result);
        } else {
          await DBService.removeStock(product['id'], result);
        }
        await loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock ${type == "IN" ? "agregado" : "retirado"} exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de pestañas simple
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 0
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Productos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 1
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Movimientos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildProductList()
                    : _buildMovementsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (products.isEmpty) {
      return const Center(
        child: Text('No hay productos. Agregue productos desde la pantalla de Productos.'),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final stock = p['stock'] ?? 0;
        final lowStock = stock <= 5;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(p['name'] ?? 'Sin nombre'),
            subtitle: Text(
              'Stock: $stock ${lowStock ? '(BAJO)' : ''}',
              style: TextStyle(
                color: lowStock ? Colors.red : Colors.black54,
                fontWeight: lowStock ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _showStockDialog(p, 'OUT'),
                  tooltip: 'Quitar stock',
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showStockDialog(p, 'IN'),
                  tooltip: 'Agregar stock',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementsList() {
    if (movements.isEmpty) {
      return const Center(child: Text('No hay movimientos registrados.'));
    }

    return ListView.builder(
      itemCount: movements.length,
      itemBuilder: (_, i) {
        final m = movements[i];
        final isIn = m['type'] == 'IN';
        final date = m['date'] ?? '';

        return ListTile(
          leading: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIn ? Colors.green : Colors.red,
          ),
          title: Text(m['name'] ?? 'Producto ${m['product_id']}'),
          subtitle: Text(date.toString().substring(0, 10)),
          trailing: Text(
            '${isIn ? '+' : '-'}${m['quantity']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isIn ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}