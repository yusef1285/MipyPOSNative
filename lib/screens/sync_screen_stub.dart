import 'package:flutter/material.dart';

class SyncScreenStub extends StatelessWidget {
  const SyncScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Sync stub: this screen is not active in the current build.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
