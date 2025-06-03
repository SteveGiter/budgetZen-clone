import 'dart:async';
import 'package:budget_zen/services/firebase/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import 'Redirection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                                'Ravie de vous revoir !',
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
                                  'Connectez-vous à votre compte existant',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 16,
                                    color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 15 : 30),
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
                                  return null;
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 20),
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
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 5 : 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/ResetPasswordPage');
                                  },
                                  child: Text(
                                    'Mot de passe oublié',
                                    style: TextStyle(fontSize: isSmallScreen ? 12 : null, color: isDarkMode ? AppColors.darkSecondaryColor : AppColors.secondaryColor),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
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
                                    'Se connecter',
                                    style: TextStyle(
                                      color: AppColors.buttonTextColor,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 15 : 25),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'Ou',
                                      style: TextStyle(fontSize: isSmallScreen ? 12 : null, color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: isDarkMode ? AppColors.darkBorderColor : AppColors.borderColor, thickness: 1)),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 15 : 25),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isGoogleLoading
                                      ? null
                                      : () async {
                                    setState(() => _isGoogleLoading = true);
                                    try {
                                      print('Début de la connexion Google');
                                      final userCredential = await Auth().signInWithGoogle();
                                      if (userCredential != null && mounted) {
                                        print('Connexion Google réussie pour ${userCredential.user?.email}');
                                        print('Redirection vers RedirectionPage');
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RedirectionPage()),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Connexion réussie ! Bienvenue ${userCredential.user?.displayName ?? ''}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: AppColors.primaryColor,
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      print('Erreur FirebaseAuthException: ${e.code} - ${e.message}');
                                      if (mounted && e.code != 'cancelled') {
                                        String errorMessage;
                                        switch (e.code) {
                                          case 'account-exists-with-different-credential':
                                            errorMessage = 'Un compte existe déjà avec cet email.';
                                            break;
                                          case 'invalid-credential':
                                            errorMessage = 'Session Google invalide. Veuillez réessayer.';
                                            break;
                                          case 'operation-not-allowed':
                                            errorMessage = 'Connexion Google désactivée.';
                                            break;
                                          case 'user-disabled':
                                            errorMessage = 'Ce compte a été désactivé.';
                                            break;
                                          case 'network-request-failed':
                                            errorMessage = 'Problème de connexion internet.';
                                            break;
                                          default:
                                            errorMessage = 'Erreur lors de la connexion (${e.code}).';
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(errorMessage)),
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
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('Erreur inattendue: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Expanded(child: Text('Erreur inattendue lors de la connexion.')),
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
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isGoogleLoading = false);
                                        print('Fin de la tentative de connexion Google');
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
                                          'Se connecter avec Google',
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
                              Padding(
                                padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 20),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/SignUpPage');
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Pas encore de compte ? ',
                                          style: TextStyle(
                                            color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                                            fontSize: isSmallScreen ? 12 : 15,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'INSCRIVEZ-VOUS',
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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Début de la connexion email');
        await Auth().loginWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          print('Connexion email réussie pour ${_emailController.text.trim()}');
          print('Redirection vers RedirectionPage');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RedirectionPage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connexion réussie ! Bienvenue',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        print('Erreur FirebaseAuthException: ${e.code} - ${e.message}');
        String errorMessage;
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide.';
            break;
          case 'user-disabled':
            errorMessage = 'Compte désactivé.';
            break;
          case 'user-not-found':
            errorMessage = 'Aucun compte trouvé.';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect.';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives. Réessayez plus tard.';
            break;
          case 'network-request-failed':
            errorMessage = 'Problème de connexion internet.';
            break;
          default:
            errorMessage = 'Erreur: ${e.code}.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(errorMessage)),
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        print('Erreur inattendue: $e');
        String errorMessage = 'Erreur inattendue.';
        if (e is TimeoutException)
          if (e is TimeoutException) {
            errorMessage = 'Temps d\'attente dépassé.';
          }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(errorMessage)),
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          print('Fin de la tentative de connexion email');
        }
      }
    }
  }
}