import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../colors/app_colors.dart';
import '../../services/firebase/auth.dart';
import '../../services/firebase/firestore.dart';
import '../../utils/logout_utils.dart';
import '../../widgets/ForAdmin/admin_bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

/// Page to display and manage the current administrator's profile.
class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final Auth _authService = Auth();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables for editable fields
  bool _isEditingPassword = false;
  bool _isObscuringPassword = true;
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  User? _currentUser;
  String _selectedCountryCode = '+237';
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  double _currentBudget = 0.0;
  bool _isLoading = true;
  bool _isAdmin = false;

  // Country codes with flags
  static const Map<String, String> _countryCodes = {
    '+237': 'Cameroun 🇨🇴',
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

  /// Initializes user data and checks admin status.
  void _initializeUserData() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      debugPrint('Utilisateur connecté : ${_currentUser!.uid}');
      _checkAdminStatus();
    } else {
      debugPrint('Aucun utilisateur connecté.');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Aucun utilisateur connecté.');
    }
  }

  /// Checks if the current user is an admin and sets up data streams.
  Future<void> _checkAdminStatus() async {
    try {
      final userDoc = await _firestoreService.firestore
          .collection('utilisateurs')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        if (data?['role'] == 'administrateur') {
          setState(() => _isAdmin = true);
          _setupUserStreams();
          _loadInitialUserData();
        } else {
          setState(() {
            _isAdmin = false;
            _isLoading = false;
          });
          _showErrorSnackBar('Accès réservé aux administrateurs.');
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Utilisateur non trouvé.');
      }
    } catch (e) {
      _handleError('Erreur lors de la vérification du statut admin: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Sets up streams to listen for user data updates.
  void _setupUserStreams() {
    final uid = _currentUser!.uid;
    debugPrint('Configuration des streams pour l\'UID : $uid');
    _userSubscription = _firestoreService.firestore
        .collection('budgets')
        .doc(uid)
        .snapshots()
        .listen(_updateBudgetFromSnapshot);

    _userDataSubscription = _firestoreService.firestore
        .collection('utilisateurs')
        .doc(uid)
        .snapshots()
        .listen(_updateControllersFromSnapshot);
  }

  /// Loads initial user data from Firestore.
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
      setState(() => _isLoading = false);
    } catch (e) {
      _handleError('Erreur lors du chargement des données initiales: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Updates budget state from Firestore snapshot.
  void _updateBudgetFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (mounted && data != null) {
      setState(() {
        _currentBudget = (data['budgetActuel'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  /// Updates text controllers from Firestore snapshot.
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

  /// Splits phone number into country code and number.
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

  /// Formats phone number with country code.
  String _formatPhoneNumber(String countryCode, String number) {
    return '$countryCode $number';
  }

  /// Shows an error notification.
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

  /// Shows a success notification.
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

  /// Handles errors by logging and showing a message.
  void _handleError(String message) {
    debugPrint(message);
    _showErrorSnackBar(message);
  }

  /// Updates the user's name in Firestore.
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

  /// Updates the user's phone number in Firestore.
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

  /// Updates the user's password.
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

  /// Shows a dialog to enter the current password.
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil Administrateur',
        showBackArrow: false,
        showDarkModeButton: true,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
          ? Center(
        child: Text(
          'Accès réservé aux administrateurs',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 16),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildPersonalInfoCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => confirmLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) {
            final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  /// Builds the profile avatar with a button to change the photo.
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

  /// Builds the header with the user's name and email.
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Non défini',
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

  /// Builds the card containing personal information.
  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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

  /// Builds the phone number field.
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        _isEditingPhone ? _buildEditablePhoneField() : _buildNonEditablePhoneField(),
      ],
    );
  }

  /// Builds the non-editable phone field.
  Widget _buildNonEditablePhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          Expanded(child: Text(_phoneController.text.isEmpty ? 'Non défini' : _phoneController.text)),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => setState(() => _isEditingPhone = true),
          ),
        ],
      ),
    );
  }

  /// Builds the editable phone field.
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
                decoration: InputDecoration(
                  hintText: '6X XX XX XX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
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

  /// Builds the password field.
  Widget _buildPasswordField() {
    final isGoogleUser = _currentUser?.providerData?.any((userInfo) => userInfo.providerId == 'google.com') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        _isEditingPassword ? _buildEditablePasswordField() : _buildNonEditablePasswordField(isGoogleUser),
      ],
    );
  }

  /// Builds the non-editable password field.
  Widget _buildNonEditablePasswordField(bool isGoogleUser) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              color: Colors.grey[600],
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

  /// Builds the editable password field.
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscuringPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
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

  /// Builds the current budget field.
  Widget _buildBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget actuel',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_currentBudget.toStringAsFixed(2)} FCFA',
                  style: TextStyle(
                    color: AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a generic editable field.
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        if (!isEditing)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondaryTextColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(controller.text.isEmpty ? 'Non défini' : controller.text),
                ),
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
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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

