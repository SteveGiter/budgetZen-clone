import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:budget_zen/services/firebase/firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /*
  Auth() {
    _firebaseAuth.setPersistence(Persistence.LOCAL);
  }
   */

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard,
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'cancelled', message: "Connexion annulée");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final bool exists = await FirestoreService().userExists(user.uid);

        if (!exists) {
          await FirestoreService().createOrUpdateUserProfile(
            uid: user.uid,
            nomPrenom: user.displayName ?? '',
            email: user.email!,
            provider: 'google', // <-- Ajout crucial
          );
        } else {
          await FirestoreService().updateLastLogin(user.uid);
        }
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
          code: 'google-signin-error',
          message: e.message ?? "Erreur lors de la connexion Google"
      );
    } catch (e) {
      throw FirebaseAuthException(
          code: 'unknown-error',
          message: "Erreur inattendue"
      );
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      String nomComplet,
      String telephone,
      double budget,
      ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        final exists = await FirestoreService().userExists(user.uid);

        if (!exists) {
          await FirestoreService().createOrUpdateUserProfile(
            uid: user.uid,
            nomPrenom: nomComplet,
            email: user.email!,
            provider: 'email',
            numeroTelephone: telephone,
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la création du compte: $e');
      rethrow;
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard,
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'cancelled', message: "Connexion annulée");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userExists = await FirestoreService().userExists(user.uid);

        if (!userExists) {
          // Dans votre logique d'authentification Google
          await FirestoreService().createOrUpdateUserProfile(
            uid: user.uid,
            nomPrenom: user.displayName ?? '',
            email: user.email!,
            provider: 'google', // <-- Ajout crucial
          );
        } else {
          await FirestoreService().updateLastLogin(user.uid);
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      if (e is PlatformException) rethrow;

      throw FirebaseAuthException(
          code: 'unknown-error',
          message: "Erreur lors de la connexion Google"
      );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
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
      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      throw FirebaseAuthException(
          code: 'unknown-error',
          message: "Une erreur inattendue s'est produite"
      );
    }
  }
}
