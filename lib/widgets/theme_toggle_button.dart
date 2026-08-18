import 'package:flutter/material.dart';
import '../main.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return IconButton(
          onPressed: () => themeNotifier.toggleTheme(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: iconColor,
          ),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
        );
      },
    );
  }
}
