// lib/screens/home_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../services/db_service.dart';

import 'sales_screen.dart';
import 'caja_sessions_screen.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'areas_screen.dart';
import 'movimientos_screen.dart';
import 'reportes_screen.dart';
import 'export_screen.dart';
import 'users_screen.dart';
import 'config_screen.dart';
import '../core/session_manager.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final session = context.watch<SessionManager>();
    final appMode = DBService.getAppMode();

    final pages = <Widget>[];
    final nav = <NavigationDestination>[];

    // Ventas
    pages.add(const SalesScreen());
    nav.add(const NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Ventas'));

    // Caja
    pages.add(const CajaSessionsScreen());
    nav.add(const NavigationDestination(icon: Icon(Icons.money), label: 'Caja'));

    // PRIMARY
    if (appMode == 'primary') {
      if (auth.isAdmin || auth.isSupervisor) {
        pages.add(const DashboardScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'));
      }

      if (auth.isAdmin) {
        pages.add(const ConfigScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.settings), label: 'Config'));
      }
    }

    // PRO
    if (appMode == 'pro') {
      if (auth.isAdmin || auth.isSupervisor) {
        pages.add(const DashboardScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'));
      }

      if (auth.isAdmin || auth.user?['role'] == 'storekeeper') {
        pages.add(const ProductsScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.inventory), label: 'Productos'));

        pages.add(const AreasScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.warehouse), label: 'Áreas'));

        pages.add(const MovimientosScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.compare_arrows), label: 'Movimientos'));
      }

      if (auth.isAdmin || auth.isSupervisor) {
        pages.add(const ReportesScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.analytics), label: 'Reportes'));

        pages.add(const ExportScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.file_download), label: 'Exportar'));
      }

      if (auth.isAdmin) {
        pages.add(const UsersScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.people), label: 'Usuarios'));

        pages.add(const ConfigScreen());
        nav.add(const NavigationDestination(icon: Icon(Icons.settings), label: 'Config'));
      }
    }

    // Texto compacto para el label del FAB
    final fabLabel = 'Vender${session.sessionId != null ? ' #${session.sessionId}' : ''}';

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => currentIndex = i),
        destinations: nav,
      ),

      // FloatingActionButton reubicado y con padding para evitar solapamientos
      floatingActionButton: session.isOpen
          ? Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Acceso rápido a ventas si la caja está abierta
                  setState(() => currentIndex = 0);
                },
                icon: const Icon(Icons.point_of_sale),
                label: Text(fabLabel),
              ),
            )
          : null,

      // Ubicación del FAB: startFloat evita que quede encima de botones en el centro inferior
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // Si prefieres que el botón no sea flotante en absoluto, usa persistentFooterButtons:
      // persistentFooterButtons: session.isOpen
      //     ? [
      //         ElevatedButton.icon(
      //           onPressed: () => setState(() => currentIndex = 0),
      //           icon: const Icon(Icons.point_of_sale),
      //           label: Text(fabLabel),
      //         )
      //       ]
      //     : null,
    );
  }
}
