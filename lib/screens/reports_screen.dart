import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'package:hive/hive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double todayTotal = 0;
  double todayProfit = 0;
  int todaySalesCount = 0;
  List<Map<String, dynamic>> topProducts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() => loading = true);
    try {
      todayTotal = await DBService.todaySales();
      topProducts = await DBService.topProducts();

      final salesBox = Hive.box('sales');
      final saleItemsBox = Hive.box('saleItems');
      double profit = 0;
      int count = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day)
          .toIso8601String()
          .substring(0, 10);

      for (var sale in salesBox.values) {
        final date = sale['date'] as String?;
        if (date != null && date.startsWith(today)) {
          count++;
          final saleId =
              salesBox.keys.elementAt(salesBox.values.toList().indexOf(sale));
          for (var item in saleItemsBox.values) {
            if (item['sale_id'] == saleId) {
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              final qty = (item['quantity'] as int?) ?? 0;
              profit += price * qty; // Sin costo, la ganancia es el ingreso
            }
          }
        }
      }

      todayProfit = profit;
      todaySalesCount = count;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: $e')),
        );
      }
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadReport),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(
                      'Ventas del día',
                      '\$${todayTotal.toStringAsFixed(2)}',
                      '$todaySalesCount ventas realizadas',
                      Colors.blue,
                      Icons.today),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                      'Ganancia estimada',
                      '\$${todayProfit.toStringAsFixed(2)}',
                      'Ingreso total (sin costo)',
                      Colors.green,
                      Icons.trending_up),
                  const SizedBox(height: 20),
                  const Text('Productos más vendidos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  topProducts.isEmpty
                      ? const Card(
                          child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No hay ventas registradas hoy.'),
                        ))
                      : Card(
                          elevation: 2,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('Producto')),
                              DataColumn(label: Text('Cant. Vendida')),
                            ],
                            rows: topProducts.asMap().entries.map((entry) {
                              final i = entry.key + 1;
                              final p = entry.value;
                              return DataRow(cells: [
                                DataCell(Text('$i')),
                                DataCell(Text(p['name'] ?? '')),
                                DataCell(Text('${p['total_qty'] ?? 0}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}
