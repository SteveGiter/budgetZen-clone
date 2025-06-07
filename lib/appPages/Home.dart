import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../services/firebase/firestore.dart';
import '../widgets/EpargnesChart.dart';
import '../widgets/ForHomePage/AddExpenseDialog.dart';
import '../widgets/ForHomePage/AddIncomeDialog.dart';
import '../widgets/ForHomePage/AddSavingsDialog.dart';
import '../widgets/RevenusChart.dart';
import '../widgets/CircularChart.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/DepensesChart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> containerTitle = [
    'Mon budget',
    'Mes dépenses',
    'Mes revenus',
    'Mes épargnes'
  ];

  List<IconData> cardIcons = [
    Icons.account_balance_wallet,
    Icons.shopping_cart,
    Icons.monetization_on,
    Icons.savings,
  ];

  List<Color> cardBgColor = [
    Colors.grey.shade300,
    Colors.pink.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
  ];

  List<String> infoMontant = [
    'Budget actuel disponible',
    'Montant total de toutes les dépenses',
    'Montant total des revenus',
    'Montant total épargné'
  ];

  final space = const SizedBox(height: 10);
  double budget = 0.0;
  double depenses = 0.0;
  double revenus = 0.0;
  double epargnes = 0.0;
  bool isExpanded = false;
  int selectedMonth = DateTime.now().month;

  // Propriétés temporaires pour le getter montantAAjouter
  double _tempAmount = 0.0;
  double _tempCurrentMontantActuel = 0.0;
  double _tempMontantCible = 0.0;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<double>? _depensesSubscription;
  StreamSubscription<double>? _revenusSubscription;
  StreamSubscription<double>? _epargnesSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  final List<Map<String, String>> revenuCategories = [
    {'value': 'Salaire', 'label': '💰 Salaire'},
    {'value': 'Investissement', 'label': '📈 Investissement'},
    {'value': 'Cadeau', 'label': '🎁 Cadeau'},
    {'value': 'Vente', 'label': '🛒 Vente'},
    {'value': 'Autre', 'label': '❓ Autre'},
  ];

  final List<Map<String, String>> depenseCategories = [
    {'value': 'Nourriture', 'label': '🍔 Nourriture'},
    {'value': 'Transport', 'label': '🚗 Transport'},
    {'value': 'Logement', 'label': '🏠 Logement'},
    {'value': 'Loisirs', 'label': '🎭 Loisirs'},
    {'value': 'Santé', 'label': '🏥 Santé'},
    {'value': 'Éducation', 'label': '📚 Éducation'},
    {'value': 'Autre', 'label': '❓ Autre'},
  ];

  final List<Map<String, String>> epargneCategories = [
    {'value': 'Prévisionnel', 'label': '📅 Prévisionnel'},
    {'value': 'Projet', 'label': '🎯 Projet'},
    {'value': 'Urgence', 'label': '🚨 Urgence'},
    {'value': 'Retraite', 'label': '👴 Retraite'},
    {'value': 'Investissement', 'label': '📈 Investissement'},
    {'value': 'Autre', 'label': '❓ Autre'},
  ];

  // Getter pour montantAAjouter
  double get montantAAjouter {
    final montantRestant = _tempMontantCible - _tempCurrentMontantActuel;
    return _tempAmount > montantRestant ? montantRestant : _tempAmount;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              budget = (data['budgetActuel'] as num?)?.toDouble() ?? 0.0;
            });
          }
        }
      });

      _updateSubscriptions(user.uid);
    }
  }

  void _updateSubscriptions(String userId) {
    _depensesSubscription?.cancel();
    _revenusSubscription?.cancel();
    _epargnesSubscription?.cancel();

    _firestoreService.getTotalDepenses(userId).then((total) {
      if (mounted) setState(() => depenses = total);
    });
    _firestoreService.getTotalRevenus(userId).then((total) {
      if (mounted) setState(() => revenus = total);
    });
    _firestoreService.getTotalEpargnes(userId).then((total) {
      if (mounted) setState(() => epargnes = total);
    });

    _depensesSubscription = _firestoreService
        .streamTotalDepensesByMonth(userId, selectedMonth)
        .listen((total) {
      if (mounted) {
        setState(() {
          depenses = total;
        });
      }
    });

    _revenusSubscription = _firestoreService
        .streamTotalRevenusByMonth(userId, selectedMonth)
        .listen((total) {
      if (mounted) {
        setState(() {
          revenus = total;
        });
      }
    });

    _epargnesSubscription = _firestoreService
        .streamTotalEpargnesByMonth(userId, selectedMonth)
        .listen((total) {
      if (mounted) {
        setState(() {
          epargnes = total;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _depensesSubscription?.cancel();
    _revenusSubscription?.cancel();
    _epargnesSubscription?.cancel();
    super.dispose();
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: isDarkMode ? AppColors.darkSecondaryColor : Colors.blue.shade800,
                size: 50,
              ),
              const SizedBox(width: 10),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20,
                  color: isDarkMode ? AppColors.darkSecondaryColor : Colors.blue.shade800,
                ),
              ),
            ],
          ),
          _MonthDropdown(
            selectedMonth: selectedMonth,
            onChanged: (value) {
              if (value != null && value != selectedMonth) {
                setState(() {
                  selectedMonth = value;
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    _updateSubscriptions(user.uid);
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Accueil',
        showBackArrow: false,
        showDarkModeButton: true,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: containerTitle.length,
              itemBuilder: (BuildContext context, int index) {
                double montant = 0.0;
                switch (index) {
                  case 0:
                    montant = budget;
                    break;
                  case 1:
                    montant = depenses;
                    break;
                  case 2:
                    montant = revenus;
                    break;
                  case 3:
                    montant = epargnes;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 5.0,
                    child: IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDarkMode
                                ? AppColors.darkCardColors[index % AppColors.darkCardColors.length]
                                : cardBgColor[index],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      cardIcons[index],
                                      size: 32,
                                      color: isDarkMode
                                          ? AppColors.darkPrimaryColor
                                          : AppColors.primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      containerTitle[index],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'LucidaCalligraphy',
                                        color: isDarkMode
                                            ? AppColors.darkTextColor
                                            : AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                space,
                                Text(
                                  'Montant : ${montant.toStringAsFixed(2)} FCFA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
                                  ),
                                ),
                                space,
                                Text(
                                  infoMontant[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? AppColors.darkSecondaryTextColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildHeader(isDarkMode),
          const SizedBox(height: 20),
          CircularChart(
            userId: user?.uid ?? '',
            selectedMonth: selectedMonth,
          ),
          const SizedBox(height: 20),
          RevenusChart(
            userId: user?.uid ?? '',
            selectedMonth: selectedMonth,
          ),
          const SizedBox(height: 20),
          DepensesChart(
            userId: user?.uid ?? '',
            selectedMonth: selectedMonth,
          ),
          const SizedBox(height: 20),
          EpargnesChart(
            userId: user?.uid ?? '',
            selectedMonth: selectedMonth,
          ),
        ],
      ),

      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 70,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'main-fab',
              shape: const CircleBorder(),
              backgroundColor: isDarkMode ? AppColors.darkSecondaryColor : Colors.blueAccent,
              child: Icon(
                isExpanded ? Icons.remove : Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded) ...[
            Positioned(
              bottom: 130,
              right: 16,
              child: Tooltip(
                message: "Ajouter un revenu",
                child: FloatingActionButton(
                  heroTag: 'income-fab',
                  shape: const CircleBorder(),
                  backgroundColor: isDarkMode ? AppColors.darkSecondaryColor : Colors.greenAccent,
                  child: const Icon(Icons.monetization_on, color: Colors.white),
                  onPressed: () {
                    _showAddIncomeDialog(context);
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 190,
              right: 16,
              child: Tooltip(
                message: "Ajouter une dépense",
                child: FloatingActionButton(
                  heroTag: 'expense-fab',
                  shape: const CircleBorder(),
                  backgroundColor: isDarkMode ? AppColors.darkSecondaryColor : Colors.pinkAccent,
                  child: const Icon(Icons.shopping_basket, color: Colors.white),
                  onPressed: () {
                    _showAddExpenseDialog(context);
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: 16,
              child: Tooltip(
                message: "Ajouter une épargne",
                child: FloatingActionButton(
                  heroTag: 'savings-fab',
                  shape: const CircleBorder(),
                  backgroundColor: isDarkMode ? AppColors.darkSecondaryColor : Colors.blueAccent,
                  child: const Icon(Icons.savings, color: Colors.white),
                  onPressed: () {
                    _showAddSavingsDialog(context);
                  },
                ),
              ),
            ),
          ],
        ],
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index != 0) {
            final routes = ['/HomePage', '/TransactionPage', '/historique-epargne-no-back', '/SettingsPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Future<void> _showAddIncomeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddIncomeDialog(
        onIncomeAdded: (amount, category, description) async {
          await _addIncome(amount, category, description);
        },
        revenuCategories: revenuCategories,
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        onExpenseAdded: (amount, category, description) async {
          await _addExpense(amount, category, description);
        },
        depenseCategories: depenseCategories,
      ),
    );
  }

  Future<void> _showAddSavingsDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour ajouter une épargne'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final goalsSnapshot = await _firestoreService.getObjectifsEpargne(user.uid);
      bool allGoalsUnusable = false;

      if (goalsSnapshot.docs.isNotEmpty) {
        allGoalsUnusable = goalsSnapshot.docs.every((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final montantActuel = (data['montantActuel'] as num?)?.toDouble() ?? 0.0;
          final montantCible = (data['montantCible'] as num?)?.toDouble() ?? 0.0;
          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          final dateLimite = data['dateLimite'] as Timestamp?;
          final isExpired = dateLimite != null && dateLimite.toDate().isBefore(DateTime.now());

          // Un objectif est inutilisable s'il est atteint ou expiré
          return isCompleted || montantActuel >= montantCible || isExpired;
        });
      }

      if (goalsSnapshot.docs.isEmpty || allGoalsUnusable) {
        await _showNoSavingsGoalDialog(context, goalsSnapshot.docs.isEmpty);
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AddSavingsDialog(
          onSavingsAdded: (amount, category, description, goalId) async {
            await _addSavings(amount, category, description, goalId);
          },
          userId: user.uid,
          firestoreService: _firestoreService,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showNoSavingsGoalDialog(BuildContext context, bool noGoalsDefined) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun objectif d\'épargne disponible'),
        content: Text(
          noGoalsDefined
              ? 'Vous n\'avez pas encore défini d\'objectif d\'épargne. Veuillez en créer un pour ajouter des épargnes.'
              : 'Tous vos objectifs d\'épargne sont soit atteints, soit expirés. Veuillez créer un nouvel objectif pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/SavingsGoalsPage');
            },
            child: const Text('Définir un objectif'),
          ),
        ],
      ),
    );
  }

  Future<void> _addIncome(double amount, String category,
      String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestoreService.addRevenu(
        userId: user.uid,
        montant: amount,
        categorie: category,
        description: description.isNotEmpty ? description : null,
      );

      await _firestoreService.firestore
          .collection('budgets')
          .doc(user.uid)
          .update({
        'budgetActuel': FieldValue.increment(amount),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Revenu de ${amount.toStringAsFixed(2)} FCFA ajouté'),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Erreur lors de l\'ajout du revenu: ${e.toString()}'),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addExpense(double amount, String category,
      String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final budgetDoc = await _firestoreService.firestore
          .collection('budgets')
          .doc(user.uid)
          .get();
      final currentBudget = (budgetDoc.data()?['budgetActuel'] as num?)
          ?.toDouble() ?? 0.0;

      if ((currentBudget - amount) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text('Opération impossible: budget insuffisant')),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestoreService.addDepense(
        userId: user.uid,
        montant: amount,
        categorie: category,
        description: description.isNotEmpty ? description : null,
      );

      await _firestoreService.firestore
          .collection('budgets')
          .doc(user.uid)
          .update({
        'budgetActuel': FieldValue.increment(-amount),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Dépense de ${amount.toStringAsFixed(2)} FCFA ajoutée'),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Erreur lors de l\'ajout de la dépense: ${e.toString()}'),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addSavings(double amount, String category, String? description, String goalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur non connecté.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestoreService.firestore.runTransaction((transaction) async {
        final budgetRef = _firestoreService.firestore.collection('budgets').doc(user.uid);
        final objectifRef = _firestoreService.firestore.collection('objectifsEpargne').doc(goalId);

        final budgetSnap = await transaction.get(budgetRef);
        final objectifSnap = await transaction.get(objectifRef);

        if (!budgetSnap.exists) {
          throw Exception('Document budget introuvable.');
        }
        if (!objectifSnap.exists) {
          throw Exception('Objectif d\'épargne introuvable.');
        }

        final currentBudget = (budgetSnap.data()?['budgetActuel'] as num?)?.toDouble() ?? 0.0;
        final currentMontantActuel = (objectifSnap.data()?['montantActuel'] as num?)?.toDouble() ?? 0.0;
        final montantCible = (objectifSnap.data()?['montantCible'] as num?)?.toDouble() ?? 0.0;
        final isCompleted = (objectifSnap.data()?['isCompleted'] as bool?) ?? false;

        // Vérification si l'objectif est déjà atteint
        if (isCompleted || currentMontantActuel >= montantCible) {
          throw Exception('Cet objectif est déjà atteint. Aucune épargne supplémentaire ne peut être ajoutée.');
        }

        // Mettre à jour les valeurs temporaires pour le getter
        _tempAmount = amount;
        _tempCurrentMontantActuel = currentMontantActuel;
        _tempMontantCible = montantCible;

        // Utiliser le getter montantAAjouter
        final montantAAjouterValue = montantAAjouter;

        // Vérification du budget disponible
        if (currentBudget < montantAAjouterValue) {
          throw Exception('Budget insuffisant pour cette épargne.');
        }

        // Vérification des épargnes récentes pour éviter les doublons
        final recentEpargnes = await _firestoreService.firestore
            .collection('epargnes')
            .where('userId', isEqualTo: user.uid)
            .where('objectifId', isEqualTo: goalId)
            .where('montant', isEqualTo: montantAAjouter)
            .where('categorie', isEqualTo: category)
            .where('dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 5))))
            .get();

        if (recentEpargnes.docs.isNotEmpty) {
          throw Exception('Une épargne similaire a été ajoutée récemment. Veuillez attendre quelques secondes.');
        }

        // Ajout de l'épargne
        final epargneRef = _firestoreService.firestore.collection('epargnes').doc();
        transaction.set(epargneRef, {
          'userId': user.uid,
          'montant': montantAAjouter,
          'categorie': category,
          'description': description,
          'objectifId': goalId,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        // Mise à jour du budget
        transaction.update(budgetRef, {
          'budgetActuel': FieldValue.increment(-montantAAjouter),
        });

        // Mise à jour de l'objectif
        final newMontantActuel = currentMontantActuel + montantAAjouter;
        transaction.update(objectifRef, {
          'montantActuel': newMontantActuel,
          'isCompleted': newMontantActuel >= montantCible,
          'derniereMiseAJour': FieldValue.serverTimestamp(),
        });
      });

      // Afficher un message indiquant le montant réellement ajouté et la différence
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _tempAmount != montantAAjouter
                      ? 'Épargne de ${montantAAjouter.toStringAsFixed(2)} FCFA ajoutée (${(_tempAmount - montantAAjouter).toStringAsFixed(2)} FCFA excédentaires)'
                      : 'Épargne de ${montantAAjouter.toStringAsFixed(2)} FCFA ajoutée',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Réinitialiser les valeurs temporaires après utilisation
      _tempAmount = 0.0;
      _tempCurrentMontantActuel = 0.0;
      _tempMontantCible = 0.0;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Erreur lors de l\'ajout de l\'épargne: ${e.toString()}')),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _MonthDropdown extends StatelessWidget {
  final int selectedMonth;
  final ValueChanged<int?> onChanged;

  const _MonthDropdown({
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: selectedMonth,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: colors.onSurface),
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
        dropdownColor: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        items: List.generate(12, (index) => index + 1).map((month) {
          return DropdownMenuItem<int>(
            value: month,
            child: Text(
              _getMonthName(month),
              style: theme.textTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return monthNames[month - 1];
  }
}