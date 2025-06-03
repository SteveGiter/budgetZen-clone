import 'package:flutter/material.dart';
import '../colors/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  void _handleTabSelected(int index, BuildContext context) {
    if (index == currentIndex) return; // Éviter la navigation si déjà sur la page

    final routes = ['/HomePage', '/TransactionPage', '/SettingsPage'];
    Navigator.pushReplacementNamed(context, routes[index]);
    onTabSelected(index); // Mettre à jour l'index dans la page parente
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: AppColors.secondaryColor,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (index) => _handleTabSelected(index, context),
        destinations: _buildNavigationDestinations(),
      ),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home, color: Colors.white),
        selectedIcon: Icon(Icons.home, color: Colors.black),
        label: 'Accueil',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt, color: Colors.white),
        selectedIcon: Icon(Icons.receipt, color: Colors.black),
        label: 'Transaction',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings, color: Colors.white),
        selectedIcon: Icon(Icons.settings, color: Colors.black),
        label: 'Paramètres',
      ),
    ];
  }
}