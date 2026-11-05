import 'package:flutter/material.dart';

class ThemeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeScope({
    super.key,
    required ValueNotifier<ThemeMode> controller,
    required super.child,
  }) : super(notifier: controller);

  static ValueNotifier<ThemeMode>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
