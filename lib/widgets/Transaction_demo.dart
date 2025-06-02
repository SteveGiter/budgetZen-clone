import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors/app_colors.dart';
import '../services/firebase/firestore.dart';

class MoneyTransferPage extends StatefulWidget {
  const MoneyTransferPage({super.key});

  @override
  State<MoneyTransferPage> createState() => _MoneyTransferPageState();
}

class _MoneyTransferPageState extends State<MoneyTransferPage> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCountryCode = '+237';
  String? _selectedCategory;

  final Map<String, String> _countryCodes = {
    '+237': '🇨🇲 Cameroun',
    '+242': '🇨🇬 Congo',
    '+241': '🇬🇦 Gabon',
    '+235': '🇹🇩 Tchad',
    '+33': '🇫🇷 France',
    '+1': '🇺🇸 USA',
    '+44': '🇬🇧 UK',
    '+49': '🇩🇪 Allemagne',
  };

  final List<Map<String, String>> _transactionCategories = [
    {'value': 'Personnel', 'label': '💼 Personnel'},
    {'value': 'Affaires', 'label': '🏢 Affaires'},
    {'value': 'Cadeau', 'label': '🎁 Cadeau'},
    {'value': 'Éducation', 'label': '📚 Éducation'},
    {'value': 'Santé', 'label': '🏥 Santé'},
    {'value': 'Famille', 'label': '👨‍👩‍👧‍👦 Famille'},
    {'value': 'Nourriture', 'label': '🍔 Nourriture'},
    {'value': 'Transport', 'label': '🚗 Transport'},
    {'value': 'Loisirs', 'label': '🎭 Loisirs'},
    {'value': 'Factures', 'label': '💡 Factures'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert d\'argent'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header avec illustration
            _buildHeaderSection(isDarkMode, screenWidth),
            const SizedBox(height: 30),
            // Formulaire de transfert
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: isDarkMode ? AppColors.darkCardColor : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPhoneField(isDarkMode),
                    const SizedBox(height: 20),
                    _buildAmountField(isDarkMode),
                    const SizedBox(height: 20),
                    _buildCategoryDropdown(isDarkMode),
                    const SizedBox(height: 30),
                    _buildTransferButton(isDarkMode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode, double screenWidth) {
    return Column(
      children: [
        // Make sure this path matches where you placed the file
        Image.asset(
          'assets/orange_money_logo.png', // or your actual path
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.money, size: 80); // Fallback widget if image fails to load
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Transfert Orange Money',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.orange[800],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Envoyez de l\'argent en toute sécurité',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro du bénéficiaire',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                items: _countryCodes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _recipientController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '6X XX XX XX',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  prefixIcon: Icon(
                    Icons.phone_android,
                    color: isDarkMode ? Colors.orange[200] : Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant à transférer (FCFA)',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            prefixIcon: Icon(
              Icons.money,
              color: isDarkMode ? Colors.orange[200] : Colors.orange,
            ),
            suffixText: 'FCFA',
            suffixStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie de transaction',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          ),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          hint: Text(
            'Sélectionnez une catégorie',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          items: _transactionCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category['value'],
              child: Text(category['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTransferButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        child: const Text(
          'TRANSFÉRER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _handleTransfer() async {
    final phoneNumber = '$_selectedCountryCode ${_recipientController.text.trim()}';
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText.replaceAll(RegExp(r'[^0-9.]'), ''));
    final category = _selectedCategory;

    // Validation des champs obligatoires
    if (_recipientController.text.isEmpty) {
      _showError('Veuillez entrer un numéro de téléphone');
      return;
    }

    if (!RegExp(r'^[0-9]{8,15}$').hasMatch(_recipientController.text)) {
      _showError('Format de numéro invalide (8-15 chiffres)');
      return;
    }

    if (amount == null || amount <= 0) {
      _showError('Montant invalide (doit être > 0)');
      return;
    }

    if (category == null) {
      _showError('Veuillez sélectionner une catégorie');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('Session expirée, veuillez vous reconnecter');
      return;
    }

    try {
      // Vérification numéro expéditeur
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(currentUser.uid)
          .get();

      final senderPhone = currentUserDoc.data()?['numeroTelephone'] as String?;
      if (senderPhone?.isEmpty ?? true) {
        _showError('Veuillez enregistrer votre numéro dans votre profil');
        return;
      }

      // Recherche bénéficiaire
      final querySnapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('numeroTelephone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.size == 0) {
        _showError('Aucun compte associé à $phoneNumber');
        return;
      }

      final recipient = querySnapshot.docs.first;
      final recipientUid = recipient.id;

      // Validation logique métier
      if (recipientUid == currentUser.uid) {
        _showError('Auto-transfert impossible');
        return;
      }

      final senderBudget = await _getBudget(currentUser.uid);
      final recipientBudget = await _getBudget(recipientUid);

      if (senderBudget == null || recipientBudget == null) {
        _showError('Problème de configuration des comptes');
        return;
      }

      // Vérification du budget
      if (amount > senderBudget) {
        _showError('Solde insuffisant (${senderBudget.toStringAsFixed(2)} FCFA)');
        return;
      }

      // Vérification supplémentaire : budget ne doit pas devenir négatif
      if ((senderBudget - amount) < 0) {
        _showError('Cette opération rendrait votre budget négatif');
        return;
      }

      // Exécution transaction sécurisée
      await _executeTransaction(
        senderId: currentUser.uid,
        recipientId: recipientUid,
        amount: amount,
        category: category,
      );

      // Réinitialisation & feedback
      _resetForm();
      _showSuccess('Transfert de ${amount.toStringAsFixed(2)} FCFA effectué !');

    } on FirebaseException catch (e) {
      _showError('Erreur réseau: ${e.code}');
    } on StateError catch (_) {
      _showError('Données corrompues, veuillez réessayer');
    } catch (e) {
      _showError('Erreur inattendue');
      print('Erreur détaillée: $e');
    }
  }


  Future<double?> _getBudget(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .get();

      return (doc.data()?['budgetActuel'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<void> _executeTransaction({
    required String senderId,
    required String recipientId,
    required double amount,
    required String category,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final senderRef = FirebaseFirestore.instance.collection('budgets').doc(senderId);
    final recipientRef = FirebaseFirestore.instance.collection('budgets').doc(recipientId);

    // Mettre à jour les budgets
    batch.update(senderRef, {'budgetActuel': FieldValue.increment(-amount)});
    batch.update(recipientRef, {'budgetActuel': FieldValue.increment(amount)});

    // Ajouter une dépense pour l'expéditeur
    await FirestoreService().addDepense(
      userId: senderId,
      montant: amount,
      categorie: category,
      description: 'Transfert à $recipientId',
    );

    // Ajouter un revenu pour le destinataire
    await FirestoreService().addRevenu(
      userId: recipientId,
      montant: amount,
      categorie: category,
      description: 'Transfert reçu de $senderId',
    );

    await batch.commit();

    await FirestoreService().saveTransaction(
      expediteurId: senderId,
      destinataireId: recipientId,
      montant: amount,
      typeTransaction: 'transfert',
      categorie: category,
    );
  }

  void _resetForm() {
    _recipientController.clear();
    _amountController.clear();
    setState(() => _selectedCategory = null);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(message)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(message)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
