// Première classe avec showBackArrow = true
import 'package:flutter/cupertino.dart';
import '../../widgets/Historique_Objectifs_Epargne.dart';

class HistoriqueObjectifsEpargneWithBackArrow extends StatelessWidget {
  const HistoriqueObjectifsEpargneWithBackArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoriqueObjectifsEpargne(
      showBackArrow: true,
    );
  }
}

// Deuxième classe avec showBackArrow = false
class HistoriqueObjectifsEpargneWithoutBackArrow extends StatelessWidget {
  const HistoriqueObjectifsEpargneWithoutBackArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoriqueObjectifsEpargne(
      showBackArrow: false,
    );
  }
}