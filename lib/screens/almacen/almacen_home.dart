import 'package:flutter/material.dart';

class WarehouseHome extends StatelessWidget {
  const WarehouseHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almacenero'),
      ),
      body: const Center(
        child: Text(
          'Panel Almacén',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}