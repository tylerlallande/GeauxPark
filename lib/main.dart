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
    const actionBlue = Color(0xFF1464A5);
    const ink = Color(0xFF24152F);
    const surface = Color(0xFFF8F7FB);
    const border = Color(0xFFE5DDEC);

    return MaterialApp(
      title: 'GeauxPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          brightness: Brightness.light,
          primary: brandPurple,
          secondary: brandGold,
          tertiary: actionBlue,
          surface: surface,
          onSurface: ink,
        ),
        scaffoldBackgroundColor: surface,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          margin: EdgeInsets.zero,
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
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: actionBlue, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: actionBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: brandGold.withValues(alpha: 0.3),
          labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          secondaryLabelStyle: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: border),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
