import 'package:flutter/material.dart';
import '../../colors/app_colors.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDarkMode;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isDarkMode = false,
  });

  void _handleTabSelected(int index, BuildContext context) {
    if (index == currentIndex) return;

    final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
    Navigator.pushReplacementNamed(context, routes[index]);
    onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark || isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: Theme(
          data: theme.copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
                    (Set<MaterialState> states) {
                  return TextStyle(
                    color: states.contains(MaterialState.selected)
                        ? isDark ? AppColors.darkSecondaryColor : AppColors.secondaryColor
                        : isDark ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
                },
              ),
            ),
          ),
          child: NavigationBar(
            height: 70,
            selectedIndex: currentIndex,
            backgroundColor: isDark ? AppColors.darkCardColor : AppColors.cardColor,
            indicatorColor: (isDark ? AppColors.darkSecondaryColor : AppColors.secondaryColor).withOpacity(0.2),
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => _handleTabSelected(index, context),
            destinations: _buildNavigationDestinations(isDark),
          ),
        ),
      ),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations(bool isDark) {
    final unselectedColor = isDark ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor;
    final selectedColor = isDark ? AppColors.darkSecondaryColor : AppColors.secondaryColor;

    return [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined, color: unselectedColor),
        selectedIcon: Icon(Icons.dashboard, color: selectedColor),
        label: 'Tableau de bord',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_add_outlined, color: unselectedColor),
        selectedIcon: Icon(Icons.person_add, color: selectedColor),
        label: 'Ajouter utilisateurs',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, color: unselectedColor),
        selectedIcon: Icon(Icons.person, color: selectedColor),
        label: 'Profil admin',
      ),
    ];
  }
}