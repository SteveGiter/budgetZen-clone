import 'package:flutter/material.dart';
import '../../colors/app_colors.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  void _handleTabSelected(int index, BuildContext context) {
    if (index == currentIndex) return; // Éviter la navigation si déjà sur la page

    final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
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
        icon: Icon(Icons.dashboard, color: Colors.white),
        selectedIcon: Icon(Icons.dashboard, color: Colors.black),
        label: 'Tableau de bord',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_add, color: Colors.white),
        selectedIcon: Icon(Icons.person_add, color: Colors.black),
        label: 'Ajouter utilisateurs',
      ),
      NavigationDestination(
        icon: Icon(Icons.person, color: Colors.white),
        selectedIcon: Icon(Icons.person, color: Colors.black),
        label: 'Profil admin',
      ),
    ];
  }
}