import 'package:flutter/material.dart';

import 'prototype/screens.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF006B63));
    return MaterialApp(
      title: 'SplitSum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colors,
        useMaterial3: true,
        scaffoldBackgroundColor: colors.surface,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
