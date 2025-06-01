import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors/app_colors.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? AppColors.darkIconColor : AppColors.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isSmallScreen ? 20 : 40),
                    Center(
                      child: Image.asset('assets/logoWithProjectName.png', height: isSmallScreen ? screenWidth * 0.35 : 100, width: isSmallScreen ? screenWidth * 0.35 : 100),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 30),
                    Text(
                      'Réinitialisation du mot de passe',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 10),
                    Text(
                      'Entrez votre email pour recevoir un lien de réinitialisation',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkSecondaryTextColor : AppColors.secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 30 : 30),
                    Form(
                      key: _formKey,
                      child: TextFormField(
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
                          labelText: "Email",
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
                            borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppColors.darkBackgroundColor : Colors.white,
                          contentPadding: isSmallScreen ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 30 : 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? AppColors.darkPrimaryColor : AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: AppColors.buttonTextColor)
                            : Text('Envoyer le lien', style: TextStyle(color: AppColors.buttonTextColor)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Lien envoyé à ${_emailController.text.trim()}')),
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
        Navigator.pop(context); // Retour à la page de login
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Erreur inconnue';
        if (e.code == 'user-not-found') {
          errorMessage = 'Aucun compte associé à cet email';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Email invalide';
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}