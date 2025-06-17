import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../services/firebase/firestore.dart';

class BudgetValidator {
  static Future<bool> validateBudget(
      BuildContext context, FirestoreService firestoreService, String userId, double amount, String? selectedGoalId, List<Map<String, dynamic>> savingsGoals) async {
    // Vérifier si un objectif est sélectionné
    if (selectedGoalId == null) {
      _showSnackBar(context, 'Veuillez sélectionner un objectif d\'épargne.');
      return false;
    }

    // Vérifier si l'objectif existe dans la liste
    final selectedGoal = savingsGoals.firstWhereOrNull((goal) => goal['id'] == selectedGoalId);
    if (selectedGoal == null) {
      _showSnackBar(context, 'L\'objectif sélectionné est invalide ou n\'existe plus.');
      return false;
    }

    // Récupérer le budget actuel
    final budgetDoc = await firestoreService.firestore.collection('budgets').doc(userId).get();

    if (!budgetDoc.exists) {
      _showSnackBar(context, 'Votre budget n\'existe pas. Veuillez vérifier votre compte.');
      return false;
    }

    final currentBudget = (budgetDoc.data()?['budgetActuel'] as num?)?.toDouble() ?? 0.0;

    // Vérifier si le budget est suffisant
    if (amount > currentBudget) {
      _showSnackBar(context, 'Votre budget est insuffisant pour ajouter cette épargne.');
      return false;
    }

    // Vérifier si le montant dépasse le restant pour l'objectif
    final montantRestant = selectedGoal['montantCible'] - selectedGoal['montantActuel'];
    if (amount > montantRestant) {
      _showSnackBar(context, 'Le montant dépasse le restant pour cet objectif (${montantRestant.toStringAsFixed(2)} FCFA).');
      return false;
    }

    return true;
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(message)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}