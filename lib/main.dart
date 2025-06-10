import 'dart:io';
import 'package:budget_zen/appPages/Initial.dart';
import 'package:budget_zen/appPages/Settings.dart';
import 'package:budget_zen/appPages/SignUp.dart';
import 'package:budget_zen/appPages/adminPages/AddUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'appPages/About.dart';
import 'appPages/HistoriqueObjectifsEpargne/HistoriqueObjectifsEpargneWithBackArrow.dart';
import 'appPages/HistoriqueObjectifsEpargne/HistoriqueObjectifsEpargneWithoutBackArrow.dart';
import 'appPages/Home.dart';
import 'appPages/Login.dart';
import 'appPages/Profile.dart';
import 'appPages/Redirection.dart';
import 'appPages/Reset_password.dart';
import 'appPages/SavingsGoalsPage.dart';
import 'appPages/Transaction.dart';
import 'appPages/Welcome.dart';
import 'appPages/adminPages/AdminProfile.dart';
import 'appPages/adminPages/Dashboard.dart';
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Enregistrez l'erreur ici si nécessaire
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Gérer les erreurs non capturées
    return true; // Indique que l'erreur a été gérée
  };

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialRouteFuture = _getInitialRoute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) &&
        (state == AppLifecycleState.inactive || state == AppLifecycleState.paused)) {
      FirebaseAuth.instance.signOut();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/LoginPage', (Route<dynamic> route) => false);
    }
  }

  Future<String> _getInitialRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '/RedirectionPage' : '/WelcomePage';
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return FutureBuilder<String>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primaryColor,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              secondary: AppColors.secondaryColor,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.darkPrimaryColor,
            colorScheme: ColorScheme.dark(
              primary: AppColors.darkPrimaryColor,
              secondary: AppColors.darkSecondaryColor,
            ),
          ),
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: snapshot.data,
          routes: {
            //users routes
            '/WelcomePage': (context) => const WelcomePage(),
            '/LoginPage': (context) => const LoginPage(),
            '/SignUpPage': (context) => const SignUpPage(),
            '/ResetPasswordPage': (context) => const ResetPasswordPage(),
            '/RedirectionPage': (context) => const RedirectionPage(),
            '/HomePage': (context) => const HomePage(),
            '/AdminPage': (context) => const DashboardAdminPage(),
            '/TransactionPage': (context) => const Transaction(),
            '/SettingsPage': (context) => const SettingsPage(),
            '/ProfilePage': (context) => const ProfilePage(),
            '/AboutPage': (context) => AboutPage(),
            '/SavingsGoalsPage': (context) => SavingsGoalsPage(),
            '/historique-epargne': (context) => const HistoriqueObjectifsEpargneWithBackArrow(),
            '/historique-epargne-no-back': (context) => const HistoriqueObjectifsEpargneWithoutBackArrow(),

            //administrateur routes
            '/dashboardPage': (context) => const DashboardAdminPage(),
            '/addusersPage': (context) => const AddUsersPage(),
            '/adminProfilPage':  (context) => const AdminProfilePage(),
          },
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