import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> movements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => loading = true);

    areas = await DBService.getAreas();
    products = await DBService.getProducts();
    movements = await DBService.getMovementsOfDay();

    setState(() => loading = false);
  }

  void crearArea() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Crear área"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Nombre del área"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBService.addArea(nameCtrl.text.trim());
              Navigator.pop(context);
              cargarDatos();
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  void moverProducto() {
    final auth = context.read<AuthController>();

    if (auth.user?['role'] != 'storekeeper') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solo el almacenista puede enviar productos")),
      );
      return;
    }

    int? productoId;
    int? fromArea;
    int? toArea;
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Mover producto entre áreas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Producto"),
              items: products.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(p['name']),
                );
              }).toList(),
              onChanged: (v) => productoId = v,
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Desde área"),
              items: areas.map<DropdownMenuItem<int>>((a) {
                return DropdownMenuItem<int>(
                  value: a['id'] as int,
                  child: Text(a['name']),
                );
              }).toList(),
              onChanged: (v) => fromArea = v,
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Hacia área"),
              items: areas.map<DropdownMenuItem<int>>((a) {
                return DropdownMenuItem<int>(
                  value: a['id'] as int,
                  child: Text(a['name']),
                );
              }).toList(),
              onChanged: (v) => toArea = v,
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cantidad"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (productoId == null || fromArea == null || toArea == null) return;

              await DBService.createMovement(
                productIndex: productoId!,
                fromAreaId: fromArea!,
                toAreaId: toArea!,
                qty: int.tryParse(qtyCtrl.text) ?? 0,
                fromUser: auth.user?['user'] ?? 'almacenista',
                toUser: 'pendiente',
                confirmedBySeller: false,
              );

              Navigator.pop(context);
              cargarDatos();
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  void confirmarMovimiento(Map<String, dynamic> mov) async {
    final auth = context.read<AuthController>();

    if (auth.user?['role'] != 'seller') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solo el cajero puede confirmar entradas")),
      );
      return;
    }

    await DBService.createMovement(
      productIndex: mov['product_index'],
      fromAreaId: mov['from_area'],
      toAreaId: mov['to_area'],
      qty: mov['qty'],
      fromUser: mov['from_user'],
      toUser: auth.user?['user'] ?? 'cajero',
      confirmedBySeller: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entrada confirmada")),
    );

    cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Áreas e Inventarios"),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: crearArea,
            ),
          if (auth.user?['role'] == 'storekeeper')
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: moverProducto,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Áreas registradas:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...areas.map((a) => ListTile(
                      leading: const Icon(Icons.home_work),
                      title: Text(a['name']),
                      subtitle: Text("ID: ${a['id']}"),
                    )),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Movimientos del día:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                ...movements.map((m) {
                  final p = products[m['product_index']];
                  final fromArea = areas[m['from_area']]['name'];
                  final toArea = areas[m['to_area']]['name'];

                  return Card(
                    child: ListTile(
                      title: Text("${p['name']} (${m['qty']})"),
                      subtitle: Text(
                        "De: $fromArea → A: $toArea\n"
                        "Enviado por: ${m['from_user']}\n"
                        "Confirmado: ${m['confirmed_by_seller'] ? 'Sí' : 'No'}",
                      ),
                      trailing: (!m['confirmed_by_seller'] &&
                              auth.user?['role'] == 'seller')
                          ? ElevatedButton(
                              onPressed: () => confirmarMovimiento(m),
                              child: const Text("Confirmar"),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
