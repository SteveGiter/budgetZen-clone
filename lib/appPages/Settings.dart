import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for currentUser
import '../colors/app_colors.dart';
import '../main.dart';
import '../utils/logout_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // État par défaut pour les notifications
  User? _currentUser; // Store current user

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Fetch current user on init
  }

  // Getter for notificationsEnabled
  bool get notificationsEnabled => _notificationsEnabled;

  // Getter for currentUser
  User? get currentUser => _currentUser;

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    // TODO: Ajouter la logique pour activer/désactiver les notifications via Firebase ou autre service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications activées' : 'Notifications désactivées',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/ProfilePage'); // Corrected route name to match main.dart
  }

  void _navigateToHelp() {
    // TODO: Implémenter la navigation vers la page d'aide
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Page d\'aide en cours de développement'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Paramètres',
        showBackArrow: true,
        backDestination: '/HomePage',
        showDarkModeButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated CircleAvatar with currentUser from FirebaseAuth
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.transparent, // Pas de fond externe
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser?.photoURL == null
                          ? Icon(Icons.person, size: 60, color: AppColors.primaryColor)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Mon Profil
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.person_outline, color: AppColors.primaryColor),
                  title: const Text('Mon profil'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _navigateToProfile,
                ),
              ),
              const SizedBox(height: 16),

              // Section Notifications
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  activeColor: AppColors.primaryColor,
                  title: const Text('Notifications'),
                  subtitle: const Text('Activer ou désactiver les notifications'),
                  value: notificationsEnabled,
                  onChanged: _toggleNotifications,
                  secondary: Icon(Icons.notifications_outlined, color: AppColors.secondaryTextColor),
                ),
              ),
              const SizedBox(height: 16),

              // Section Mode Sombre
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Consumer<ThemeNotifier>(
                  builder: (context, themeNotifier, child) {
                    return SwitchListTile(
                      activeColor: AppColors.primaryColor,
                      title: const Text('Mode sombre'),
                      subtitle: const Text('Activer ou désactiver le mode sombre'),
                      value: themeNotifier.isDark,
                      onChanged: (value) {
                        themeNotifier.toggleTheme();
                      },
                      secondary: Icon(
                        themeNotifier.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: AppColors.secondaryTextColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Section Aide
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.help_outline, color: AppColors.primaryColor),
                  title: const Text('Aide'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _navigateToHelp,
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Déconnexion positioned closer to bottomNavigationBar
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(
                      Radius.circular(30), // Fully rounded for better integration
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => confirmLogout(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                    ),
                    child: const Text('Déconnexion'),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Space to avoid overlap with bottomNavigationBar
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          // Pas de navigation ici, gérée par CustomBottomNavBar
        },
      ),
    );
  }
}