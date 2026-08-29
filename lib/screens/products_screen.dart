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
    final subcategoryCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: "0");
    final cashCtrl = TextEditingController(text: "0.0");
    final transferCtrl = TextEditingController(text: "0.0");
    String? photoPath;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Crear producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: subcategoryCtrl, decoration: const InputDecoration(labelText: 'Subcategoría')),
                TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock')),
                TextField(controller: cashCtrl, decoration: const InputDecoration(labelText: 'Precio efectivo')),
                TextField(controller: transferCtrl, decoration: const InputDecoration(labelText: 'Precio transferencia')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(photoPath == null ? 'Sin foto' : photoPath!.split('/').last),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        if (result != null && result.files.single.path != null) {
                          setState(() => photoPath = result.files.single.path!);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Foto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await DBService.insertProduct({
                  'name': nameCtrl.text,
                  'subcategory': subcategoryCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'price_cash': double.tryParse(cashCtrl.text) ?? 0.0,
                  'price_transfer': double.tryParse(transferCtrl.text) ?? 0.0,
                  'foto': photoPath ?? '',
                });
                Navigator.pop(context);
                loadProducts();
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void editProduct(int index) {
    final p = products[index];

    final nameCtrl = TextEditingController(text: p['name']);
    final subcategoryCtrl = TextEditingController(text: (p['subcategory'] ?? '').toString());
    final stockCtrl = TextEditingController(text: p['stock'].toString());
    final cashCtrl = TextEditingController(text: p['price_cash'].toString());
    final transferCtrl = TextEditingController(text: p['price_transfer'].toString());
    String? photoPath = (p['foto'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: subcategoryCtrl, decoration: const InputDecoration(labelText: 'Subcategoría')),
                TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock')),
                TextField(controller: cashCtrl, decoration: const InputDecoration(labelText: 'Precio efectivo')),
                TextField(controller: transferCtrl, decoration: const InputDecoration(labelText: 'Precio transferencia')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(photoPath == null || photoPath!.isEmpty ? 'Sin foto' : photoPath!.split('/').last),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        if (result != null && result.files.single.path != null) {
                          setState(() => photoPath = result.files.single.path!);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Foto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await DBService.updateProduct(index, {
                  'name': nameCtrl.text,
                  'subcategory': subcategoryCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'price_cash': double.tryParse(cashCtrl.text) ?? 0.0,
                  'price_transfer': double.tryParse(transferCtrl.text) ?? 0.0,
                  'foto': photoPath ?? '',
                });
                Navigator.pop(context);
                loadProducts();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> recordProductEntry() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final userCtrl = TextEditingController(text: 'admin');
    final noteCtrl = TextEditingController(text: 'Entrada del día');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Entrada de producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del producto')),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Usuario')),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Nota')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar entrada'),
          )
        ],
      ),
    );

    if (ok != true) return;

    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final name = nameCtrl.text.trim();
    if (name.isEmpty || qty <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre y cantidad inválidos')));
      }
      return;
    }

    await DBService.recordProductEntry(
      productName: name,
      qty: qty,
      user: userCtrl.text.trim().isEmpty ? 'admin' : userCtrl.text.trim(),
      note: noteCtrl.text.trim().isEmpty ? 'Entrada del día' : noteCtrl.text.trim(),
    );
    await loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrada registrada')));
    }
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
          'subcategory': parts.length > 5 ? parts[1] : '',
          'stock': int.tryParse(parts.length > 5 ? parts[2] : parts[1]) ?? 0,
          'price_cash': double.tryParse(parts.length > 5 ? parts[3] : parts[2]) ?? 0.0,
          'price_transfer': double.tryParse(parts.length > 5 ? parts[4] : parts[3]) ?? 0.0,
          'foto': parts.length > 5 ? parts[5] : '',
        });
      }
    }

    loadProducts();
  }

  Future<void> exportCSV() async {
    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/productos_mipypos.csv');

    final buffer = StringBuffer();
    buffer.writeln("name,subcategory,stock,price_cash,price_transfer,foto");

    for (var p in products) {
      buffer.writeln(
          "${p['name']},${p['subcategory'] ?? ''},${p['stock']},${p['price_cash']},${p['price_transfer']},${p['foto'] ?? ''}");
    }

    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exportado a: ${file.path}")),
    );
  }

  Future<void> exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Productos'];

    sheet.appendRow(["Nombre", "Subcategoría", "Stock", "Efectivo", "Transferencia", "Foto"]);

    for (var p in products) {
      sheet.appendRow([
        p['name'],
        p['subcategory'] ?? '',
        p['stock'],
        p['price_cash'],
        p['price_transfer'],
        p['foto'] ?? '',
      ]);
    }

    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/productos_mipypos.xlsx');
    await file.parent.create(recursive: true);
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
          IconButton(icon: const Icon(Icons.input), onPressed: recordProductEntry),
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
                      '${(p['subcategory'] ?? '').toString().isEmpty ? 'Sin subcategoría' : 'Sub: ${p['subcategory']}'} | Stock: ${p['stock']} | Efectivo: \$${p['price_cash']} | Transferencia: \$${p['price_transfer']}',
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
