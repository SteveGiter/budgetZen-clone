import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/firebase/firestore.dart';
import '../colors/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime? _dueDate;
  String _selectedCategory = 'Prévisionnel';
  bool _isLoading = false;

  // Limite à 50 caractères pour le nom de l'objectif
  static const int maxGoalNameLength = 50;

  final List<Map<String, dynamic>> categories = [
    {'value': 'Prévisionnel', 'label': '📅 Prévisionnel', 'color': Colors.blue},
    {'value': 'Projet', 'label': '🎯 Projet', 'color': Colors.green},
    {'value': 'Urgence', 'label': '🚨 Urgence', 'color': Colors.red},
    {'value': 'Retraite', 'label': '👴 Retraite', 'color': Colors.purple},
    {'value': 'Investissement', 'label': '📈 Investissement', 'color': Colors.orange},
    {'value': 'Autre', 'label': '❓ Autre', 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Veuillez sélectionner une date limite')),
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
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestoreService.createObjectifEpargne(
        userId: user.uid,
        nomObjectif: _nameController.text,
        montantCible: double.parse(_targetAmountController.text),
        dateLimite: Timestamp.fromDate(_dueDate!),
        categorie: _selectedCategory,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Objectif enregistré avec succès!')),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Erreur: ${e.toString()}')),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    bool showCounter = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: showCounter ? null : '',
        prefixIcon: icon != null
            ? Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        isDense: true, // Optimisation pour Android
      ),
      validator: validator,
      style: const TextStyle(fontSize: 14), // Taille de police adaptée
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        return ChoiceChip(
          label: Text(category['label']),
          selected: _selectedCategory == category['value'],
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = category['value']);
            }
          },
          selectedColor: category['color'].withOpacity(0.2),
          labelStyle: TextStyle(
            color: _selectedCategory == category['value']
                ? category['color']
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: _selectedCategory == category['value']
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 13, // Taille réduite pour Android
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _selectedCategory == category['value']
                  ? category['color']
                  : Colors.grey.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _dueDate == null
                    ? 'Sélectionner une date'
                    : DateFormat('dd MMMM yyyy').format(_dueDate!),
                style: const TextStyle(fontSize: 14), // Taille adaptée
              ),
            ),
            if (_dueDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20), // Taille réduite
                onPressed: () => setState(() => _dueDate = null),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nouvel objectif d\'épargne',
        showBackArrow: true,
        showDarkModeButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Détails de l\'objectif',
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom de l\'objectif',
                    hint: 'Ex: Achat voiture ou maison',
                    icon: Icons.flag,
                    maxLength: maxGoalNameLength,
                    showCounter: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ce champ est requis';
                      if (value!.length > maxGoalNameLength) {
                        return 'Maximum $maxGoalNameLength caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _targetAmountController,
                    label: 'Montant cible',
                    hint: '0 FCFA',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ce champ est requis';
                      if (double.tryParse(value!) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Catégorie',
                children: [
                  _buildCategorySelector(context),
                ],
              ),
              _buildSectionCard(
                title: 'Date limite',
                children: [
                  _buildDateSelector(context),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'ENREGISTRER L\'OBJECTIF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}