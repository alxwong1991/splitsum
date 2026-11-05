import 'package:flutter/material.dart';

import 'info_note.dart';
import 'theme_mode_button.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.isDemo = true,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool isDemo;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [const ThemeModeButton(), ...?actions],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children,
                const SizedBox(height: 28),
                if (isDemo)
                  const InfoNote(
                    icon: Icons.science_outlined,
                    text:
                        'UI preview only. Synthetic data; no sign-in, payments, '
                        'or database saves. Changes reset when you leave the demo.',
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
