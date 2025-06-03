import 'dart:async';
import 'package:budget_zen/services/firebase/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RedirectionPage extends StatefulWidget {
  const RedirectionPage({super.key});

  @override
  State<RedirectionPage> createState() => _RedirectionPageState();
}

class _RedirectionPageState extends State<RedirectionPage> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  bool _isCheckingAuth = true;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isCheckingAuth = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
      debugPrint("Erreur d'authentification: $error");
    });
  }

  void _redirectUser(BuildContext context, String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
              (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      _redirectUser(context, '/LoginPage');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<String?>(
      future: _firestoreService.getUserRole(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          _redirectUser(context, '/InitialPage');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;
        final route = role == 'administrateur' ? '/AdminPage' : '/HomePage';

        _redirectUser(context, route);

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}