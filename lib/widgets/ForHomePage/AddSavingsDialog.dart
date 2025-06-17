import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase/firestore.dart';
import 'BudgetValidator.dart';
import 'package:collection/collection.dart';

class AddSavingsDialog extends StatefulWidget {
  final Function(double, String, String?, String, List<Map<String, dynamic>>) onSavingsAdded;
  final String userId;
  final FirestoreService firestoreService;

  const AddSavingsDialog({
    super.key,
    required this.onSavingsAdded,
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<AddSavingsDialog> createState() => _AddSavingsDialogState();
}

class _AddSavingsDialogState extends State<AddSavingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGoalId;
  String? _selectedGoalCategory;
  List<Map<String, dynamic>> _savingsGoals = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const int maxDescriptionLength = 50;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goalsSnapshot = await widget.firestoreService.getObjectifsEpargne(widget.userId);
      if (mounted) {
        final currentDate = DateTime.now();
        setState(() {
          _savingsGoals = goalsSnapshot.docs
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nomObjectif': data['nomObjectif'] as String,
              'categorie': data['categorie'] as String?,
              'montantActuel': (data['montantActuel'] as num?)?.toDouble() ?? 0.0,
              'montantCible': (data['montantCible'] as num?)?.toDouble() ?? 0.0,
              'isCompleted': (data['isCompleted'] as bool?) ?? false,
              'dateLimite': data['dateLimite'] as Timestamp?,
            };
          })
              .where((goal) {
            final isCompleted = goal['isCompleted'] as bool;
            final montantActuel = goal['montantActuel'] as double;
            final montantCible = goal['montantCible'] as double;
            final isGoalReached = isCompleted || montantActuel >= montantCible;
            final dateLimite = goal['dateLimite'] as Timestamp?;
            bool isExpired = false;
            if (dateLimite != null) {
              final goalDeadline = dateLimite.toDate();
              isExpired = goalDeadline.isBefore(currentDate);
            }
            return !isGoalReached && !isExpired;
          })
              .toList();

          if (_savingsGoals.isNotEmpty) {
            _selectedGoalId = _savingsGoals[0]['id'];
            _selectedGoalCategory = _savingsGoals[0]['categorie'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des objectifs : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une épargne'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Montant invalide';
                  }
                  if (amount <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Sélection de l'objectif
              DropdownButtonFormField<String>(
                value: _selectedGoalId,
                items: _savingsGoals.isEmpty
                    ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text(
                      'Aucun objectif disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ]
                    : _savingsGoals.map((goal) {
                  return DropdownMenuItem<String>(
                    value: goal['id'],
                    child: Text(goal['nomObjectif']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGoalId = newValue;
                    if (newValue != null) {
                      final selectedGoal = _savingsGoals.firstWhereOrNull((goal) => goal['id'] == newValue);
                      _selectedGoalCategory = selectedGoal?['categorie'];
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Objectif d\'épargne',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) =>
                _savingsGoals.isEmpty || value == null ? 'Veuillez sélectionner un objectif' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              // Champ Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnelle)',
                  prefixIcon: const Icon(Icons.description),
                  counterText: '${_descriptionController.text.length}/$maxDescriptionLength',
                ),
                maxLength: maxDescriptionLength,
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
          onPressed: _isSubmitting || _savingsGoals.isEmpty
              ? null
              : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isSubmitting = true);
              try {
                final amount = double.parse(_amountController.text);

                // Valider le budget en utilisant la classe utilitaire
                final isBudgetValid = await BudgetValidator.validateBudget(
                  context,
                  widget.firestoreService,
                  widget.userId,
                  amount,
                  _selectedGoalId,
                  _savingsGoals,
                );

                if (!isBudgetValid) {
                  setState(() => _isSubmitting = false);
                  return;
                }

                final description = _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null;

                if (_selectedGoalCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('L\'objectif sélectionné n\'a pas de catégorie définie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() => _isSubmitting = false);
                  return;
                }
                print('AddSavingsDialog: _selectedGoalId=$_selectedGoalId, _savingsGoals=$_savingsGoals');
                await widget.onSavingsAdded(
                  amount,
                  _selectedGoalCategory!,
                  description,
                  _selectedGoalId!,
                  _savingsGoals,
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de l\'ajout : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => _isSubmitting = false);
              }
            }
          },
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}