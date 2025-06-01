import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajoutez ce getter public
  FirebaseFirestore get firestore => _firestore;

  // -------------------- UTILISATEURS --------------------

  Future<bool> userExists(String uid) async {
    final docSnapshot = await _firestore.collection('utilisateurs').doc(uid).get();
    return docSnapshot.exists;
  }

  Future<void> updateLastLogin(String uid) async {
    final userDoc = _firestore.collection('utilisateurs').doc(uid);

    await userDoc.update({
      'derniereConnexion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrUpdateUserProfile({
    required String uid,
    required String nomPrenom,
    required String email,
    String? numeroTelephone,
    String role = 'utilisateur',
    required String provider, // Ajout du paramètre provider
  }) async {
    final userDocRef = _firestore.collection('utilisateurs').doc(uid);
    final exists = await userExists(uid);

    if (exists) {
      await userDocRef.update({
        'nomPrenom': nomPrenom,
        'email': email,
        if (numeroTelephone != null) 'numeroTelephone': numeroTelephone,
        'derniereConnexion': FieldValue.serverTimestamp(),
      });
    } else {
      await userDocRef.set({
        'nomPrenom': nomPrenom,
        'email': email,
        'numeroTelephone': numeroTelephone,
        'role': role,
        'provider': provider, // Stockage du provider
        'dateInscription': FieldValue.serverTimestamp(),
        'derniereConnexion': FieldValue.serverTimestamp(),
      });

      // Création automatique du budget de départ
      final budgetDoc = _firestore.collection('budgets').doc(uid);
      await budgetDoc.set({
        'budgetInitial': 0,
        'budgetActuel': 0,
        'devise': 'EUR',
        'categoriePrincipale': 'Général',
        'dateCreation': FieldValue.serverTimestamp(),
      });

      // Ajout d'une entrée dans l'historique de connexion
      final historiqueDoc = _firestore.collection('historique_connexions').doc(); // auto-ID
      await historiqueDoc.set({
        'uid': uid,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'evenement': 'Création du compte',
      });
    }
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestore.collection('utilisateurs').doc(uid).get();
  }

  // Dans la classe FirestoreService
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('utilisateurs').doc(uid).snapshots();
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('utilisateurs').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération du rôle utilisateur : $e");
    }
    return null;
  }


  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('utilisateurs').doc(uid).update(data);
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de l'utilisateur $uid : $e");
      throw Exception("Échec de la mise à jour");
    }
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('utilisateurs').doc(uid).delete();
  }

  // -------------------- TRANSACTIONS --------------------

  /// Enregistre une nouvelle transaction
  Future<void> saveTransaction({
    required String expediteurId,
    required String destinataireId,
    required double montant,
    required String typeTransaction,
    required String categorie,
    String? description,
  }) async {
    final transactionData = {
      'expediteurId': expediteurId,
      'destinataireId': destinataireId,
      'users': [expediteurId, destinataireId], // Pour les requêtes avec arrayContains
      'montant': montant,
      'typeTransaction': typeTransaction,
      'categorie': categorie,
      'description': description,
      'dateHeure': FieldValue.serverTimestamp(),
      'expediteurDeleted': null,
      'destinataireDeleted': null,
    };

    await _firestore.collection('transactions').add(transactionData);
  }

  /// Récupère toutes les transactions visibles par l'utilisateur
  Future<QuerySnapshot> getTransactions(String userId) async {
    return await _firestore
        .collection('transactions')
        .where('users', arrayContains: userId)
        .where('expediteurDeleted', isEqualTo: null)
        .where('destinataireDeleted', isEqualTo: null)
        .orderBy('expediteurDeleted')
        .orderBy('destinataireDeleted')
        .orderBy('dateHeure', descending: true)
        .get();
      }

      /// Met à jour une transaction
      Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
        await _firestore.collection('transactions').doc(id).update(data);
      }

      /// Effectue un "soft delete" d'une transaction pour un utilisateur
      Future<void> softDeleteTransaction(String transactionId, String userId) async {
        final doc = await _firestore.collection('transactions').doc(transactionId).get();
        final data = doc.data();

        if (data == null) return;

        final isExpediteur = data['expediteurId'] == userId;
        final fieldToUpdate = isExpediteur ? 'expediteurDeleted' : 'destinataireDeleted';

        await _firestore.collection('transactions').doc(transactionId).update({
          fieldToUpdate: userId,
        });
      }


  // -------------------- BUDGETS --------------------

  Future<void> createBudget({
    required String categorie,
    required double montantBudget,
    required Timestamp dateDebut,
    required Timestamp dateFin,
  }) async {
    final budgetData = {
      'categorie': categorie,
      'montantBudget': montantBudget,
      'dateDebut': dateDebut,
      'dateFin': dateFin,
    };
    await _firestore.collection('budgets').add(budgetData);
  }

  Future<QuerySnapshot> getBudgets() async {
    return await _firestore.collection('budgets').get();
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    await _firestore.collection('budgets').doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    await _firestore.collection('budgets').doc(id).delete();
  }

  // -------------------- OBJECTIFS ÉPARGNE --------------------

  Future<void> createObjectifEpargne({
    required String nomObjectif,
    required double montantCible,
    required double montantActuel,
    required Timestamp dateLimite,
  }) async {
    final objectifData = {
      'nomObjectif': nomObjectif,
      'montantCible': montantCible,
      'montantActuel': montantActuel,
      'dateLimite': dateLimite,
    };
    await _firestore.collection('objectifsEpargne').add(objectifData);
  }

  Future<QuerySnapshot> getObjectifsEpargne() async {
    return await _firestore.collection('objectifsEpargne').get();
  }

  Future<void> updateObjectifEpargne(String id, Map<String, dynamic> data) async {
    await _firestore.collection('objectifsEpargne').doc(id).update(data);
  }

  Future<void> deleteObjectifEpargne(String id) async {
    await _firestore.collection('objectifsEpargne').doc(id).delete();
  }

  // -------------------- STATISTIQUES --------------------

  Future<void> createStatistiques({
    required String utilisateurId,
    required double depensesTotales,
    required double revenusTotaux,
    required double economiesTotales,
  }) async {
    final statistiquesData = {
      'utilisateurId': utilisateurId,
      'depensesTotales': depensesTotales,
      'revenusTotaux': revenusTotaux,
      'economiesTotales': economiesTotales,
    };
    await _firestore.collection('statistiques').add(statistiquesData);
  }

  Future<QuerySnapshot> getStatistiques() async {
    return await _firestore.collection('statistiques').get();
  }

  Future<void> updateStatistiques(String id, Map<String, dynamic> data) async {
    await _firestore.collection('statistiques').doc(id).update(data);
  }

  Future<void> deleteStatistiques(String id) async {
    await _firestore.collection('statistiques').doc(id).delete();
  }

  // -------------------- PARAMÈTRES --------------------

  Future<void> saveParametres({
    required String parametreId,
    required Map<String, dynamic> preferencesUtilisateur,
  }) async {
    final parametreData = {
      'preferencesUtilisateur': preferencesUtilisateur,
    };
    await _firestore.collection('parametres').doc(parametreId).set(parametreData);
  }

  Future<DocumentSnapshot> getParametres(String parametreId) async {
    return await _firestore.collection('parametres').doc(parametreId).get();
  }

  Future<void> updateParametres(String parametreId, Map<String, dynamic> data) async {
    await _firestore.collection('parametres').doc(parametreId).update(data);
  }

  Future<void> deleteParametres(String parametreId) async {
    await _firestore.collection('parametres').doc(parametreId).delete();
  }

  // -------------------- HISTORIQUE CONNEXIONS --------------------

  Future<void> saveHistoriqueConnexion({
    required String utilisateurId,
    required Timestamp dateHeureConnexion,
    String? adresseIP,
  }) async {
    final historiqueData = {
      'utilisateurId': utilisateurId,
      'dateHeureConnexion': dateHeureConnexion,
      if (adresseIP != null) 'adresseIP': adresseIP,
    };
    await _firestore.collection('historiqueConnexions').add(historiqueData);
  }

  Future<QuerySnapshot> getHistoriquesConnexions() async {
    return await _firestore.collection('historiqueConnexions').get();
  }

  Future<void> updateHistoriqueConnexion(String id, Map<String, dynamic> data) async {
    await _firestore.collection('historiqueConnexions').doc(id).update(data);
  }

  Future<void> deleteHistoriqueConnexion(String id) async {
    await _firestore.collection('historiqueConnexions').doc(id).delete();
  }


