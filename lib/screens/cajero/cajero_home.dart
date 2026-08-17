import 'package:flutter/material.dart';

class CashierHome extends StatelessWidget {
  const CashierHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dependiente'),
      ),
      body: const Center(
        child: Text(
          'Panel Dependiente',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}