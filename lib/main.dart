import 'dart:io';
import 'package:budget_zen/appPages/Initial.dart';
import 'package:budget_zen/appPages/Settings.dart';
import 'package:budget_zen/appPages/SignUp.dart';
import 'package:budget_zen/services/firebase/messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'appPages/About.dart';
import 'appPages/Home.dart';
import 'appPages/Login.dart';
import 'appPages/Profile.dart';
import 'appPages/Redirection.dart';
import 'appPages/Reset_password.dart';
import 'appPages/Transaction.dart';
import 'appPages/Welcome.dart';
import 'appPages/admin.dart';
import 'colors/app_colors.dart';
import 'firebase_options.dart';

class ThemeNotifier with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'MainNavigator');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Pour éviter cette erreur: Could not navigate to initial route.
  // The requested route name was: "/TransactionPage"
  // There was no corresponding route in the app, and therefore the initial
  // route specified will be ignored and "/" will be used instead.
  //setUrlStrategy(PathUrlStrategy()); // important


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //initialisation du service de notification
  //await FirebaseMessagingService().initFCM();

  //await FirebaseAuth.instance.setPersistence(Persistence.LOCAL); //Cette fonctionnaté n'est pas supportée sur mobile
  await initializeDateFormatting('fr_FR', null); // Initialise les données françaises

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Ajout de WidgetsBindingObserver pour écouter les changements de cycle de vie de l'app
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();

    // Enregistrement de l'observateur du cycle de vie
    WidgetsBinding.instance.addObserver(this);

    // Déterminer la route initiale selon si l'utilisateur est connecté ou non
    _initialRouteFuture = _getInitialRoute();
  }

  @override
  void dispose() {
    // Nettoyage : retirer l'observateur quand l'app est détruite
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Méthode déclenchée quand l'état de l'app change (active, inactive, en pause, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Appliquer la déconnexion uniquement sur mobile (Android ou iOS)
    if (!kIsWeb &&
        (Platform.isAndroid || Platform.isIOS) &&
        (state == AppLifecycleState.inactive || state == AppLifecycleState.paused)) {
      FirebaseAuth.instance.signOut();

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/LoginPage',
            (Route<dynamic> route) => false,
      );
    }
  }


  // Détermine la route initiale selon la session Firebase
  Future<String> _getInitialRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '/RedirectionPage' : '/WelcomePage';
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // FutureBuilder attend que la route initiale soit déterminée
    return FutureBuilder<String>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Pendant le chargement, afficher un loader
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Application principale
        return MaterialApp(
          navigatorKey: navigatorKey, // Permet la navigation globale sans contexte
          debugShowCheckedModeBanner: false,

          // Thème clair
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primaryColor,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              secondary: AppColors.secondaryColor,
            ),
          ),

          // Thème sombre
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.darkPrimaryColor,
            colorScheme: ColorScheme.dark(
              primary: AppColors.darkPrimaryColor,
              secondary: AppColors.darkSecondaryColor,
            ),
          ),

          // Application du thème selon l'état du switch
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,

          // Route initiale selon l'état de connexion
          initialRoute: snapshot.data,

          // Définition des routes principales
          routes: {
            '/WelcomePage': (context) => const WelcomePage(),
            '/LoginPage': (context) => const LoginPage(),
            '/SignUpPage': (context) => const SignUpPage(),
            '/ResetPasswordPage': (context) => const ResetPasswordPage(),
            '/RedirectionPage': (context) => const RedirectionPage(),
            '/HomePage': (context) => const HomePage(),
            '/AdminPage': (context) => const AdminWelcomePage(),
            '/TransactionPage': (context) => const Transaction(),
            '/SettingsPage': (context) => const SettingsPage(),
            '/ProfilePage': (context) => const ProfilePage(),
            '/AboutPage': (context) => AboutPage(),
          },

          // Routes personnalisées (fallback)
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/InitialPage':
                return MaterialPageRoute(builder: (_) => const InitialPage());
              default:
                return MaterialPageRoute(builder: (_) => const WelcomePage());
            }
          },
        );
      },
    );
  }
}