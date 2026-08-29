// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool processing = false;
  bool remember = false; // opcional: casilla "Recordarme"

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final auth = context.read<AuthController>();
    final username = userCtrl.text.trim();
    final password = passCtrl.text;

    // Validación local antes de llamar al servicio
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese usuario y contraseña')));
      return;
    }

    // Debug temporal para Web: ver en consola lo que llega desde la UI
    debugPrint('Login attempt -> username: $username, password length: ${password.length}, remember: $remember');

    setState(() => processing = true);
    try {
      final ok = await auth.login(username, password, persist: remember);
      if (ok) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña incorrectos')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        automaticallyImplyLeading: false,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF4FF),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.94, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 70,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Bienvenido',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accede a tu panel POS profesional',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: userCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _doLogin(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(
                                value: remember,
                                onChanged: (v) => setState(() => remember = v ?? false),
                              ),
                              const Expanded(child: Text('Recordarme')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: processing || auth.isLoading ? null : _doLogin,
                            icon: processing || auth.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(processing || auth.isLoading ? 'Entrando...' : 'Entrar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
