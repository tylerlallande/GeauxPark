import 'package:flutter/material.dart';

import 'app_shell.dart';

void main() {
  runApp(const GeauxParkApp());
}

class GeauxParkApp extends StatelessWidget {
  const GeauxParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandPurple = Color(0xFF461D7C);
    const brandGold = Color(0xFFFDD023);

    return MaterialApp(
      title: 'GeauxPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          primary: brandPurple,
          secondary: brandGold,
          surface: const Color(0xFFF8F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7FB),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7FB),
          foregroundColor: Color(0xFF24152F),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFFE7E1EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: brandPurple, width: 2),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
