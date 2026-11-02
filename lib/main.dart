import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GeauxParkApp());
}

class GeauxParkApp extends StatelessWidget {
  const GeauxParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeauxPark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
