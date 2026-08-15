import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../services/db_service.dart';
import '../widgets/branding_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    products = await DBService.getProducts();
    setState(() => loading = false);
  }

  void createProduct() {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: "0");
    final cashCtrl = TextEditingController(text: "0.0");
    final transferCtrl = TextEditingController(text: "0.0");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock')),
            TextField(
                controller: cashCtrl,
                decoration:
                    const InputDecoration(labelText: 'Precio efectivo')),
            TextField(
                controller: transferCtrl,
                decoration:
                    const InputDecoration(labelText: 'Precio transferencia')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await DBService.insertProduct({
                'name': nameCtrl.text,
                'stock': int.tryParse(stockCtrl.text) ?? 0,
                'price_cash': double.tryParse(cashCtrl.text) ?? 0.0,
                'price_transfer': double.tryParse(transferCtrl.text) ?? 0.0,
              });
              Navigator.pop(context);
              loadProducts();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void editProduct(int index) {
    final p = products[index];

    final nameCtrl = TextEditingController(text: p['name']);
    final stockCtrl = TextEditingController(text: p['stock'].toString());
    final cashCtrl = TextEditingController(text: p['price_cash'].toString());
    final transferCtrl =
        TextEditingController(text: p['price_transfer'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock')),
            TextField(
                controller: cashCtrl,
                decoration:
                    const InputDecoration(labelText: 'Precio efectivo')),
            TextField(
                controller: transferCtrl,
                decoration:
                    const InputDecoration(labelText: 'Precio transferencia')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await DBService.updateProduct(index, {
                'name': nameCtrl.text,
                'stock': int.tryParse(stockCtrl.text) ?? 0,
                'price_cash': double.tryParse(cashCtrl.text) ?? 0.0,
                'price_transfer': double.tryParse(transferCtrl.text) ?? 0.0,
              });
              Navigator.pop(context);
              loadProducts();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> importCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final lines = await file.readAsLines();

    for (var line in lines.skip(1)) {
      final parts = line.split(',');

      if (parts.length >= 4) {
        await DBService.insertProduct({
          'name': parts[0],
          'stock': int.tryParse(parts[1]) ?? 0,
          'price_cash': double.tryParse(parts[2]) ?? 0.0,
          'price_transfer': double.tryParse(parts[3]) ?? 0.0,
        });
      }
    }

    loadProducts();
  }

  Future<void> exportCSV() async {
    final dir = await getDownloadsDirectory();
    final file = File('${dir!.path}/productos_mipypos.csv');

    final buffer = StringBuffer();
    buffer.writeln("name,stock,price_cash,price_transfer");

    for (var p in products) {
      buffer.writeln(
          "${p['name']},${p['stock']},${p['price_cash']},${p['price_transfer']}");
    }

    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exportado a: ${file.path}")),
    );
  }

  Future<void> exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Productos'];

    sheet.appendRow(["Nombre", "Stock", "Efectivo", "Transferencia"]);

    for (var p in products) {
      sheet.appendRow([
        p['name'],
        p['stock'],
        p['price_cash'],
        p['price_transfer'],
      ]);
    }

    final dir = await getDownloadsDirectory();
    final file = File('${dir!.path}/productos_mipypos.xlsx');
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exportado a Excel: ${file.path}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 28),
            SizedBox(width: 12),
            Text('Productos'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: createProduct),
          IconButton(icon: const Icon(Icons.upload_file), onPressed: importCSV),
          IconButton(icon: const Icon(Icons.download), onPressed: exportCSV),
          IconButton(
              icon: const Icon(Icons.table_view), onPressed: exportExcel),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  child: ListTile(
                    leading: ProductImage(
                      url: p['foto'] ?? 'assets/productos/placeholder.png',
                      size: 56,
                    ),
                    title: Text(p['name']),
                    subtitle: Text(
                      'Stock: ${p['stock']} | Efectivo: \$${p['price_cash']} | Transferencia: \$${p['price_transfer']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => editProduct(i),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
