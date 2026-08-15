import 'package:flutter/material.dart';
import '../services/db_service.dart';

class VentasDiaScreen extends StatefulWidget {
  const VentasDiaScreen({super.key});

  @override
  State<VentasDiaScreen> createState() => _VentasDiaScreenState();
}

class _VentasDiaScreenState extends State<VentasDiaScreen> {
  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  double totalDia = 0;
  double totalEfectivo = 0;
  double totalTransferencia = 0;

  Map<String, double> totalPorUsuario = {};

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    setState(() => loading = true);

    ventas = await DBService.getSalesOfDay();

    // Cargar items de venta
    items = await DBService.getSaleItems();

    totalDia = 0;
    totalEfectivo = 0;
    totalTransferencia = 0;
    totalPorUsuario = {};

    for (var v in ventas) {
      final total = (v['total'] ?? 0).toDouble();
      final user = v['user'] ?? 'desconocido';
      final method = v['method'];

      totalDia += total;

      if (method == 'Efectivo') totalEfectivo += total;
      if (method == 'Transferencia') totalTransferencia += total;

      totalPorUsuario[user] = (totalPorUsuario[user] ?? 0) + total;
    }

    setState(() => loading = false);
  }

  List<Map<String, dynamic>> itemsDeVenta(int saleId) {
    return items.where((i) => i['sale_id'] == saleId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ventas del día"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarVentas,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // RESUMEN GENERAL
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total del día: \$${totalDia.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("Efectivo: \$${totalEfectivo.toStringAsFixed(2)}"),
                        Text(
                            "Transferencia: \$${totalTransferencia.toStringAsFixed(2)}"),
                        const SizedBox(height: 10),
                        const Text("Totales por usuario:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...totalPorUsuario.keys.map((u) => Text(
                            "$u: \$${totalPorUsuario[u]!.toStringAsFixed(2)}")),
                      ],
                    ),
                  ),
                ),

                const Divider(),

                // LISTA DE VENTAS
                Expanded(
                  child: ventas.isEmpty
                      ? const Center(child: Text("No hay ventas hoy"))
                      : ListView.builder(
                          itemCount: ventas.length,
                          itemBuilder: (_, i) {
                            final v = ventas[i];
                            final saleId = i;
                            final saleItems = itemsDeVenta(saleId);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ExpansionTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text(
                                  "Venta #$saleId - \$${v['total'].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${v['method']} • ${v['user']} • ${v['date']}",
                                ),
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Productos:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ...saleItems.map((item) {
                                    return ListTile(
                                      title: Text(
                                          "${item['product_id']} x${item['quantity']}"),
                                      subtitle: Text(
                                          "Precio: \$${item['price'].toStringAsFixed(2)}"),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
