import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../colors/app_colors.dart';
import '../main.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onDarkModePressed;
  final bool showBackArrow;
  final String? backDestination;
  final bool showDarkModeButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onDarkModePressed,
    this.showBackArrow = false,
    this.backDestination,
    this.showDarkModeButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondaryColor,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: null, // Suppression de la flèche de déconnexion
      actions: [
        ...?actions,
        if (showDarkModeButton)
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return Tooltip(
                message: themeNotifier.isDark
                    ? 'Revenir en mode clair'
                    : 'Activer le mode sombre',
                child: IconButton(
                  icon: Icon(
                    themeNotifier.isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    themeNotifier.toggleTheme();
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
