import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../controllers/auth_controller.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  List<Map<String, dynamic>> movimientos = [];
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> areas = [];
  bool loading = true;

  String filtroUsuario = "Todos";
  String filtroArea = "Todos";
  String filtroProducto = "Todos";

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => loading = true);

    movimientos = await DBService.getMovementsOfDay();
    productos = await DBService.getProducts();
    areas = await DBService.getAreas();

    setState(() => loading = false);
  }

  List<Map<String, dynamic>> aplicarFiltros() {
    return movimientos.where((m) {
      final producto = productos[m['product_index']]['name'];
      final areaOrigen = areas[m['from_area']]['name'];
      final areaDestino = areas[m['to_area']]['name'];
      final usuario = m['from_user'];

      if (filtroUsuario != "Todos" && usuario != filtroUsuario) return false;

      if (filtroArea != "Todos" &&
          filtroArea != areaOrigen &&
          filtroArea != areaDestino) {
        return false;
      }

      if (filtroProducto != "Todos" && filtroProducto != producto) return false;

      return true;
    }).toList();
  }

  Future<void> confirmarMovimiento(Map<String, dynamic> mov) async {
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
    final filtrados = aplicarFiltros();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Movimientos del día"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarDatos,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // -------------------------
                // FILTROS
                // -------------------------
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: filtroUsuario,
                              decoration: const InputDecoration(
                                labelText: "Usuario",
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: "Todos", child: Text("Todos")),
                                ...movimientos
                                    .map((m) => m['from_user'])
                                    .where((u) => u != null)
                                    .toSet()
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        ))
                              ],
                              onChanged: (v) {
                                setState(() => filtroUsuario = v!);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: filtroArea,
                              decoration: const InputDecoration(
                                labelText: "Área",
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: "Todos", child: Text("Todos")),
                                ...areas.map((a) => DropdownMenuItem(
                                      value: a['name'],
                                      child: Text(a['name']),
                                    ))
                              ],
                              onChanged: (v) {
                                setState(() => filtroArea = v!);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: filtroProducto,
                        decoration: const InputDecoration(
                          labelText: "Producto",
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: "Todos", child: Text("Todos")),
                          ...productos.map((p) => DropdownMenuItem(
                                value: p['name'],
                                child: Text(p['name']),
                              ))
                        ],
                        onChanged: (v) {
                          setState(() => filtroProducto = v!);
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // -------------------------
                // LISTA DE MOVIMIENTOS
                // -------------------------
                Expanded(
                  child: filtrados.isEmpty
                      ? const Center(child: Text("No hay movimientos hoy"))
                      : ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) {
                            final m = filtrados[i];
                            final p = productos[m['product_index']];
                            final fromArea = areas[m['from_area']]['name'];
                            final toArea = areas[m['to_area']]['name'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.swap_horiz),
                                title: Text("${p['name']} (${m['qty']})"),
                                subtitle: Text(
                                  "De: $fromArea → A: $toArea\n"
                                  "Enviado por: ${m['from_user']}\n"
                                  "Recibido por: ${m['to_user']}\n"
                                  "Confirmado: ${m['confirmed_by_seller'] ? 'Sí' : 'No'}\n"
                                  "Fecha: ${m['date']}",
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
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