// -------------------- REVENUS --------------------
  Future<void> addRevenu({
    required String userId,
    required double montant,
    required String categorie,
    String? description,
  }) async {
    try {
      await _firestore.collection('revenus').add({
        'userId': userId,
        'montant': montant,
        'categorie': categorie,
        'description': description,
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur lors de l'ajout du revenu : $e");
    }
  }

// -------------------- DEPENSES --------------------
  Future<void> addDepense({
    required String userId,
    required double montant,
    required String categorie,
    String? description,
  }) async {
    try {
      await _firestore.collection('depenses').add({
        'userId': userId,
        'montant': montant,
        'categorie': categorie,
        'description': description,
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de la dépense : $e");
    }
  }

// -------------------- EPARGNES --------------------
  Future<void> addEpargne({
    required String userId,
    required double montant,
    required String categorie,
    String? description,
  }) async {
    try {
      await _firestore.collection('epargnes').add({
        'userId': userId,
        'montant': montant,
        'categorie': categorie,
        'description': description,
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'épargne : $e");
    }
  }
//------------------------------------------------------------------------------

  //Méthode permétant de vérifié l'unicité du numéro de téléphone saisi
  Future<bool> isPhoneNumberUnique(String phoneNumber, String? provider, String uid) async {
    final query = _firestore.collection('utilisateurs')
        .where('numeroTelephone', isEqualTo: phoneNumber);

    final snapshot = await query.get();

    // Filtre selon le provider
    final existingUsers = snapshot.docs.where((doc) {
      final data = doc.data();
      if (provider == 'google') {
        return data['provider'] == 'google' && doc.id != uid;
      }
      return data['provider'] != 'google';
    });

    return existingUsers.isEmpty;
  }




// Méthode de récupération des dépenses
  Future<double> getTotalDepenses(String userId) async {
    final query = _firestore
        .collection('depenses')
        .where('userId', isEqualTo: userId);

    final snapshot = await query.get();
    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    });
  }

  Stream<double> streamTotalDepenses(String userId) {
    return _firestore
        .collection('depenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

// Méthode de récupération des revenus
  Future<double> getTotalRevenus(String userId) async {
    final query = _firestore
        .collection('revenus')
        .where('userId', isEqualTo: userId);

    final snapshot = await query.get();
    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    });
  }

  Stream<double> streamTotalRevenus(String userId) {
    return _firestore
        .collection('revenus')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  // Méthode de récupération des épargnes
  Future<double> getTotalEpargnes(String userId) async {
    final query = _firestore
        .collection('epargnes')
        .where('userId', isEqualTo: userId);

    final snapshot = await query.get();
    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    });
  }

  Stream<double> streamTotalEpargnes(String userId) {
    return _firestore
        .collection('epargnes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }


  //Pour l'année
  Stream<double> streamTotalDepensesForCurrentYear(String userId) {
    final currentYear = DateTime.now().year;
    return _firestore
        .collection('depenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateTime(currentYear, 1, 1))
        .where('date', isLessThanOrEqualTo: DateTime(currentYear, 12, 31))
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  Stream<double> streamTotalRevenusForCurrentYear(String userId) {
    final currentYear = DateTime.now().year;
    return _firestore
        .collection('revenus')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateTime(currentYear, 1, 1))
        .where('date', isLessThanOrEqualTo: DateTime(currentYear, 12, 31))
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

}
