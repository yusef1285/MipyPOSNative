import 'package:flutter/material.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperAdmin'),
      ),
      body: const Center(
        child: Text(
          'Panel SuperAdmin',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}