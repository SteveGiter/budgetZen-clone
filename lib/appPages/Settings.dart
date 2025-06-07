import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _notificationsEnabled = true;
  User? _currentUser;
  String _userName = "Non renseigné";

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(_currentUser!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _userName = userDoc.data()?['nomPrenom'] ?? "Non renseigné";
      });
    }
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ? 'Notifications activées' : 'Notifications désactivées',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/ProfilePage');
  }

  void _navigateToSavingsManagement() {
    Navigator.pushNamed(context, '/historique-epargne');
  }

  void _navigateToAddSavings() {
    Navigator.pushNamed(context, '/SavingsGoalsPage');
  }

  void _navigateToHelp() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Page d\'aide en cours de développement')),
            Icon(Icons.close, color: Colors.white),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Paramètres',
        showDarkModeButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header avec avatar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor.withOpacity(0.3),
                                AppColors.primaryColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser?.photoURL == null
                              ? Icon(Icons.person,
                              size: 60, color: AppColors.primaryColor)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Compte
              _buildSectionCard(
                title: 'Compte',
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Mon profil',
                    subtitle: 'Modifier vos informations personnelles',
                    onTap: _navigateToProfile,
                  ),
                  _buildSettingItem(
                    icon: Icons.savings_outlined,
                    title: 'Voir les épargnes',
                    subtitle: 'Consulter vos épargnes',
                    onTap: _navigateToSavingsManagement,
                  ),
                  _buildSettingItem(
                    icon: Icons.add_circle_outline,
                    title: 'Définir un objectif d\'épargne',
                    subtitle: 'Créer un nouvel objectif d\'épargne',
                    onTap: _navigateToAddSavings,
                    showDivider: false,
                  ),
                ],
              ),

              // Section Préférences
              _buildSectionCard(
                title: 'Préférences',
                children: [
                  Consumer<ThemeNotifier>(
                    builder: (context, themeNotifier, child) {
                      return _buildSettingItem(
                        icon: themeNotifier.isDark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        title: 'Apparence',
                        subtitle: 'Changer le thème de l\'application',
                        onTap: () => themeNotifier.toggleTheme(),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Activer/désactiver les notifications',
                    onTap: null,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: AppColors.primaryColor,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              // Section Support
              _buildSectionCard(
                title: 'Support',
                children: [
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Aide & Support',
                    subtitle: 'FAQ et contact du support',
                    onTap: _navigateToHelp,
                  ),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    subtitle: 'Version et informations légales',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/AboutPage',
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),

              // Bouton de déconnexion
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => confirmLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index != 3) {
            final routes = ['/HomePage', '/TransactionPage', '/historique-epargne-no-back', '/SettingsPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}