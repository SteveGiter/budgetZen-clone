import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors/app_colors.dart';
import '../services/firebase/auth.dart';
import '../services/firebase/firestore.dart';
import '../utils/logout_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Auth _auth = Auth();
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEditingPassword = false;
  bool _obscurePassword = true;
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  User? currentUser;
  String _selectedCountryCode = '+237';
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  double _currentBudget = 0.0;

  final Map<String, String> _countryCodes = {
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
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupUserStream();
      _loadInitialData();
    }
  }

  void _updateBudgetFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        _currentBudget = (data['budgetActuel'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _setupUserStream() {
    _userSubscription = _firestore.firestore
        .collection('budgets')
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        _updateBudgetFromSnapshot(snapshot);
      }
    });

    _userDataSubscription = _firestore.firestore
        .collection('utilisateurs')
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        _updateControllersFromSnapshot(snapshot);
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final userDoc = await _firestore.firestore
          .collection('utilisateurs')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        _updateControllersFromSnapshot(userDoc);
      }

      final budgetDoc = await _firestore.firestore
          .collection('budgets')
          .doc(currentUser!.uid)
          .get();

      if (budgetDoc.exists && mounted) {
        _updateBudgetFromSnapshot(budgetDoc);
      }
    } catch (e) {
      debugPrint('Erreur chargement initial: $e');
    }
  }


  void _updateControllersFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    final phone = data['numeroTelephone'] ?? '';
    final phoneParts = _splitPhoneNumber(phone);

    if (mounted) {
      setState(() {
        _emailController.text = currentUser?.email ?? '';
        _nameController.text = data['nomPrenom'] ?? '';
        _selectedCountryCode = phoneParts['countryCode'] ?? '+237';
        _phoneController.text = phoneParts['number'] ?? '';
        _passwordController.text = '********';
      });
    }
  }

  Map<String, String> _splitPhoneNumber(String fullPhone) {
    if (fullPhone.isEmpty) return {'countryCode': '+237', 'number': ''};
    final spaceIndex = fullPhone.indexOf(' ');
    if (spaceIndex == -1) return {'countryCode': '+237', 'number': fullPhone};
    return {
      'countryCode': fullPhone.substring(0, spaceIndex),
      'number': fullPhone.substring(spaceIndex + 1),
    };
  }

  String _formatPhoneNumber(String countryCode, String number) {
    return '$countryCode $number';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(message),
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
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(message),
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
  }

  Future<void> _updateName() async {
    if (currentUser == null || _nameController.text.isEmpty) {
      _showErrorSnackBar('Le nom ne peut pas être vide');
      return;
    }

    try {
      await _firestore.updateUser(currentUser!.uid, {
        'nomPrenom': _nameController.text, // Utilisation de updateUser
      });
      setState(() => _isEditingName = false);
      _showSuccessSnackBar('Nom mis à jour avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour du nom: ${e.toString()}');
    }
  }

  Future<void> _updatePhone() async {
    if (currentUser == null) return;

    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar('Le numéro de téléphone ne peut pas être vide');
      return;
    }

    final fullPhoneNumber = _formatPhoneNumber(_selectedCountryCode, _phoneController.text);
    final isGoogleUser = currentUser!.providerData.any((u) => u.providerId == 'google.com');

    try {
      // Utilisation de la nouvelle méthode de vérification
      final isUnique = await _firestore.isPhoneNumberUnique(
        fullPhoneNumber,
        isGoogleUser ? 'google' : null,
        currentUser!.uid,
      );

      if (!isUnique) {
        _showErrorSnackBar(isGoogleUser
            ? 'Numéro déjà utilisé par un autre compte Google'
            : 'Numéro déjà attribué');
        return;
      }

      await _firestore.updateUser(currentUser!.uid, {
        'numeroTelephone': fullPhoneNumber,
      });
      setState(() => _isEditingPhone = false);
      _showSuccessSnackBar('Téléphone mis à jour avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur de vérification: ${e.toString()}');
    }
  }

  Future<void> _updatePassword() async {
    if (currentUser == null) return;

    final isGoogleUser = currentUser!.providerData.any((userInfo) => userInfo.providerId == 'google.com');
    if (isGoogleUser) {
      _showErrorSnackBar('Les utilisateurs Google ne peuvent pas modifier leur mot de passe');
      return;
    }

    if (_passwordController.text.isEmpty || _passwordController.text == '********') {
      _showErrorSnackBar('Veuillez entrer un nouveau mot de passe');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    final currentPassword = await _showPasswordDialog("Veuillez entrer votre mot de passe actuel");
    if (currentPassword == null || currentPassword.isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(_passwordController.text);

      setState(() {
        _isEditingPassword = false;
        _obscurePassword = true;
        _passwordController.text = '********';
      });
      _showSuccessSnackBar('Mot de passe mis à jour avec succès');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Erreur lors de la mise à jour';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Veuillez vous reconnecter pour modifier votre mot de passe';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Le mot de passe est trop faible';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Mot de passe actuel incorrect';
      } else {
        errorMessage = 'Erreur: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Erreur inattendue: ${e.toString()}');
    }
  }

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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer votre mot de passe'),
                    backgroundColor: Colors.red,
                  ),
                );
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
      appBar: CustomAppBar(
        title: 'Profil',
        showBackArrow: true,
        backDestination: '/LoginPage',
        showDarkModeButton: true,
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.transparent, // Pas de fond externe
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
                              backgroundImage: currentUser?.photoURL != null
                                  ? NetworkImage(currentUser!.photoURL!)
                                  : null,
                              child: currentUser?.photoURL == null
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
                              onPressed: () {
                                // Logique pour changer la photo de profil
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fonctionnalité de photo à venir')),
                                );
                              },
                              icon: const Icon(Icons.camera_alt, color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Non renseigné',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.email ?? '',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations personnelles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                            /*//J'ai retiré le champs
                            const SizedBox(height: 16),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email_outlined, color: AppColors.secondaryTextColor),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(_emailController.text)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            */
                            const SizedBox(height: 16),
                            _buildPhoneField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget actuel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey,
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
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade900
                                        : Colors.white,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        if (!_isEditingPhone)
          Container(
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
          )
        else
          Column(
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
                    onChanged: (value) {
                      setState(() {
                        _selectedCountryCode = value!;
                      });
                    },
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
                        border: const OutlineInputBorder(),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Enregistrer', style: TextStyle(color: AppColors.buttonTextColor)),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
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
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        border: const OutlineInputBorder(),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Enregistrer', style: TextStyle(color: AppColors.buttonTextColor)),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final isGoogleUser = currentUser?.providerData
        .any((userInfo) => userInfo.providerId == 'google.com') ?? false;

    void handleEditPassword() {
      if (isGoogleUser) {
        _showErrorSnackBar('Les utilisateurs Google ne peuvent pas modifier leur mot de passe');
      } else {
        setState(() {
          _isEditingPassword = true;
          if (_passwordController.text == '********') {
            _passwordController.clear();
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        if (!_isEditingPassword)
          Container(
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
                      color: _passwordController.text == '********'
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: handleEditPassword,
                ),
                IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: () {
                    if (_passwordController.text != '********') {
                      setState(() => _obscurePassword = !_obscurePassword);
                    }
                  },
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nouveau mot de passe (min. 6 caractères)',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        _obscurePassword = true;
                        _passwordController.text = '********';
                      });
                    },
                    child: const Text('Annuler', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
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
    _userDataSubscription?.cancel(); // Nouveau
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}