import 'package:flutter/material.dart';
import '../colors/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo optimisé avec taille responsive
                Image.asset(
                  'assets/logoSimple.png',
                  height: isSmallScreen ? 180 : 220,
                  width: isSmallScreen ? 180 : 220,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet,
                    size: isSmallScreen ? 80 : 100,
                    color: AppColors.secondaryColor,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),

                // Titre avec taille responsive
                Text(
                  'Maîtrisez vos finances avec BudgetZen',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryColor,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description avec padding adaptatif
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 20.0,
                  ),
                  child: Text(
                    'Solution intuitive pour gérer votre budget, épargner plus et atteindre vos objectifs sans stress.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 40),

                // Boutons avec taille adaptative
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/LoginPage'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/SignUpPage'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: AppColors.secondaryColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: AppColors.secondaryColor,
                    ),
                    child: const Text(
                      'Inscription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),

                // Sécurité avec icône stylisée
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Données sécurisées',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}