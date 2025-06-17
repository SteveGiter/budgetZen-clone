import 'package:budget_zen/services/firebase/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/ForAdmin/admin_bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final FirestoreService _firestore = FirestoreService();
  final DateFormat dateFormat = DateFormat('EEEE dd MMMM yyyy \'à\' HH:mm:ss', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord Admin',
        showBackArrow: false,
        showDarkModeButton: true,
      ),
      backgroundColor: Colors.transparent, // Keep Scaffold background transparent
      body: Column(
        children: [
          Expanded( // Use Expanded to fill available space
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/Administrateur.png'),
                  fit: BoxFit.cover, // Cover the entire container
                  alignment: Alignment.bottomCenter, // Align image bottom with container bottom
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.2),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liste des Utilisateurs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUsersList(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index != 0) {
            final routes = ['/dashboardPage', '/addusersPage', '/adminProfilPage'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.firestore.collection('utilisateurs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("Aucun utilisateur trouvé", context);
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            return _buildUserCard(userDoc, context);
          },
        );
      },
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = uid == currentUserUid;

    final nomPrenom = isCurrentUser ? 'Vous' : (data['nomPrenom'] as String? ?? 'Non défini');
    final email = data['email'] as String? ?? 'Non défini';
    final role = data['role'] as String? ?? 'utilisateur';
    final dateInscription = (data['dateInscription'] as Timestamp?)?.toDate();
    final derniereConnexion = (data['derniereConnexion'] as Timestamp?)?.toDate();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nomPrenom.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (!isCurrentUser) // N'affiche le bouton de suppression que si ce n'est pas l'utilisateur actuel
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteDialog(uid, nomPrenom, context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Email: $email',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rôle: ${role.capitalize()}',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            if (dateInscription != null)
              Text(
                'Inscription: ${dateFormat.format(dateInscription)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            const SizedBox(height: 4),
            if (derniereConnexion != null)
              Text(
                'Dernière connexion: ${dateFormat.format(derniereConnexion)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 100,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String uid, String nomPrenom, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer l'utilisateur"),
          content: Text("Voulez-vous vraiment supprimer l'utilisateur '$nomPrenom' et toutes ses données associées ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _deleteUserAndData(uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Utilisateur supprimé avec succès")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la suppression: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserAndData(String uid) async {
    final batch = _firestore.firestore.batch();

    // Delete user document
    final userRef = _firestore.firestore.collection('utilisateurs').doc(uid);
    batch.delete(userRef);

    // Delete budget document
    final budgetRef = _firestore.firestore.collection('budgets').doc(uid);
    batch.delete(budgetRef);

    // Delete statistics document
    final statsRef = _firestore.firestore.collection('statistiques').doc(uid);
    batch.delete(statsRef);

    // Delete transactions where user is involved
    final transactionsSnapshot = await _firestore.firestore
        .collection('transactions')
        .where('users', arrayContains: uid)
        .get();
    for (var doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete savings goals
    final objectifsSnapshot = await _firestore.firestore
        .collection('objectifsEpargne')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in objectifsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete revenues
    final revenusSnapshot = await _firestore.firestore
        .collection('revenus')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in revenusSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete expenses
    final depensesSnapshot = await _firestore.firestore
        .collection('depenses')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in depensesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete savings
    final epargnesSnapshot = await _firestore.firestore
        .collection('epargnes')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in epargnesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete connection history
    final historiqueSnapshot = await _firestore.firestore
        .collection('historique_connexions')
        .where('uid', isEqualTo: uid)
        .get();
    for (var doc in historiqueSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch
    await batch.commit();

    // Cancel any active subscriptions
    _firestore.cancelStatisticsSubscription(uid);
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}