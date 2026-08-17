import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../widgets/branding_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> ventas = [];

  @override
  void initState() {
    super.initState();
    loadVentas();
  }

  Future<void> loadVentas() async {
    ventas = await DBService.getSalesOfDay();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 28),
            SizedBox(width: 12),
            Text('Dashboard'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: ventas.length,
              itemBuilder: (_, i) {
                final v = ventas[i];
                return ListTile(
                  title: Text('Venta #${v['id']}'),
                  subtitle: Text('${v['method']} - ${v['total']}'),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: CopyrightText(),
          ),
        ],
      ),
    );
  }
}
