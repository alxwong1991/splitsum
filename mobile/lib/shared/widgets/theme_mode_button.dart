import 'package:flutter/material.dart';

import '../../core/theme/theme_scope.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    if (controller == null) return const SizedBox.shrink();
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      initialValue: controller.value,
      onSelected: (mode) => controller.value = mode,
      icon: Icon(switch (controller.value) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      }),
      itemBuilder: (_) => [
        for (final mode in ThemeMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: controller.value == mode,
            child: Text(switch (mode) {
              ThemeMode.system => 'System',
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
            }),
          ),
      ],
    );
  }
}
