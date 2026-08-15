import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../widgets/branding_widgets.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  double sales = 0;
  int products = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    sales = await DBService.todaySales();
    products = (await DBService.getProducts()).length;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogo(height: 32),
            SizedBox(width: 14),
            Text("MipyPOS ADMIN PANEL"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                children: [
                  card("Ventas Hoy", "\$${sales.toStringAsFixed(2)}"),
                  card("Productos", "$products"),
                  card("Sistema", "ONLINE"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CopyrightText(),
            ),
          ],
        ),
      ),
    );
  }

  Widget card(String title, String value) {
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
