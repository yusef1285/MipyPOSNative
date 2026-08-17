import 'package:flutter/material.dart';
import '../core/app_router.dart';

class HomeScreen extends StatelessWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  bool canAccess(String module) {
    if (role == "admin") return true;

    if (role == "cashier") {
      return module == "sales" || module == "cash";
    }

    if (role == "warehouse") {
      return module == "inventory" || module == "products";
    }

    return false;
  }

  void go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MipyPOS - $role")),
      body: ListView(
        children: [
          // Ventas
          if (canAccess("sales"))
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text("Ventas (POS)"),
              onTap: () => go(context, AppRouter.sales),
            ),

          // Productos
          if (canAccess("products"))
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("Productos"),
              onTap: () => go(context, AppRouter.products),
            ),

          // Inventario
          if (canAccess("inventory"))
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text("Inventario"),
              onTap: () => go(context, AppRouter.inventory),
            ),

          // Caja
          if (canAccess("cash"))
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text("Caja"),
              onTap: () => go(context, AppRouter.cash),
            ),

          // Reportes
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Reportes"),
            onTap: () => go(context, AppRouter.reports),
          ),

          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () => go(context, AppRouter.dashboard),
          ),

          // Sincronización
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text("Sincronización"),
            onTap: () => go(context, AppRouter.sync),
          ),
        ],
      ),
    );
  }
}