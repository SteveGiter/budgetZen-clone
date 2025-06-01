import 'package:flutter/material.dart';
import '../services/firebase/auth.dart';

Future<void> confirmLogout(BuildContext context, {String backDestination = '/LoginPage'}) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmation'),
      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await Auth().logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      backDestination,
          (route) => false,
    );
  }
}
