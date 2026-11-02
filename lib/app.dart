import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class GrowCapitalApp extends StatelessWidget {
  const GrowCapitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROW CAPITAL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B50),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
