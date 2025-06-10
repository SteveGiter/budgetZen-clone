import 'package:flutter/material.dart';
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

  final List<String> _roleOptions = ['utilisateur', 'administrateur'];
  final List<String> _providerOptions = ['manual', 'google'];

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
          final isUnique = await _firestore.isPhoneNumberUnique(phoneNumber, _provider, '');
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
          numeroTelephone: phoneNumber.isNotEmpty ? phoneNumber : null,
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

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ajouter des Utilisateurs',
        showBackArrow: false,
        showDarkModeButton: true,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
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
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomPrenomController,
                decoration: InputDecoration(
                  labelText: 'Nom et Prénom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(Icons.person, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom et prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(Icons.email, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(Icons.lock, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroTelephoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(Icons.phone, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                      return 'Veuillez entrer un numéro de téléphone valide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(
                    Icons.admin_panel_settings,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Fournisseur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  prefixIcon: Icon(Icons.security, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
                    backgroundColor: isDarkMode ? Colors.blueGrey[800] : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Ajouter l\'utilisateur', style: TextStyle(fontSize: 16)),
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