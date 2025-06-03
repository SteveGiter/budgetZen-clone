import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:budget_zen/services/firebase/firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<bool> _isNetworkAvailable() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isConnected = connectivityResult != ConnectivityResult.none;
      print('Vérification réseau: ${isConnected ? "Connecté" : "Non connecté"}');
      return isConnected;
    } catch (e) {
      print('Erreur vérification réseau: $e');
      return false;
    }
  }

  Future<bool> _checkGooglePlayServices() async {
    try {
      final result = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
      print('Statut Google Play Services: $result');
      if (result == GooglePlayServicesAvailability.success) {
        return true;
      } else {
        print('Google Play Services non disponible, tentative de mise à jour');
        await GoogleApiAvailability.instance.makeGooglePlayServicesAvailable();
        return false;
      }
    } catch (e) {
      print('Erreur lors de la vérification de Google Play Services: $e');
      return false;
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      if (!await _isNetworkAvailable()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Aucune connexion Internet. Veuillez vérifier votre réseau.',
        );
      }
      print('Tentative de connexion avec email: $email');
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      print('Connexion email réussie');
    } catch (e, stackTrace) {
      print('Erreur connexion email: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Étape 1: Vérification réseau');
      if (!await _isNetworkAvailable()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Aucune connexion Internet. Veuillez vérifier votre réseau.',
        );
      }

      print('Étape 2: Vérification Google Play Services');
      if (!await _checkGooglePlayServices()) {
        throw FirebaseAuthException(
          code: 'google-services-update-required',
          message: 'Mise à jour de Google Play Services requise.',
        );
      }

      print('Étape 3: Initialisation GoogleSignIn');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        signInOption: SignInOption.standard,
      );

      print('Étape 4: Déconnexion préalable pour forcer la sélection de compte');
      await googleSignIn.signOut(); // Déconnecte tout compte Google pré-sélectionné
      print('Étape 5: Affichage de la boîte de dialogue de sélection de compte Google');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("Connexion Google annulée par l'utilisateur");
        throw FirebaseAuthException(code: 'cancelled', message: 'Connexion annulée');
      }

      print("Étape 6: Récupération des informations d'authentification pour ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Étape 7: Création du credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Étape 8: Connexion à Firebase');
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print("Étape 9: Vérification de l'existence de l'utilisateur dans Firestore");
        final bool exists = await FirestoreService().userExists(user.uid);

        if (!exists) {
          print('Étape 10: Création du profil utilisateur');
          await FirestoreService().createOrUpdateUserProfile(
            uid: user.uid,
            nomPrenom: user.displayName ?? '',
            email: user.email!,
            provider: 'google',
          );
        } else {
          print('Étape 10: Mise à jour de la dernière connexion');
          await FirestoreService().updateLastLogin(user.uid);
        }
      }

      print('Connexion Google réussie: ${user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Erreur inattendue: $e\nStackTrace: $stackTrace');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Erreur inattendue: ${e.toString()}',
      );
    }
  }

  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      String nomComplet,
      String telephone,
      double budget,
      ) async {
    try {
      if (!await _isNetworkAvailable()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Aucune connexion Internet. Veuillez vérifier votre réseau.',
        );
      }

      print('Tentative de création de compte avec email: $email');
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        print("Vérification si l'utilisateur existe dans Firestore");
        final exists = await FirestoreService().userExists(user.uid);

        if (!exists) {
          print('Création du profil utilisateur');
          await FirestoreService().createOrUpdateUserProfile(
            uid: user.uid,
            nomPrenom: nomComplet,
            email: user.email!,
            provider: 'email',
            numeroTelephone: telephone,
          );
        }
        print('Création de compte réussie');
      }
    } catch (e, stackTrace) {
      print('Erreur lors de la création du compte: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print("Déconnexion de l'utilisateur");
      await _firebaseAuth.signOut();
      print('Déconnexion réussie');
    } catch (e, stackTrace) {
      print('Erreur lors de la déconnexion: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      if (!await _isNetworkAvailable()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Aucune connexion Internet. Veuillez vérifier votre réseau.',
        );
      }

      print("Envoi de l'email de réinitialisation pour: $email");
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('Email de réinitialisation envoyé');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "L'adresse email fournie n'est pas valide";
          break;
        case 'user-not-found':
          errorMessage = "Aucun compte n'est associé à cette adresse email";
          break;
        case 'user-disabled':
          errorMessage = "Ce compte a été désactivé";
          break;
        case 'too-many-requests':
          errorMessage = "Trop de tentatives. Veuillez patienter avant de réessayer";
          break;
        case 'network-request-failed':
          errorMessage = "Erreur de réseau. Vérifiez votre connexion internet";
          break;
        default:
          errorMessage = "Impossible d'envoyer l'email de réinitialisation";
      }
      print('Erreur FirebaseAuth: ${e.code} - $errorMessage');
      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e, stackTrace) {
      print('Erreur inattendue: $e\nStackTrace: $stackTrace');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: "Une erreur inattendue s'est produite",
      );
    }
  }
}