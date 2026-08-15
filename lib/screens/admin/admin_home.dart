import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
      ),
      body: const Center(
        child: Text(
          'Panel Administrador',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}