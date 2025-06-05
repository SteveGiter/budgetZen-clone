import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../colors/app_colors.dart';
import '../services/firebase/firestore.dart';
import 'custom_app_bar.dart';
import 'custom_bottom_nav_bar.dart';

class HistoriqueObjectifsEpargne extends StatefulWidget {
  final bool showBackArrow;

  const HistoriqueObjectifsEpargne({
    super.key,
    this.showBackArrow = true,
  });

  @override
  State<HistoriqueObjectifsEpargne> createState() => _HistoriqueObjectifsEpargneState();
}

class _HistoriqueObjectifsEpargneState extends State<HistoriqueObjectifsEpargne> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat dateFormat = DateFormat('EEEE dd MMMM yyyy \'à\' HH:mm:ss', 'fr_FR');
  String _selectedFilter = 'Tout';
  final Map<String, bool> _notificationShown = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Veuillez vous connecter")),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Objectifs d\'Épargne',
        showBackArrow: widget.showBackArrow,
        showDarkModeButton: true,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackgroundColor
          : AppColors.backgroundColor,
      body: Column(
        children: [
          _buildFilterButtons(context),
          const SizedBox(height: 8),
          Expanded(
            child: _buildObjectifsList(currentUser.uid, context),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) {
            final routes = ['/HomePage', '/TransactionPage', '/HistoriqueObjectifsEpargneWithoutBackArrow', '/SettingsPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildFilterButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: ['Tout', 'En cours', 'Terminé']
              .map((label) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(label, context),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BuildContext context) {
    final isSelected = _selectedFilter == label;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isDarkMode ? AppColors.darkButtonColor : AppColors.buttonColor,
      checkmarkColor: isDarkMode ? AppColors.darkButtonTextColor : AppColors.buttonTextColor,
      labelStyle: TextStyle(
        color: isSelected
            ? (isDarkMode ? AppColors.darkButtonTextColor : AppColors.buttonTextColor)
            : (isDarkMode ? AppColors.darkTextColor : AppColors.textColor),
      ),
      backgroundColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'Tout';
        });
      },
    );
  }

  Widget _buildMonthHeader(DateTime date) {
    final moisAnnee = DateFormat('MMMM yyyy', 'fr_FR').format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              moisAnnee.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextColor
                    : AppColors.textColor,
              ),
            ),
          ),
          Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildObjectifsList(String userId, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamAllObjectifsEpargne(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: TextStyle(color: AppColors.errorColor),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimaryColor
                  : AppColors.primaryColor,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("Aucun objectif d'épargne trouvé", context);
        }

        final filteredObjectifs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final montantCible = (data['montantCible'] as num).toDouble();
          final montantActuel = (data['montantActuel'] as num?)?.toDouble() ?? 0.0;
          final isCompleted = montantActuel >= montantCible;

          if (_selectedFilter == 'En cours') return !isCompleted;
          if (_selectedFilter == 'Terminé') return isCompleted;
          return true;
        }).toList();

        if (filteredObjectifs.isEmpty) {
          return _buildEmptyState("Aucun objectif pour '$_selectedFilter'", context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredObjectifs.length,
          itemBuilder: (context, index) {
            final currentDoc = filteredObjectifs[index];
            final currentData = currentDoc.data() as Map<String, dynamic>;
            final currentDate = (currentData['dateCreation'] as Timestamp).toDate();
            final objectifId = currentDoc.id;

            bool showMonthHeader = false;
            if (index == 0) {
              showMonthHeader = true;
            } else {
              final previousData = filteredObjectifs[index - 1].data() as Map<String, dynamic>;
              final previousDate = (previousData['dateCreation'] as Timestamp).toDate();
              if (currentDate.month != previousDate.month || currentDate.year != previousDate.year) {
                showMonthHeader = true;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMonthHeader) _buildMonthHeader(currentDate),
                _buildObjectifCard(currentDoc, objectifId, context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSecondaryTextColor
        : AppColors.secondaryTextColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Aucun objectif disponible',
            child: Icon(
              Icons.savings_outlined,
              size: 100,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectifCard(QueryDocumentSnapshot doc, String objectifId, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final nomObjectif = data['nomObjectif'] as String;
    final montantCible = (data['montantCible'] as num).toDouble();
    final montantActuel = (data['montantActuel'] as num?)?.toDouble() ?? 0.0;
    final categorie = (data['categorie'] as String?) ?? 'Non défini';
    final dateCreation = (data['dateCreation'] as Timestamp).toDate();
    final dateLimite = (data['dateLimite'] as Timestamp).toDate();
    final isCompleted = montantActuel >= montantCible;

    return StreamBuilder<double>(
      stream: _firestoreService.streamMontantActuelParObjectif(objectifId),
      initialData: montantActuel,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}', style: TextStyle(color: AppColors.errorColor));
        }

        final streamedMontantActuel = snapshot.data ?? montantActuel;
        final progress = (streamedMontantActuel / montantCible).clamp(0.0, 1.0);
        final isStreamedCompleted = streamedMontantActuel >= montantCible;

        if (isStreamedCompleted && !_notificationShown.containsKey(objectifId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Félicitations ! L'objectif '$nomObjectif' est atteint !"),
                duration: const Duration(seconds: 3),
              ),
            );
            setState(() {
              _notificationShown[objectifId] = true;
            });
          });
        } else if (!isStreamedCompleted && _notificationShown.containsKey(objectifId)) {
          setState(() {
            _notificationShown.remove(objectifId);
          });
        }

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDarkMode ? AppColors.darkCardColors[0].withOpacity(0.2) : AppColors.cardColors[0];
        final textColor = isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBJECTIF D\'ÉPARGNE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nomObjectif.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${NumberFormat.decimalPattern('fr').format(streamedMontantActuel)} / ${NumberFormat.decimalPattern('fr').format(montantCible)} FCFA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                      onPressed: () {
                        _showDeleteDialog(doc.id, context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  color: textColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          categorie,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Créé le ${dateFormat.format(dateCreation)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Échéance: ${dateFormat.format(dateLimite)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String objectifId, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer l'objectif"),
          content: const Text("Voulez-vous vraiment supprimer cet objectif d'épargne ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Supprimer"),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _firestoreService.deleteObjectifEpargne(objectifId);
                  setState(() {
                    _notificationShown.remove(objectifId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Objectif d'épargne supprimé")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la suppression: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}