import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'À propos',
        showBackArrow: true,
        showDarkModeButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Remplacement de l'icône et du texte par une image
              Center(
                child: Column(
                  children: [
                    // Image avec une hauteur fixe et largeur adaptative
                    Image.asset(
                      'assets/logoWithProjectName.png',
                      height: 200, // Ajustez selon vos besoins
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback si l'image ne charge pas
                        return Icon(
                          Icons.savings,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Optionnel: Sous-titre sous l'image
                    Text(
                      'Votre sérénité financière',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section Description
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Notre Philosophie',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'BudgetZen transforme la gestion financière en une expérience paisible et gratifiante. '
                            'Conçue pour les personnes qui cherchent à harmoniser leurs finances avec leur bien-être, '
                            'notre application vous guide vers une relation sereine avec votre argent.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Fonctionnalités
              Text(
                'Fonctionnalités Zen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildFeatureCards(context),
              const SizedBox(height: 24),

              // Section Contact
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.contact_support,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contact Zen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context,
                        icon: Icons.email,
                        text: 'support@budgetzen.app',
                      ),
                      _buildContactItem(
                        context,
                        icon: Icons.phone,
                        text: '+237 6 86 96 28 46',
                      ),
                      _buildContactItem(
                        context,
                        icon: Icons.language,
                        text: 'www.budgetzen.app',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nos équipes sont disponibles du lundi au vendredi, de 9h à 18h.',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Version de l'app
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureCards(BuildContext context) {
    final features = [
      {
        'icon': Icons.insights,
        'title': 'Analyses apaisantes',
        'description': 'Visualisez vos finances avec des graphiques clairs et des insights personnalisés'
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Budgets harmonieux',
        'description': 'Créez des budgets réalistes qui s\'adaptent à votre rythme de vie'
      },
      {
        'icon': Icons.flag,
        'title': 'Objectifs inspirants',
        'description': 'Définissez et atteignez vos objectifs financiers sans stress'
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Rappels bienveillants',
        'description': 'Des notifications utiles qui ne vous submergent pas'
      },
    ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildContactItem(BuildContext context, {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}