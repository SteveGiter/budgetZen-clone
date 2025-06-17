import 'package:flutter/material.dart';
import '../../colors/app_colors.dart';
import '../../widgets/ForAdmin/admin_bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:budget_zen/services/firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUsersPage extends StatefulWidget {
  const AddUsersPage({super.key});

  @override
  State<AddUsersPage> createState() => _AddUsersPageState();
}

class _AddUsersPageState extends State<AddUsersPage> {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _nomPrenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _numeroTelephoneController = TextEditingController();
  String _role = 'utilisateur';
  String _provider = 'manual';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedCountryCode = '+237'; // Code de pays par défaut

  final List<String> _roleOptions = ['utilisateur', 'administrateur'];
  final List<String> _providerOptions = ['manual', 'google'];

  // Liste des codes de pays avec leurs drapeaux
  static const Map<String, String> _countryCodes = {
    '+237': 'Cameroun 🇨🇲',
    '+242': 'Congo 🇨🇬',
    '+241': 'Gabon 🇬🇦',
    '+235': 'Tchad �td',
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

  // Validateur pour le nom et prénom
  String? _nomPrenomValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un nom et prénom';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    if (trimmedValue.length > 50) {
      return 'Le nom ne peut excéder 50 caractères';
    }

    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-]+$').hasMatch(trimmedValue)) {
      return 'Seuls les lettres, espaces et tirets sont autorisés';
    }

    if (RegExp(r'[\-\s]{2,}').hasMatch(trimmedValue)) {
      return 'Évitez plusieurs espaces ou tirets consécutifs';
    }

    return null;
  }

  // Validateur pour l'email
  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un email';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 5) {
      return 'Email trop court';
    }

    if (trimmedValue.length > 320) {
      return 'Email trop long (max 320 caractères)';
    }

    if (RegExp(r'^[^a-zA-Z0-9]').hasMatch(trimmedValue)) {
      return 'L\'email ne peut pas commencer par un caractère spécial';
    }

    final parts = trimmedValue.split('@');
    if (parts.length != 2) {
      return 'Format d\'email invalide (manque @ ou trop de @)';
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.isEmpty) return 'La partie avant le @ est vide';
    if (domainPart.isEmpty) return 'La partie après le @ est vide';
    if (!domainPart.contains('.')) return 'Le domaine doit contenir un point';
    if (domainPart.startsWith('.') || domainPart.endsWith('.')) {
      return 'Le domaine ne peut pas commencer ou finir par un point';
    }
    if (trimmedValue.contains('..')) {
      return 'L\'email ne peut pas contenir deux points consécutifs';
    }

    final tld = domainPart.split('.').last;
    if (tld.length < 2) {
      return 'L\'extension de domaine doit faire au moins 2 caractères';
    }

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Format d\'email invalide';
    }

    return null;
  }

  // Validateur pour le mot de passe
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }

    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }

    if (value.length > 128) {
      return 'Maximum 128 caractères';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '1 majuscule minimum';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '1 minuscule minimum';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '1 chiffre minimum';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '1 caractère spécial minimum';
    }

    if (value.contains(' ')) {
      return 'Pas d\'espaces autorisés';
    }

    if (RegExp(r'(123|abc|password|azerty|qwerty)').hasMatch(value.toLowerCase())) {
      return 'Mot de passe trop simple';
    }

    if (RegExp(r'(.)\1{3,}').hasMatch(value)) {
      return 'Trop de répétitions';
    }

    return null;
  }

  // Validateur pour le téléphone
  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Champ optionnel
    }

    final phone = value.trim();

    if (!RegExp(r'^[0-9\s\-]{8,15}$').hasMatch(phone)) {
      return 'Format invalide (ex: 6XX XXX XXX)';
    }

    final digits = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length < 8 || digits.length > 15) {
      return 'Doit contenir 8 à 15 chiffres';
    }

    return null;
  }

  // Formater le numéro de téléphone avec le code de pays
  String _formatPhoneNumber(String countryCode, String number) {
    if (number.isEmpty) return '';
    return '$countryCode $number';
  }

  @override
  void dispose() {
    _nomPrenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _numeroTelephoneController.dispose();
    super.dispose();
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
                  const SnackBar(content: Text('Veuillez entrer votre mot de passe.')),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Vérifier si l'utilisateur connecté est un administrateur
        final adminUser = _auth.currentUser;
        if (adminUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun administrateur connecté.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final userDoc = await _firestore.firestore
            .collection('utilisateurs')
            .doc(adminUser.uid)
            .get();
        if (!userDoc.exists || userDoc.data()?['role'] != 'administrateur') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seuls les administrateurs peuvent ajouter des utilisateurs.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Demander le mot de passe de l'administrateur
        final adminPassword = await _showPasswordDialog('Veuillez entrer votre mot de passe d\'administrateur.');
        if (adminPassword == null || adminPassword.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Vérifier si le numéro de téléphone est unique (si fourni)
        final phoneNumber = _numeroTelephoneController.text.trim();
        if (phoneNumber.isNotEmpty) {
          final fullPhoneNumber = _formatPhoneNumber(_selectedCountryCode, phoneNumber);
          final isUnique = await _firestore.isPhoneNumberUnique(fullPhoneNumber, _provider, '');
          if (!isUnique) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ce numéro de téléphone est déjà utilisé.')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // Créer le nouvel utilisateur
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final newUser = userCredential.user;

        if (newUser == null) {
          throw Exception('Échec de la création de l\'utilisateur dans l\'authentification');
        }

        // Créer ou mettre à jour le profil de l'utilisateur dans Firestore
        await _firestore.createOrUpdateUserProfile(
          uid: newUser.uid,
          nomPrenom: _nomPrenomController.text.trim(),
          email: _emailController.text.trim(),
          numeroTelephone: phoneNumber.isNotEmpty ? _formatPhoneNumber(_selectedCountryCode, phoneNumber) : null,
          role: _role,
          provider: _provider,
        );

        // Restaurer la session de l'administrateur
        await _auth.signInWithEmailAndPassword(
          email: adminUser.email!,
          password: adminPassword,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur ajouté avec succès')),
        );

        // Réinitialiser le formulaire
        _nomPrenomController.clear();
        _emailController.clear();
        _passwordController.clear();
        _numeroTelephoneController.clear();
        setState(() {
          _role = 'utilisateur';
          _provider = 'manual';
          _selectedCountryCode = '+237';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'utilisateur : $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      appBar: CustomAppBar(
        title: 'Ajouter des Utilisateurs',
        showBackArrow: false,
        showDarkModeButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvel Utilisateur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomPrenomController,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : null,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.person,
                    size: isSmallScreen ? 20 : null,
                    color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                  labelText: 'Nom et Prénom',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : null,
                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                ),
                validator: _nomPrenomValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : null,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.email,
                    size: isSmallScreen ? 20 : null,
                    color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : null,
                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : null,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.lock,
                    size: isSmallScreen ? 20 : null,
                    color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : null,
                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: isSmallScreen ? 20 : null,
                      color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                ),
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro de téléphone (optionnel)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                          borderRadius: BorderRadius.circular(10),
                          color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          underline: const SizedBox(),
                          items: _countryCodes.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                '${entry.key} ${entry.value}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : null,
                                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                ),
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
                        child: TextFormField(
                          controller: _numeroTelephoneController,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : null,
                            color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.phone,
                              size: isSmallScreen ? 20 : null,
                              color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                            ),
                            labelText: 'Numéro',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 14 : null,
                              color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                            contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _phoneValidator,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : null,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.admin_panel_settings,
                    size: isSmallScreen ? 20 : null,
                    color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                  labelText: 'Rôle',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : null,
                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                ),
                items: _roleOptions.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _role = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un rôle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _provider,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : null,
                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.security,
                    size: isSmallScreen ? 20 : null,
                    color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                  labelText: 'Fournisseur',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : null,
                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                  contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                ),
                items: _providerOptions.map((provider) {
                  return DropdownMenuItem(
                    value: provider,
                    child: Text(provider.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _provider = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un fournisseur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppColors.darkButtonColor : AppColors.buttonColor,
                    foregroundColor: isDarkMode ? AppColors.darkButtonTextColor : AppColors.buttonTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: isDarkMode ? AppColors.darkButtonTextColor : AppColors.buttonTextColor)
                      : const Text(
                    'Ajouter l\'utilisateur',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index != 1) {
            final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}