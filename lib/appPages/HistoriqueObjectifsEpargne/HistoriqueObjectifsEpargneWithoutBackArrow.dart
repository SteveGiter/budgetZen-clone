// Deuxième classe avec showBackArrow = false
import 'package:flutter/cupertino.dart';
import '../../widgets/Historique_Objectifs_Epargne.dart';

class HistoriqueObjectifsEpargneWithoutBackArrow extends StatelessWidget {
  const HistoriqueObjectifsEpargneWithoutBackArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoriqueObjectifsEpargne(
      showBackArrow: false,
    );
  }
}