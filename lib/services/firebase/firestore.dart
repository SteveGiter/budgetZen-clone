import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  // Getter public
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
    required String provider,
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
        'provider': provider,
        'dateInscription': FieldValue.serverTimestamp(),
        'derniereConnexion': FieldValue.serverTimestamp(),
      });

      // Création automatique du budget de départ
      final budgetDoc = _firestore.collection('budgets').doc(uid);
      await budgetDoc.set({
        'budgetInitial': 0,
        'budgetActuel': 0,
        'devise': 'FCFA',
        'categoriePrincipale': 'Général',
        'dateCreation': FieldValue.serverTimestamp(),
      });

      // Ajout d'une entrée dans l'historique de connexion
      final historiqueDoc = _firestore.collection('historique_connexions').doc();
      await historiqueDoc.set({
        'uid': uid,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'evenement': 'Création du compte',
      });

      // Initialiser les statistiques
      await initializeStatistics(uid);
    }
  }

  Future<void> initializeStatistics(String userId) async {
    final statistiquesRef = _firestore.collection('statistiques').doc(userId);
    await statistiquesRef.set({
      'utilisateurId': userId,
      'depensesTotales': 0,
      'revenusTotaux': 0,
      'epargnesTotales': 0,
      'soldeActuel': 0,
      'derniereMiseAJour': FieldValue.serverTimestamp(),
    });

    // Démarrer le suivi en temps réel
    createOrUpdateStatistiques(userId);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestore.collection('utilisateurs').doc(uid).get();
  }

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
    cancelStatisticsSubscription(uid);
  }

  // -------------------- TRANSACTIONS -----------------------
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
      'users': [expediteurId, destinataireId],
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

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _firestore.collection('transactions').doc(id).update(data);
  }

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

  // -------------------- STATISTIQUES EN TEMPS RÉEL --------------------
  Future<void> createOrUpdateStatistiques(String utilisateurId) async {
    cancelStatisticsSubscription(utilisateurId);

    final statistiquesRef = _firestore.collection('statistiques').doc(utilisateurId);
    final docSnapshot = await statistiquesRef.get();

    if (!docSnapshot.exists) {
      await statistiquesRef.set({
        'utilisateurId': utilisateurId,
        'mois': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
        'depensesTotales': 0,
        'revenusTotaux': 0,
        'epargnesTotales': 0,
        'soldeActuel': 0,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    }

    if (_activeSubscriptions.containsKey(utilisateurId)) {
      return;
    }

    final depensesStream = streamTotalDepenses(utilisateurId).distinct();
    final revenusStream = streamTotalRevenus(utilisateurId).distinct();
    final epargnesStream = streamTotalEpargnes(utilisateurId).distinct();

    final combinedStream = Rx.combineLatest3<double, double, double, Map<String, double>>(
      depensesStream,
      revenusStream,
      epargnesStream,
          (depenses, revenus, epargnes) => {
        'depenses': depenses,
        'revenus': revenus,
        'epargnes': epargnes,
      },
    ).distinct();

    _activeSubscriptions[utilisateurId] = combinedStream.throttleTime(
      const Duration(seconds: 1),
      trailing: true,
    ).listen((data) async {
      final now = DateTime.now();
      final mois = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final docId = utilisateurId;

      final statistiquesRef = _firestore.collection('statistiques').doc(docId);

      try {
        final newDepenses = data['depenses'] ?? 0;
        final newRevenus = data['revenus'] ?? 0;
        final newEpargnes = data['epargnes'] ?? 0;
        final newSolde = newRevenus - newDepenses - newEpargnes;

        await statistiquesRef.set({
          'utilisateurId': utilisateurId,
          'mois': mois,
          'depensesTotales': newDepenses,
          'revenusTotaux': newRevenus,
          'epargnesTotales': newEpargnes,
          'soldeActuel': newSolde,
          'derniereMiseAJour': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Erreur lors de la mise à jour des statistiques: $e');
        cancelStatisticsSubscription(utilisateurId);
        createOrUpdateStatistiques(utilisateurId);
      }
    });
  }

  void cancelStatisticsSubscription(String userId) {
    if (_activeSubscriptions.containsKey(userId)) {
      _activeSubscriptions[userId]!.cancel();
      _activeSubscriptions.remove(userId);
    }
  }

  Stream<DocumentSnapshot> getStatisticsStream(String userId) {
    return _firestore.collection('statistiques').doc(userId).snapshots();
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
    required String userId,
    required String nomObjectif,
    required double montantCible,
    required Timestamp dateLimite,
    String? categorie,
  }) async {
    final objectifData = {
      'userId': userId,
      'nomObjectif': nomObjectif,
      'montantCible': montantCible,
      'montantActuel': 0.0, // Initialiser montantActuel
      'dateLimite': dateLimite,
      'categorie': categorie ?? 'Autre',
      'dateCreation': FieldValue.serverTimestamp(),
      'derniereMiseAJour': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('objectifsEpargne').add(objectifData);
  }

  Future<QuerySnapshot> getObjectifsEpargne(String userId) async {
    return await _firestore
        .collection('objectifsEpargne')
        .where('userId', isEqualTo: userId)
        .orderBy('dateCreation', descending: true)
        .get();
  }

  Future<QuerySnapshot> getObjectifsEpargneByCategorie(String userId, String categorie) async {
    return await _firestore
        .collection('objectifsEpargne')
        .where('userId', isEqualTo: userId)
        .where('categorie', isEqualTo: categorie)
        .orderBy('dateCreation', descending: true)
        .get();
  }

  Future<void> updateObjectifEpargne(String id, Map<String, dynamic> data) async {
    await _firestore.collection('objectifsEpargne').doc(id).update(data);
  }

  Future<void> deleteObjectifEpargne(String id) async {
    await _firestore.collection('objectifsEpargne').doc(id).delete();
  }

  Stream<QuerySnapshot> streamObjectifsEpargneByCategorie(String userId, String categorie) {
    return _firestore
        .collection('objectifsEpargne')
        .where('userId', isEqualTo: userId)
        .where('categorie', isEqualTo: categorie)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamAllObjectifsEpargne(String userId) {
    return _firestore
        .collection('objectifsEpargne')
        .where('userId', isEqualTo: userId)
        .orderBy('dateCreation', descending: true)
        .snapshots();
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
      rethrow;
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
      rethrow;
    }
  }

  // -------------------- EPARGNES --------------------
  Future<void> addEpargne({
    required String userId,
    required double montant,
    required String categorie,
    String? description,
    required String objectifId,
    Transaction? transaction, // Ajouter un paramètre optionnel pour la transaction
  }) async {
    try {
      final epargneData = {
        'userId': userId,
        'montant': montant,
        'categorie': categorie,
        'description': description,
        'objectifId': objectifId,
        'dateCreation': FieldValue.serverTimestamp(),
      };

      if (transaction != null) {
        // Si une transaction est fournie, l'utiliser
        final epargneRef = _firestore.collection('epargnes').doc();
        transaction.set(epargneRef, epargneData);
      } else {
        // Sinon, ajouter directement
        await _firestore.collection('epargnes').add(epargneData);
        // Mettre à jour montantActuel si aucune transaction n'est fournie
        await updateMontantActuelObjectif(objectifId);
      }
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'épargne : $e");
      rethrow;
    }
  }

  Future<void> updateMontantActuelObjectif(String objectifId) async {
    try {
      final montantActuel = await _firestore
          .collection('epargnes')
          .where('objectifId', isEqualTo: objectifId)
          .get()
          .then((snapshot) => snapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['montant'] as num).toDouble()));

      await _firestore.collection('objectifsEpargne').doc(objectifId).update({
        'montantActuel': montantActuel,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de montantActuel: $e");
      rethrow;
    }
  }

  // -------------------- MÉTHODES DE CALCUL --------------------
  Future<double> getTotalDepenses(String userId) async {
    final query = _firestore.collection('depenses').where('userId', isEqualTo: userId);
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

  Future<double> getTotalRevenus(String userId) async {
    final query = _firestore.collection('revenus').where('userId', isEqualTo: userId);
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

  Future<double> getTotalEpargnes(String userId) async {
    final query = _firestore.collection('epargnes').where('userId', isEqualTo: userId);
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

  Stream<double> streamMontantActuelParObjectif(String objectifId) {
    return _firestore
        .collection('epargnes')
        .where('objectifId', isEqualTo: objectifId)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  // -------------------- NOUVELLES MÉTHODES POUR FILTRE MENSUEL --------------------
  Stream<double> streamTotalDepensesByMonth(String userId, int month) {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, month, 1));
    final end = Timestamp.fromDate(DateTime(now.year, month + 1, 1).subtract(const Duration(seconds: 1)));

    return _firestore
        .collection('depenses')
        .where('userId', isEqualTo: userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  Stream<double> streamTotalRevenusByMonth(String userId, int month) {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, month, 1));
    final end = Timestamp.fromDate(DateTime(now.year, month + 1, 1).subtract(const Duration(seconds: 1)));

    return _firestore
        .collection('revenus')
        .where('userId', isEqualTo: userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  Stream<double> streamTotalEpargnesByMonth(String userId, int month) {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, month, 1));
    final end = Timestamp.fromDate(DateTime(now.year, month + 1, 1).subtract(const Duration(seconds: 1)));

    return _firestore
        .collection('epargnes')
        .where('userId', isEqualTo: userId)
        .where('dateCreation', isGreaterThanOrEqualTo: start)
        .where('dateCreation', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['montant'] as num).toDouble();
    }));
  }

  // -------------------- UTILITAIRE --------------------
  Future<bool> isPhoneNumberUnique(String phoneNumber, String? provider, String uid) async {
    final query = _firestore.collection('utilisateurs').where('numeroTelephone', isEqualTo: phoneNumber);
    final snapshot = await query.get();

    final existingUsers = snapshot.docs.where((doc) {
      final data = doc.data();
      if (provider == 'google') {
        return data['provider'] == 'google' && doc.id != uid;
      }
      return data['provider'] != 'google';
    });

    return existingUsers.isEmpty;
  }

  void dispose() {
    for (var subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
  }
}