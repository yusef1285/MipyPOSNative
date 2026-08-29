import 'package:flutter/material.dart';
import '../screens/sync_screen.dart';
import '../screens/home_screen.dart';
import '../screens/products_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/cash_screen.dart';
import '../screens/dashboard_screen.dart';

class AppRouter {
  static const String home = '/home';
  static const String products = '/products';
  static const String sales = '/sales';
  static const String reports = '/reports';
  static const String inventory = '/inventory';
  static const String cash = '/cash';
  static const String dashboard = "/dashboard";
  static const String sync = "/sync";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final role = settings.arguments is String ? settings.arguments as String : 'admin';
        return MaterialPageRoute(
          builder: (_) => HomeScreen(role: role),
        );
      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case sales:
        return MaterialPageRoute(builder: (_) => const SalesScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());
      case cash:
        return MaterialPageRoute(builder: (_) => const CashScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case sync:
        return MaterialPageRoute(builder: (_) => const SyncScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
