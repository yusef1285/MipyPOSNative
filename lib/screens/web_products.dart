import 'package:flutter/material.dart';
import '../services/db_service.dart';

class WebProducts extends StatefulWidget {
  const WebProducts({super.key});

  @override
  State<WebProducts> createState() =>
      _WebProductsState();
}

class _WebProductsState extends State<WebProducts> {

  List products = [];

  final name = TextEditingController();
  final price = TextEditingController();
  final cost = TextEditingController();
  final stock = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    products = await DBService.getProducts();
    setState(() {});
  }

  Future<void> save() async {
    await DBService.insertProduct({
      'name': name.text,
      'price': double.parse(price.text),
      'cost': double.parse(cost.text),
      'stock': int.parse(stock.text),
      'updated_at': DateTime.now().toIso8601String(),
    });

    name.clear();
    price.clear();
    cost.clear();
    stock.clear();

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Productos (WEB)")),

      body: Row(
        children: [

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  TextField(controller: name, decoration: const InputDecoration(labelText: "Nombre")),
                  TextField(controller: price, decoration: const InputDecoration(labelText: "Precio")),
                  TextField(controller: cost, decoration: const InputDecoration(labelText: "Costo")),
                  TextField(controller: stock, decoration: const InputDecoration(labelText: "Stock")),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: save,
                    child: const Text("Guardar"),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];

                return ListTile(
                  title: Text(p['name']),
                  subtitle: Text("Stock: ${p['stock']}"),
                  trailing: Text("\$${p['price']}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}