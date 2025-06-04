import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../colors/app_colors.dart';
import '../main.dart';

/// A customizable AppBar with support for dark mode toggle and optional back navigation.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onDarkModePressed;
  final bool showBackArrow;
  final bool showDarkModeButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onDarkModePressed,
    this.showBackArrow = false,
    this.showDarkModeButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondaryColor,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: showBackArrow
          ? IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          semanticLabel: 'Retour',
        ),
        onPressed: () {
          Navigator.pop(context); // Simply pop to return to previous page
        },
      )
          : null,
      actions: [
        ...?actions,
        if (showDarkModeButton)
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return Tooltip(
                message: themeNotifier.isDark
                    ? 'Passer au mode clair'
                    : 'Passer au mode sombre',
                child: IconButton(
                  icon: Icon(
                    themeNotifier.isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 30,
                    color: Colors.white,
                    semanticLabel: themeNotifier.isDark ? 'Mode clair' : 'Mode sombre',
                  ),
                  onPressed: () {
                    themeNotifier.toggleTheme();
                    onDarkModePressed?.call();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}