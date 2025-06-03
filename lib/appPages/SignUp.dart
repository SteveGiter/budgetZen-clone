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
      body: LayoutBuilder(
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
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
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
                                    return 'Veuillez confirmer votre mot de passe';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Les mots de passe ne correspondent pas';
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
    );
  }

  Future<void> _register() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Auth().createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nomCompletController.text.trim(),
          _telephoneController.text.trim(),
          double.tryParse(_budgetController.text.trim()) ?? 0.0,
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Inscription réussie !',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Félicitations ! Votre compte a été créé avec l\'adresse : ${_emailController.text.trim()}\n\nVous pouvez maintenant accéder à toutes les fonctionnalités de BudgetZen.',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Continuer',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                  ),
                ),
              ),
            ],
            backgroundColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RedirectionPage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        switch (e.code) {
          case 'invalid-email':
            errorMessage = "Format d'email invalide. Utilisez une adresse valide (ex: utilisateur@exemple.com)";
            break;
          case 'email-already-in-use':
            errorMessage = "Cet email est déjà utilisé. Connectez-vous ou utilisez l'option 'Mot de passe oublié'";
            break;
          case 'operation-not-allowed':
            errorMessage = "Inscription désactivée. Contactez le support à support@budgetzen.com";
            break;
          case 'weak-password':
            errorMessage = "Mot de passe trop faible (minimum 6 caractères). Ajoutez des chiffres et caractères spéciaux";
            break;
          case 'network-request-failed':
            errorMessage = "Problème de connexion internet. Vérifiez votre réseau et réessayez";
            break;
          case 'too-many-requests':
            errorMessage = "Trop de tentatives. Veuillez patienter quelques minutes";
            break;
          case 'invalid-credential':
            errorMessage = "Identifiants invalides. Actualisez la page et réessayez";
            break;
          default:
            errorMessage = "Erreur d'inscription (${e.code}). Veuillez réessayer";
        }

        if (mounted) {
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
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        String errorMessage = "Erreur technique";

        if (e is SocketException) {
          errorMessage = "Pas de connexion internet. Activez WiFi/mobile data";
        } else if (e is TimeoutException) {
          errorMessage = "Serveur indisponible. Réessayez plus tard";
        } else if (e is FormatException) {
          errorMessage = "Format de données invalide. Vérifiez vos informations";
        } else if (e is PlatformException) {
          errorMessage = "Erreur système (${e.code}). Redémarrez l'application";
        } else {
          errorMessage = "Erreur inattendue: ${e.toString().split(':').first}";
        }

        if (mounted) {
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
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}