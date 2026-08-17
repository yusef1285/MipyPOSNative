import 'package:flutter/material.dart';
import 'screens/web_dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MipyPOSWeb());
}

class MipyPOSWeb extends StatelessWidget {
  const MipyPOSWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MipyPOS WEB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WebDashboard(),
    );
  }
}