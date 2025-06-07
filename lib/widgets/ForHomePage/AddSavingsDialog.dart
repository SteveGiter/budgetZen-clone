import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase/firestore.dart';

class AddSavingsDialog extends StatefulWidget {
  final Function(double, String, String?, String) onSavingsAdded;
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

  // Constante pour la limite de caractères
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
        setState(() {
          _savingsGoals = goalsSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nomObjectif': data['nomObjectif'] as String,
              'categorie': data['categorie'] as String?,
            };
          }).toList();
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
            content: Text('Erreur lors du chargement des objectifs: $e'),
            backgroundColor: Colors.red,
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
                    : _savingsGoals.map((Map<String, dynamic> goal) {
                  final goalName = goal['nomObjectif'] as String;
                  return DropdownMenuItem<String>(
                    value: goal['id'],
                    child: Tooltip(
                      message: goalName,
                      child: Text(
                        goalName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _savingsGoals.isEmpty
                    ? null
                    : (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGoalId = newValue;
                      _selectedGoalCategory = _savingsGoals
                          .firstWhere((goal) => goal['id'] == newValue)['categorie'];
                    });
                  }
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
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
        if (_savingsGoals.isEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/SavingsGoalsPage');
            },
            child: const Text(
              'Créer un objectif',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ElevatedButton(
          onPressed: _isSubmitting || _savingsGoals.isEmpty
              ? null
              : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isSubmitting = true);
              try {
                final amount = double.parse(_amountController.text);
                final description = _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null;
                if (_selectedGoalCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'L\'objectif sélectionné n\'a pas de catégorie définie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() => _isSubmitting = false);
                  return;
                }
                await widget.onSavingsAdded(
                  amount,
                  _selectedGoalCategory!,
                  description,
                  _selectedGoalId!,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'ajout: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isSubmitting = false);
                }
              }
            }
          },
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}