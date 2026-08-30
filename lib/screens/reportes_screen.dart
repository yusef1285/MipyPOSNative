import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../widgets/branding_widgets.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool loading = true;

  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> movimientos = [];

  String filtroUsuario = "Todos";
  String filtroMetodo = "Todos";

  double totalGeneral = 0;
  double totalEfectivo = 0;
  double totalTransferencia = 0;

  Map<String, double> totalPorUsuario = {};
  Map<String, double> totalPorProducto = {};
  Map<String, double> totalPorArea = {};

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => loading = true);

    productos = await DBService.getProducts();
    areas = await DBService.getAreas();
    ventas = await DBService.getSalesOfDay();
    items = await DBService.getSaleItems();
    movimientos = await DBService.getMovementsOfDay();

    calcularTotales();

    setState(() => loading = false);
  }

  void calcularTotales() {
    totalGeneral = 0;
    totalEfectivo = 0;
    totalTransferencia = 0;

    totalPorUsuario = {};
    totalPorProducto = {};
    totalPorArea = {};

    for (var v in ventas) {
      final total = (v['total'] ?? 0).toDouble();
      final user = v['user'] ?? 'desconocido';
      final method = v['method'];

      totalGeneral += total;

      if (method == 'Efectivo') totalEfectivo += total;
      if (method == 'Transferencia') totalTransferencia += total;

      totalPorUsuario[user] = (totalPorUsuario[user] ?? 0) + total;
    }

    for (var item in items) {
      final pIndex = item['product_id'];
      final qty = item['quantity'];
      final price = item['price'];

      final name = productos[pIndex]['name'];

      totalPorProducto[name] = (totalPorProducto[name] ?? 0) + (qty * price);
    }

    for (var m in movimientos) {
      final areaName = areas[m['to_area']]['name'];
      final qty = m['qty'];
      final pIndex = m['product_index'];
      final name = productos[pIndex]['name'];

      totalPorArea[areaName] = (totalPorArea[areaName] ?? 0) + qty;
    }
  }

  List<Map<String, dynamic>> aplicarFiltros() {
    return ventas.where((v) {
      final user = v['user'];
      final method = v['method'];

      if (filtroUsuario != "Todos" && filtroUsuario != user) return false;
      if (filtroMetodo != "Todos" && filtroMetodo != method) return false;

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> itemsDeVenta(int saleId) {
    return items.where((i) => i['sale_id'] == saleId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = aplicarFiltros();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarDatos,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: BrandLogo(height: 56),
                ),

                const Text("Filtros",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                // -------------------------
                // FILTRO USUARIO
                // -------------------------
                DropdownButtonFormField<String>(
                  value: filtroUsuario,
                  decoration: const InputDecoration(labelText: "Usuario"),
                  items: [
                    const DropdownMenuItem(value: "Todos", child: Text("Todos")),
                    ...ventas
                        .map((v) => v['user'])
                        .where((u) => u != null)
                        .toSet()
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ))
                  ],
                  onChanged: (v) => setState(() => filtroUsuario = v!),
                ),

                // -------------------------
                // FILTRO MÉTODO
                // -------------------------
                DropdownButtonFormField<String>(
                  value: filtroMetodo,
                  decoration: const InputDecoration(labelText: "Método"),
                  items: const [
                    DropdownMenuItem(value: "Todos", child: Text("Todos")),
                    DropdownMenuItem(value: "Efectivo", child: Text("Efectivo")),
                    DropdownMenuItem(
                        value: "Transferencia", child: Text("Transferencia")),
                  ],
                  onChanged: (v) => setState(() => filtroMetodo = v!),
                ),

                const SizedBox(height: 20),

                // -------------------------
                // RESUMEN DEL DÍA
                // -------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Resumen del día",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Total general: \$${totalGeneral.toStringAsFixed(2)}"),
                        Text("Efectivo: \$${totalEfectivo.toStringAsFixed(2)}"),
                        Text(
                            "Transferencia: \$${totalTransferencia.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                ),

                // -------------------------
                // TOTALES POR USUARIO
                // -------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Totales por usuario",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        ...totalPorUsuario.keys.map((u) => Text(
                            "$u: \$${totalPorUsuario[u]!.toStringAsFixed(2)}")),
                      ],
                    ),
                  ),
                ),

                // -------------------------
                // TOTALES POR PRODUCTO
                // -------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Totales por producto",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        ...totalPorProducto.keys.map((p) => Text(
                            "$p: \$${totalPorProducto[p]!.toStringAsFixed(2)}")),
                      ],
                    ),
                  ),
                ),

                // -------------------------
                // TOTALES POR ÁREA
                // -------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Entradas por área",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        ...totalPorArea.keys.map((a) => Text(
                            "$a: ${totalPorArea[a]!.toStringAsFixed(0)} unidades")),
                      ],
                    ),
                  ),
                ),

                const Text("Ventas filtradas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                // -------------------------
                // VENTAS FILTRADAS
                // -------------------------
                ...filtradas.map((v) {
                  final saleId = ventas.indexOf(v);
                  final saleItems = itemsDeVenta(saleId);

                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        "Venta #$saleId - \$${v['total'].toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${v['method']} • ${v['user']} • ${v['date']}",
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Productos:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...saleItems.map((item) {
                          final p = productos[item['product_id']]['name'];
                          return ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text("$p x${item['quantity']}"),
                            subtitle: Text(
                                "Precio: \$${item['price'].toStringAsFixed(2)}"),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const CopyrightText(),
              ],
            ),
    );
  }
}
