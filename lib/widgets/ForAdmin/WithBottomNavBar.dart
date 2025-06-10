import 'package:flutter/material.dart';
import 'admin_bottom_nav_bar.dart';

class WithBottomNavBar extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const WithBottomNavBar({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: currentIndex, // Utilisez le paramètre reçu
        onTabSelected: (index) {
          final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}