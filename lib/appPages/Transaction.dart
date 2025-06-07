import 'package:flutter/material.dart';
import '../widgets/Historique_transactions.dart';
import '../widgets/Transaction_demo.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HistoriqueTransaction(),
    MoneyTransferPage(),
  ];
  final List<String> _pageTitles = [
    'Historique des transactions',
    'Transfert d\'argent',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _pageTitles[_currentIndex],
        showBackArrow: false,
        showDarkModeButton: true,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flèche gauche
              _currentIndex > 0
                  ? Tooltip(
                message: 'Page précédente',
                child: IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentIndex--;
                    });
                  },
                  color: Colors.white,
                ),
              )
                  : IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: null,
                color: Colors.white.withOpacity(0.5),
              ),

              // Flèche droite
              _currentIndex < _pages.length - 1
                  ? Tooltip(
                message: 'Page suivante',
                child: IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentIndex++;
                    });
                  },
                  color: Colors.white,
                ),
              )
                  : IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: null,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index != 1) {
            final routes = ['/HomePage', '/TransactionPage', '/historique-epargne-no-back', '/SettingsPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}