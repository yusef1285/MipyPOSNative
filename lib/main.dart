// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/db_service.dart';
import 'native_bridge.dart';
import 'core/session_manager.dart';
import 'controllers/cart_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive y DBService
  await Hive.initFlutter();
  await DBService.init();
  // Configurar puente nativo <-> Dart (permite que Android invoque lógica desde `lib/`)
  try {
    NativeBridge.setup();
  } catch (e) {
    debugPrint('Warning: NativeBridge.setup() failed: $e');
  }

  // Crear instancias compartidas sin auto-login
  final auth =
      AuthController(); // no llamar loadFromStorage() para forzar login en cada arranque
  final sessionManager = SessionManager();

  // Cargar la sesión de caja en memoria ANTES de construir la UI.
  // Esto evita que la UI de ventas piense que la caja está cerrada cuando en DB hay una sesión abierta.
  try {
    await sessionManager.loadSession();
  } catch (e) {
    // No detener el arranque por un fallo en carga de sesión; log para debugging.
    debugPrint('Warning: sessionManager.loadSession() failed: $e');
  }

  // Opcional: si quieres restaurar usuario persistente en web/desktop,
  // llama a auth.loadFromStorage() aquí (controlado). Por ahora lo dejamos desactivado.
  // await auth.loadFromStorage();

  // Manejo global de errores para que no queden silenciosos en web/desktop
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiPyPOS',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // Rutas nombradas útiles para navegación consistente
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeShell(),
      },
      // Forzar inicio en login para evitar reentrada automática con sesión persistida
      initialRoute: '/',
    );
  }
}
