import 'package:flutter/material.dart';

import '../../models/candidature.dart';

String dateCourte(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

Color couleurStatut(Statut statut) => switch (statut) {
  Statut.brouillon => const Color(0xFF596575),
  Statut.envoyee => const Color(0xFF195DB2),
  Statut.entretien => const Color(0xFF08735F),
  Statut.offre => const Color(0xFF795500),
  Statut.refusee => const Color(0xFFB3261E),
};

class BadgeStatut extends StatelessWidget {
  const BadgeStatut({super.key, required this.statut});
  final Statut statut;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(Icons.circle, size: 9, color: couleurStatut(statut)),
    label: Text(statut.libelle),
    labelStyle: TextStyle(
      color: couleurStatut(statut),
      fontWeight: FontWeight.w600,
    ),
    backgroundColor: couleurStatut(statut).withValues(alpha: 0.09),
    side: BorderSide.none,
    visualDensity: VisualDensity.compact,
  );
}

class MessageEtat extends StatelessWidget {
  const MessageEtat({
    super.key,
    required this.icone,
    required this.titre,
    required this.message,
    this.action,
  });
  final IconData icone;
  final String titre;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}
