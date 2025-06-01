import 'package:flutter/material.dart';

import '../widgets/custom_app_bar.dart';

class AdminWelcomePage extends StatefulWidget {
  const AdminWelcomePage({super.key});

  @override
  State<AdminWelcomePage> createState() => _AdminWelcomePageState();
}

class _AdminWelcomePageState extends State<AdminWelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Administrateur',
        showBackArrow: true,
        backDestination: '/LoginPage',
        showDarkModeButton: true,
        onDarkModePressed: () {
          // Implémentez votre logique de dark mode ici
          print("Mode sombre activé");
        },
      ),
      body: Center(
        child: Text("Bienvenue sur la page des administrateurs🙂!", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
