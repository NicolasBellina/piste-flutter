import 'package:flutter/material.dart';

import '../models/candidature.dart';
import '../state/candidature_controller.dart';
import 'widgets/presentation.dart';

class BilanView extends StatelessWidget {
  const BilanView({super.key, required this.controller});
  final CandidatureController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
    children: [
      Text(
        'Mon bilan',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Une vue sur toutes tes démarches, quels que soient les filtres.',
      ),
      const SizedBox(height: 24),
      Text(
        '${controller.elements.length}',
        key: const Key('bilan-total'),
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const Text('candidatures au total'),
      const SizedBox(height: 24),
      for (final statut in Statut.values) ...[
        Row(
          children: [
            Expanded(child: Text(statut.libelle)),
            Text(
              '${controller.nombre(statut)}',
              key: Key('bilan-${statut.name}'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: controller.proportion(statut),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: couleurStatut(statut),
          semanticsLabel:
              '${statut.libelle}, ${controller.nombre(statut)} sur ${controller.elements.length}',
        ),
        const SizedBox(height: 24),
      ],
      if (controller.elements.isEmpty)
        const Text(
          'Ajoute une candidature pour commencer à construire ton bilan.',
        ),
    ],
  );
}
