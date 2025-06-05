import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../services/firebase/firestore.dart';
import '../widgets/EpargnesChart.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Stream pour le budget actuel
      _userSubscription = FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            budget = (data['budgetActuel'] as num?)?.toDouble() ?? 0.0;
          });
        }
      });

      // Streams pour les totaux mensuels
      _updateSubscriptions(user.uid);
    }
  }

  void _updateSubscriptions(String userId) {
    // Annuler les abonnements existants
    _depensesSubscription?.cancel();
    _revenusSubscription?.cancel();
    _epargnesSubscription?.cancel();

    // Charger les données initiales
    _firestoreService.getTotalDepenses(userId).then((total) {
      if (mounted) setState(() => depenses = total);
    });
    _firestoreService.getTotalRevenus(userId).then((total) {
      if (mounted) setState(() => revenus = total);
    });
    _firestoreService.getTotalEpargnes(userId).then((total) {
      if (mounted) setState(() => epargnes = total);
    });

    // S'abonner aux streams mensuels
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
            final routes = ['/HomePage', '/TransactionPage', '/HistoriqueObjectifsEpargneWithoutBackArrow', '/SettingsPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Future<void> _showAddIncomeDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = revenuCategories[0]['value']!;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un revenu'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: revenuCategories.map((Map<String, String> category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedCategory = newValue;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnelle)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                final description = descriptionController.text;
                await _addIncome(amount, selectedCategory, description);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = depenseCategories[0]['value']!;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une dépense'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: depenseCategories.map((Map<String, String> category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedCategory = newValue;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnelle)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                final description = descriptionController.text;
                await _addExpense(amount, selectedCategory, description);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSavingsDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non connecté.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Vérifier si l'utilisateur a des objectifs d'épargne
      final goalsSnapshot = await _firestoreService.getObjectifsEpargne(user.uid);
      if (goalsSnapshot.docs.isEmpty) {
        return _showNoSavingsGoalDialog(context);
      }

      // Récupérer tous les objectifs d'épargne pour la liste déroulante
      List<Map<String, dynamic>> savingsGoals = goalsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nomObjectif': data['nomObjectif'] as String,
          'categorie': data['categorie'] as String?,
        };
      }).toList();

      final amountController = TextEditingController();
      final descriptionController = TextEditingController();
      String selectedGoalId = savingsGoals[0]['id']!;
      String? selectedGoalCategory = savingsGoals[0]['categorie'];
      final formKey = GlobalKey<FormState>();

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Ajouter une épargne'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (FCFA)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGoalId,
                      items: savingsGoals.map((Map<String, dynamic> goal) {
                        return DropdownMenuItem<String>(
                          value: goal['id'],
                          child: Text(goal['nomObjectif']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedGoalId = newValue;
                            selectedGoalCategory = savingsGoals
                                .firstWhere((goal) => goal['id'] == newValue)['categorie'];
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Objectif d\'épargne',
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnelle)',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/SavingsGoalsPage');
                },
                child: const Text(
                  'Créer un nouvel objectif',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final amount = double.parse(amountController.text);
                    final description =
                    descriptionController.text.isNotEmpty ? descriptionController.text : null;
                    if (selectedGoalCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('L\'objectif sélectionné n\'a pas de catégorie définie.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await _addSavings(amount, selectedGoalCategory!, description, selectedGoalId);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      );

      amountController.dispose();
      descriptionController.dispose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des objectifs: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showNoSavingsGoalDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun objectif d\'épargne défini'),
        content: const Text(
            'Vous devez d\'abord définir un objectif d\'épargne avant de pouvoir ajouter des épargnes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer cette boîte de dialogue
              // Naviguer vers la page de création d'objectifs d'épargne
              Navigator.pushNamed(context, '/SavingsGoalsPage'); // Assurez-vous que cette route existe
            },
            child: const Text('Définir un objectif'),
          ),
        ],
      ),
    );
  }

  Future<void> _addIncome(double amount, String category, String description) async {
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
                child: Text('Revenu de ${amount.toStringAsFixed(2)} FCFA ajouté'),
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
                child: Text('Erreur lors de l\'ajout du revenu: ${e.toString()}'),
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

  Future<void> _addExpense(double amount, String category, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Vérifier que le budget ne deviendra pas négatif
      final budgetDoc = await _firestoreService.firestore.collection('budgets').doc(user.uid).get();
      final currentBudget = (budgetDoc.data()?['budgetActuel'] as num?)?.toDouble() ?? 0.0;

      if ((currentBudget - amount) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Opération impossible: budget insuffisant')),
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
                child: Text('Dépense de ${amount.toStringAsFixed(2)} FCFA ajoutée'),
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
                child: Text('Erreur lors de l\'ajout de la dépense: ${e.toString()}'),
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
        SnackBar(
          content: Text('Utilisateur non connecté.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Vérifier que le budget ne deviendra pas négatif
      final budgetDoc = await _firestoreService.firestore.collection('budgets').doc(user.uid).get();
      final currentBudget = (budgetDoc.data()?['budgetActuel'] as num?)?.toDouble() ?? 0.0;

      if ((currentBudget - amount) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Opération impossible: budget insuffisant')),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Exécuter l'ajout de l'épargne dans une transaction pour la cohérence
      await _firestoreService.firestore.runTransaction((transaction) async {
        final budgetRef = _firestoreService.firestore.collection('budgets').doc(user.uid);
        final budgetSnap = await transaction.get(budgetRef);
        final currentBudget = (budgetSnap.data()?['budgetActuel'] as num?)?.toDouble() ?? 0.0;

        if (currentBudget < amount) {
          throw Exception('Budget insuffisant pour cette épargne.');
        }

        await _firestoreService.addEpargne(
          userId: user.uid,
          montant: amount,
          categorie: category,
          description: description,
          objectifId: goalId,
        );

        transaction.update(budgetRef, {
          'budgetActuel': FieldValue.increment(-amount),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Épargne de ${amount.toStringAsFixed(2)} FCFA ajoutée')),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
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
              Expanded(child: Text('Erreur lors de l\'ajout de l\'épargne: ${e.toString()}')),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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