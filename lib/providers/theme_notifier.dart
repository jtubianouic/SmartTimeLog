import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier({ThemeMode initialMode = ThemeMode.light}) 
    : super(initialMode);

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    value = mode;
  }

  bool get isDarkMode => value == ThemeMode.dark;
  bool get isLightMode => value == ThemeMode.light;
}
