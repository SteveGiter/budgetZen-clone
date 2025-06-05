import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../services/firebase/auth.dart';
import '../services/firebase/firestore.dart';
import '../widgets/custom_app_bar.dart';

/// Page de gestion du profil utilisateur.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Auth _authService = Auth();
  final FirestoreService _firestoreService = FirestoreService();

  // Contrôleurs pour les champs de saisie
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // États des champs éditables
  bool _isEditingPassword = false;
  bool _isObscuringPassword = true;
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  User? _currentUser;
  String _selectedCountryCode = '+237';
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  double _currentBudget = 0.0;

  // Liste des codes de pays avec leurs drapeaux
  static const Map<String, String> _countryCodes = {
    '+237': 'Cameroun 🇨🇲',
    '+242': 'Congo 🇨🇬',
    '+241': 'Gabon 🇬🇦',
    '+235': 'Tchad 🇹🇩',
    '+33': 'France 🇫🇷',
    '+1': 'USA 🇺🇸',
    '+44': 'UK 🇬🇧',
    '+49': 'Germany 🇩🇪',
    '+32': 'Belgium 🇧🇪',
    '+41': 'Switzerland 🇨🇭',
    '+212': 'Morocco 🇲🇦',
    '+221': 'Senegal 🇸🇳',
    '+225': 'Ivory Coast 🇨🇮',
    '+229': 'Benin 🇧🇯',
  };

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  /// Initialise les données utilisateur et configure les streams.
  void _initializeUserData() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _setupUserStreams();
      _loadInitialUserData();
    }
  }

  /// Configure les streams pour écouter les mises à jour des données utilisateur.
  void _setupUserStreams() {
    _userSubscription = _firestoreService.firestore
        .collection('budgets')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen(_updateBudgetFromSnapshot);

    _userDataSubscription = _firestoreService.firestore
        .collection('utilisateurs')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen(_updateControllersFromSnapshot);
  }

  /// Charge les données initiales de l'utilisateur depuis Firestore.
  Future<void> _loadInitialUserData() async {
    try {
      final userDoc = await _firestoreService.firestore
          .collection('utilisateurs')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        _updateControllersFromSnapshot(userDoc);
      }

      final budgetDoc = await _firestoreService.firestore
          .collection('budgets')
          .doc(_currentUser!.uid)
          .get();

      if (budgetDoc.exists && mounted) {
        _updateBudgetFromSnapshot(budgetDoc);
      }
    } catch (e) {
      _handleError('Erreur lors du chargement des données initiales: $e');
    }
  }

  /// Met à jour l'état du budget à partir d'un snapshot Firestore.
  void _updateBudgetFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (mounted && data != null) {
      setState(() {
        _currentBudget = (data['budgetActuel'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  /// Met à jour les contrôleurs de texte à partir d'un snapshot Firestore.
  void _updateControllersFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final phone = data['numeroTelephone'] ?? '';
    final phoneParts = _splitPhoneNumber(phone);

    if (mounted) {
      setState(() {
        _emailController.text = _currentUser?.email ?? '';
        _nameController.text = data['nomPrenom'] ?? '';
        _selectedCountryCode = phoneParts['countryCode'] ?? '+237';
        _phoneController.text = phoneParts['number'] ?? '';
        _passwordController.text = '********';
      });
    }
  }

  /// Sépare le numéro de téléphone en code de pays et numéro.
  Map<String, String> _splitPhoneNumber(String fullPhone) {
    if (fullPhone.isEmpty) {
      return {'countryCode': '+237', 'number': ''};
    }
    final spaceIndex = fullPhone.indexOf(' ');
    if (spaceIndex == -1) {
      return {'countryCode': '+237', 'number': fullPhone};
    }
    return {
      'countryCode': fullPhone.substring(0, spaceIndex),
      'number': fullPhone.substring(spaceIndex + 1),
    };
  }

  /// Formate le numéro de téléphone avec le code de pays.
  String _formatPhoneNumber(String countryCode, String number) {
    return '$countryCode $number';
  }

  /// Affiche une notification d'erreur.
  void _showErrorSnackBar(String message) {
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
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Affiche une notification de succès.
  void _showSuccessSnackBar(String message) {
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
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Gère les erreurs en affichant un message et en journalisant.
  void _handleError(String message) {
    debugPrint(message);
    _showErrorSnackBar(message);
  }

  /// Met à jour le nom de l'utilisateur dans Firestore.
  Future<void> _updateName() async {
    if (_currentUser == null || _nameController.text.isEmpty) {
      _showErrorSnackBar('Le nom ne peut pas être vide.');
      return;
    }

    try {
      await _firestoreService.updateUser(_currentUser!.uid, {
        'nomPrenom': _nameController.text,
      });
      setState(() => _isEditingName = false);
      _showSuccessSnackBar('Nom mis à jour avec succès.');
    } catch (e) {
      _handleError('Erreur lors de la mise à jour du nom: $e');
    }
  }

  /// Met à jour le numéro de téléphone dans Firestore.
  Future<void> _updatePhone() async {
    if (_currentUser == null || _phoneController.text.isEmpty) {
      _showErrorSnackBar('Le numéro de téléphone ne peut pas être vide.');
      return;
    }

    final fullPhoneNumber = _formatPhoneNumber(_selectedCountryCode, _phoneController.text);
    final isGoogleUser = _currentUser!.providerData.any((u) => u.providerId == 'google.com');

    try {
      final isUnique = await _firestoreService.isPhoneNumberUnique(
        fullPhoneNumber,
        isGoogleUser ? 'google' : null,
        _currentUser!.uid,
      );

      if (!isUnique) {
        _showErrorSnackBar(isGoogleUser
            ? 'Numéro déjà utilisé par un autre compte Google.'
            : 'Numéro déjà attribué.');
        return;
      }

      await _firestoreService.updateUser(_currentUser!.uid, {
        'numeroTelephone': fullPhoneNumber,
      });
      setState(() => _isEditingPhone = false);
      _showSuccessSnackBar('Numéro de téléphone mis à jour avec succès.');
    } catch (e) {
      _handleError('Erreur lors de la mise à jour du numéro: $e');
    }
  }

  /// Met à jour le mot de passe de l'utilisateur.
  Future<void> _updatePassword() async {
    if (_currentUser == null) return;

    final isGoogleUser = _currentUser!.providerData.any((userInfo) => userInfo.providerId == 'google.com');
    if (isGoogleUser) {
      _showErrorSnackBar('Les utilisateurs Google ne peuvent pas modifier leur mot de passe.');
      return;
    }

    if (_passwordController.text.isEmpty || _passwordController.text == '********') {
      _showErrorSnackBar('Veuillez entrer un nouveau mot de passe.');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    final currentPassword = await _showPasswordDialog('Veuillez entrer votre mot de passe actuel.');
    if (currentPassword == null || currentPassword.isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );

      await _currentUser!.reauthenticateWithCredential(credential);
      await _currentUser!.updatePassword(_passwordController.text);

      setState(() {
        _isEditingPassword = false;
        _isObscuringPassword = true;
        _passwordController.text = '********';
      });
      _showSuccessSnackBar('Mot de passe mis à jour avec succès.');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Veuillez vous reconnecter pour modifier votre mot de passe.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible.';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe actuel incorrect.';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _handleError('Erreur inattendue: $e');
    }
  }

  /// Affiche une boîte de dialogue pour saisir le mot de passe actuel.
  Future<String?> _showPasswordDialog(String message) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                _showErrorSnackBar('Veuillez entrer votre mot de passe.');
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
// In ProfilePage's build method
      appBar: CustomAppBar(
        title: 'Profil',
        showBackArrow: true, // Keep back arrow
        showDarkModeButton: true,
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 16),
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildPersonalInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit l'avatar du profil avec un bouton pour changer la photo.
  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              backgroundImage: _currentUser?.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              child: _currentUser?.photoURL == null
                  ? Icon(Icons.person, size: 60, color: AppColors.primaryColor)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showErrorSnackBar('Fonctionnalité de changement de photo à venir.'),
              icon: const Icon(Icons.camera_alt, color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit l'en-tête avec le nom et l'email de l'utilisateur.
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Non renseigné',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentUser?.email ?? '',
          style: TextStyle(
            color: AppColors.secondaryTextColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Construit la carte contenant les informations personnelles.
  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildEditableField(
              label: 'Nom complet',
              controller: _nameController,
              isEditing: _isEditingName,
              onEdit: () => setState(() => _isEditingName = true),
              onSave: _updateName,
              onCancel: () => setState(() => _isEditingName = false),
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildBudgetField(),
          ],
        ),
      ),
    );
  }

  /// Construit le champ du numéro de téléphone.
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        if (!_isEditingPhone)
          _buildNonEditablePhoneField()
        else
          _buildEditablePhoneField(),
      ],
    );
  }

  /// Construit le champ du numéro de téléphone en mode non éditable.
  Widget _buildNonEditablePhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_outlined, color: AppColors.secondaryTextColor),
          const SizedBox(width: 10),
          Text(_selectedCountryCode),
          const SizedBox(width: 5),
          Expanded(child: Text(_phoneController.text)),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => setState(() => _isEditingPhone = true),
          ),
        ],
      ),
    );
  }

  /// Construit le champ du numéro de téléphone en mode éditable.
  Widget _buildEditablePhoneField() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.phone_outlined, color: AppColors.secondaryTextColor),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _selectedCountryCode,
              items: _countryCodes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text('${entry.key} ${entry.value}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCountryCode = value!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '6X XX XX XX',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _isEditingPhone = false),
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _updatePhone,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              child: const Text('Enregistrer', style: TextStyle(color: AppColors.buttonTextColor)),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le champ du mot de passe.
  Widget _buildPasswordField() {
    final isGoogleUser = _currentUser?.providerData.any((userInfo) => userInfo.providerId == 'google.com') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        if (!_isEditingPassword)
          _buildNonEditablePasswordField(isGoogleUser)
        else
          _buildEditablePasswordField(),
      ],
    );
  }

  /// Construit le champ du mot de passe en mode non éditable.
  Widget _buildNonEditablePasswordField(bool isGoogleUser) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.secondaryTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _passwordController.text,
              style: TextStyle(
                color: _passwordController.text == '********' ? Colors.grey : Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              if (isGoogleUser) {
                _showErrorSnackBar('Les utilisateurs Google ne peuvent pas modifier leur mot de passe.');
              } else {
                setState(() {
                  _isEditingPassword = true;
                  if (_passwordController.text == '********') {
                    _passwordController.clear();
                  }
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isObscuringPassword ? Icons.visibility : Icons.visibility_off,
              size: 20,
            ),
            onPressed: () {
              if (_passwordController.text != '********') {
                setState(() => _isObscuringPassword = !_isObscuringPassword);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Construit le champ du mot de passe en mode éditable.
  Widget _buildEditablePasswordField() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.secondaryTextColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _passwordController,
                obscureText: _isObscuringPassword,
                decoration: InputDecoration(
                  hintText: 'Nouveau mot de passe (min. 6 caractères)',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuringPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _isObscuringPassword = !_isObscuringPassword),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingPassword = false;
                  _isObscuringPassword = true;
                  _passwordController.text = '********';
                });
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              child: const Text('Enregistrer', style: TextStyle(color: AppColors.buttonTextColor)),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le champ du budget actuel.
  Widget _buildBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget actuel',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : AppColors.borderColor,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : AppColors.secondaryTextColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_currentBudget.toStringAsFixed(2)} FCFA',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit un champ éditable générique.
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    TextInputType? keyboardType,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        if (!isEditing)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondaryTextColor),
                const SizedBox(width: 10),
                Expanded(child: Text(controller.text)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Annuler', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                    child: const Text('Enregistrer', style: TextStyle(color: AppColors.buttonTextColor)),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _userDataSubscription?.cancel();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}