import 'dart:async';
import 'dart:io';

import 'package:budget_zen/services/firebase/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors/app_colors.dart';
import 'Redirection.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final TextEditingController _nomCompletController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Illustration de gestion financière.jpg'),
            fit: BoxFit.cover, // Ajuste l'image pour couvrir tout l'écran
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), // Opacité pour améliorer la lisibilité
              BlendMode.darken,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/logoWithProjectName.png',
                            height: isSmallScreen ? screenWidth * 0.35 : screenWidth * 0.25,
                            width: isSmallScreen ? screenWidth * 0.35 : screenWidth * 0.25,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 30),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: isSmallScreen ? 15 : 30),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode ? Colors.black.withOpacity(0.3) : AppColors.borderColor.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Créez votre compte',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 5 : 10),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 20),
                                  child: Text(
                                    'Commencez votre voyage financier avec nous',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 16,
                                      color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 30),

                                // Bouton Google d'inscription
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _isGoogleLoading
                                        ? null
                                        : () async {
                                      setState(() => _isGoogleLoading = true);
                                      try {
                                        await Auth().signInWithGoogle();
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const RedirectionPage()),
                                          );
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        if (mounted) {
                                          String errorMessage;
                                          switch (e.code) {
                                            case 'account-exists-with-different-credential':
                                              errorMessage = "Un compte existe déjà avec cet email";
                                              break;
                                            case 'invalid-credential':
                                              errorMessage = "Session Google invalide. Veuillez réessayer";
                                              break;
                                            case 'operation-not-allowed':
                                              errorMessage = "Connexion Google désactivée";
                                              break;
                                            case 'user-disabled':
                                              errorMessage = "Ce compte a été désactivé";
                                              break;
                                            case 'network-request-failed':
                                              errorMessage = "Problème de connexion internet";
                                              break;
                                            case 'cancelled':
                                              return; // Ne pas afficher de message si annulé
                                            default:
                                              errorMessage = "Erreur lors de la connexion Google";
                                          }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: Text(errorMessage)),
                                                  IconButton(
                                                    icon: Icon(Icons.close, color: Colors.white),
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                    },
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: AppColors.errorColor,
                                              duration: const Duration(seconds: 3),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: const Text("Erreur inattendue lors de la connexion")),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white),
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                    },
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: AppColors.errorColor,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isGoogleLoading = false);
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(
                                        color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor,
                                      ),
                                      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : Colors.white,
                                    ),
                                    child: _isGoogleLoading
                                        ? SizedBox(
                                      height: isSmallScreen ? 20 : 24,
                                      width: isSmallScreen ? 20 : 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/google_icon.png',
                                          height: isSmallScreen ? 22 : 28,
                                          width: isSmallScreen ? 22 : 28,
                                        ),
                                        SizedBox(width: isSmallScreen ? 8 : 12),
                                        Flexible(
                                          child: Text(
                                            'S\'inscrire avec Google',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 25),

                                // Séparateur OU
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor, thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'Ou',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : null,
                                          color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor, thickness: 1)),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 25),

                                // Champ email
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixIcon: Icon(Icons.email, size: isSmallScreen ? 20 : null, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
                                    labelText: "Email",
                                    labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor),
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
                                      borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? AppColors.darkBackgroundColor : Colors.white,
                                    contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre email';
                                    }

                                    // Supprimer les espaces avant/après
                                    final trimmedValue = value.trim();

                                    // 1. Vérification longueur minimale (a@b.c = 5 caractères minimum)
                                    if (trimmedValue.length < 5) {
                                      return 'L\'email est trop court';
                                    }

                                    // 2. Vérification longueur maximale
                                    if (trimmedValue.length > 320) {
                                      return 'L\'email est trop long (max 320 caractères)';
                                    }

                                    // 3. Ne doit pas commencer par un caractère spécial
                                    if (RegExp(r'^[^a-zA-Z0-9]').hasMatch(trimmedValue)) {
                                      return 'L\'email ne peut pas commencer par un caractère spécial';
                                    }

                                    // 4. Doit contenir un et un seul @
                                    final atCount = trimmedValue.split('@').length - 1;
                                    if (atCount == 0) {
                                      return 'L\'email doit contenir un @';
                                    }
                                    if (atCount > 1) {
                                      return 'L\'email ne peut contenir qu\'un seul @';
                                    }

                                    // Séparation partie locale et domaine
                                    final parts = trimmedValue.split('@');
                                    final localPart = parts[0];
                                    final domainPart = parts[1];

                                    // 5. Vérification partie locale (avant @)
                                    if (localPart.isEmpty) {
                                      return 'La partie avant le @ est vide';
                                    }

                                    // 6. Vérification partie domaine (après @)
                                    if (domainPart.isEmpty) {
                                      return 'La partie après le @ est vide';
                                    }

                                    // 7. Le domaine doit contenir un point
                                    if (!domainPart.contains('.')) {
                                      return 'Le domaine doit contenir un point (ex: exemple.com)';
                                    }

                                    // 8. Le point ne peut pas être en début ou fin de domaine
                                    if (domainPart.startsWith('.') || domainPart.endsWith('.')) {
                                      return 'Le domaine ne peut pas commencer ou finir par un point';
                                    }

                                    // 9. Validation format complet avec regex
                                    final emailRegex = RegExp(
                                        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$'
                                    );

                                    if (!emailRegex.hasMatch(trimmedValue)) {
                                      return 'Format d\'email invalide';
                                    }

                                    // 10. Vérifier les séquences de points invalides (..)
                                    if (trimmedValue.contains('..')) {
                                      return 'L\'email ne peut pas contenir deux points consécutifs';
                                    }

                                    // 11. Vérifier le TLD (dernière partie après le dernier point)
                                    final tld = domainPart.split('.').last;
                                    if (tld.length < 2) {
                                      return 'L\'extension de domaine doit faire au moins 2 caractères';
                                    }

                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 20),

                                // Champ mot de passe
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixIcon: Icon(Icons.lock, size: isSmallScreen ? 20 : null, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
                                    labelText: "Mot de passe",
                                    labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor),
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
                                      borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor, width: 2),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: isSmallScreen ? 20 : null, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? AppColors.darkBackgroundColor : Colors.white,
                                    contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un mot de passe';
                                    }
                                    if (value.length < 6) {
                                      return 'Le mot de passe doit contenir au moins 6 caractères';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 20),

                                // Champ confirmation mot de passe
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixIcon: Icon(Icons.lock_outline, size: isSmallScreen ? 20 : null, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
                                    labelText: "Confirmez le mot de passe",
                                    labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : null, color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor),
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
                                      borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor, width: 2),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: isSmallScreen ? 20 : null, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? AppColors.darkBackgroundColor : Colors.white,
                                    contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un mot de passe';
                                    }

                                    // 1. Longueur minimale
                                    if (value.length < 8) {
                                      return 'Le mot de passe doit contenir au moins 8 caractères';
                                    }

                                    // 2. Longueur maximale
                                    if (value.length > 128) {
                                      return 'Le mot de passe ne peut excéder 128 caractères';
                                    }

                                    // 3. Contient au moins une majuscule
                                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                      return 'Le mot de passe doit contenir au moins une majuscule';
                                    }

                                    // 4. Contient au moins une minuscule
                                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                                      return 'Le mot de passe doit contenir au moins une minuscule';
                                    }

                                    // 5. Contient au moins un chiffre
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return 'Le mot de passe doit contenir au moins un chiffre';
                                    }

                                    // 6. Contient au moins un caractère spécial
                                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                                      return 'Le mot de passe doit contenir au moins un caractère spécial (!@#\$%^&* etc.)';
                                    }

                                    // 7. Pas d'espaces
                                    if (value.contains(' ')) {
                                      return 'Le mot de passe ne peut pas contenir d\'espaces';
                                    }

                                    // 8. Pas de séquences simples (123, abc, etc.)
                                    if (RegExp(r'(123|abc|password|azerty|qwerty)').hasMatch(value.toLowerCase())) {
                                      return 'Évitez les séquences trop simples';
                                    }

                                    // 9. Pas de répétition excessive (aaa, 1111)
                                    if (RegExp(r'(.)\1{3,}').hasMatch(value)) {
                                      return 'Trop de caractères identiques consécutifs';
                                    }

                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 30),

                                // Bouton d'inscription
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                      height: isSmallScreen ? 20 : 24,
                                      width: isSmallScreen ? 20 : 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AppColors.buttonTextColor,
                                      ),
                                    )
                                        : Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                        color: AppColors.buttonTextColor,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 25),

                                // Lien connexion
                                Padding(
                                  padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 20),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/LoginPage');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Déjà un compte ? ',
                                            style: TextStyle(
                                              color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                                              fontSize: isSmallScreen ? 12 : 15,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'CONNECTEZ-VOUS',
                                            style: TextStyle(
                                              color: isDarkMode ? AppColors.darkSecondaryColor : AppColors.secondaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 12 : 15,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Auth().createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nomCompletController.text.trim(),
          _telephoneController.text.trim(),
          double.tryParse(_budgetController.text.trim()) ?? 0.0,
        );

        if (mounted) {
          _showSuccessSnackbar('Inscription réussie ! Bienvenue');
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RedirectionPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        _handleFirebaseAuthError(e);
      } on SocketException catch (_) {
        _showErrorSnackbar(
          'Pas de connexion internet',
          'Activez votre WiFi ou données mobiles et réessayez.',
          Icons.wifi_off,
        );
      } on TimeoutException catch (_) {
        _showErrorSnackbar(
          'Serveur indisponible',
          'Le serveur met trop de temps à répondre. Réessayez plus tard.',
          Icons.timer_off,
        );
      } on PlatformException catch (e) {
        _showErrorSnackbar(
          'Erreur système',
          'Redémarrez l\'application (Code: ${e.code}).',
          Icons.settings,
        );
      } catch (e) {
        _showErrorSnackbar(
          'Erreur inattendue',
          'Une erreur technique s\'est produite. Veuillez réessayer.',
          Icons.error_outline,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await Auth().signInWithGoogle();
      if (mounted) {
        _showSuccessSnackbar('Inscription réussie avec Google !');
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RedirectionPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'cancelled') {
        _handleFirebaseAuthError(e);
      }
    } catch (e) {
      _showErrorSnackbar(
        'Erreur inattendue',
        'Une erreur s\'est produite lors de l\'inscription avec Google.',
        Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    final errorConfig = _getErrorConfig(e.code);
    _showErrorSnackbar(errorConfig.message, errorConfig.solution, errorConfig.icon);
  }

  ErrorConfig _getErrorConfig(String errorCode) {
    switch (errorCode) {
    // Erreurs d'inscription
      case 'invalid-email':
        return ErrorConfig(
          'Format d\'email incorrect',
          'Veuillez entrer une adresse email valide (ex: utilisateur@exemple.com)',
          Icons.email,
        );
      case 'email-already-in-use':
        return ErrorConfig(
          'Email déjà utilisé',
          'Cet email est déjà associé à un compte. Connectez-vous ou utilisez "Mot de passe oublié".',
          Icons.alternate_email,
        );
      case 'operation-not-allowed':
        return ErrorConfig(
          'Inscription désactivée',
          'L\'inscription par email est temporairement désactivée. Contactez le support.',
          Icons.block,
        );
      case 'weak-password':
        return ErrorConfig(
          'Mot de passe trop faible',
          'Votre mot de passe doit contenir au moins 6 caractères. Ajoutez des chiffres et caractères spéciaux pour plus de sécurité.',
          Icons.password,
        );
      case 'network-request-failed':
        return ErrorConfig(
          'Problème de connexion',
          'Vérifiez votre connexion internet et réessayez.',
          Icons.wifi_off,
        );
      case 'too-many-requests':
        return ErrorConfig(
          'Trop de tentatives',
          'Veuillez patienter quelques minutes avant de réessayer.',
          Icons.timer,
        );
    // Erreurs Google Sign-In
      case 'account-exists-with-different-credential':
        return ErrorConfig(
          'Compte existant',
          'Cet email est déjà associé à un autre compte. Connectez-vous avec la méthode originale.',
          Icons.link_off,
        );
      case 'invalid-verification-code':
        return ErrorConfig(
          'Code de vérification invalide',
          'Le code de vérification est incorrect ou a expiré.',
          Icons.sms_failed,
        );
      default:
        return ErrorConfig(
          'Erreur d\'inscription',
          'Une erreur technique s\'est produite (Code: $errorCode).',
          Icons.error_outline,
        );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String error, String solution, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  error,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              solution,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class ErrorConfig {
  final String message;
  final String solution;
  final IconData icon;

  ErrorConfig(this.message, this.solution, this.icon);
}