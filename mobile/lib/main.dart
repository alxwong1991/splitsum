import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'features/auth/screens/welcome_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeMode = ValueNotifier(ThemeMode.system);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeMode,
      child: ValueListenableBuilder(
        valueListenable: _themeMode,
        builder: (_, mode, _) => MaterialApp(
          title: 'SplitSum',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const WelcomeScreen(),
        ),
      ),
    );
  }
}
