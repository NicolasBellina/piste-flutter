import 'package:flutter/material.dart';

import '../state/candidature_controller.dart';
import 'candidature_form_page.dart';
import 'widgets/presentation.dart';

class CandidatureDetailPage extends StatefulWidget {
  const CandidatureDetailPage({
    super.key,
    required this.controller,
    required this.id,
  });
  final CandidatureController controller;
  final int id;

  @override
  State<CandidatureDetailPage> createState() => _CandidatureDetailPageState();
}

class _CandidatureDetailPageState extends State<CandidatureDetailPage> {
  bool _suppression = false;
  String? _erreur;

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette candidature ?'),
        content: const Text(
          'Cette action est définitive. Les notes et la date de relance seront aussi supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    setState(() {
      _suppression = true;
      _erreur = null;
    });
    try {
      await widget.controller.supprimer(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Candidature supprimée.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Suppression impossible. Réessaie.');
      }
    } finally {
      if (mounted) setState(() => _suppression = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, child) {
      final c = widget.controller.parId(widget.id);
      return Scaffold(
        appBar: AppBar(title: const Text('Détail de la candidature')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: c == null
                  ? MessageEtat(
                      icone: Icons.info_outline,
                      titre: 'Fiche indisponible',
                      message:
                          widget.controller.messageErreur ??
                          'Cette candidature ne figure plus dans la liste.',
                      action: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Retour au suivi'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          c.poste,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.entreprise,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BadgeStatut(statut: c.statut),
                        ),
                        const SizedBox(height: 24),
                        _information(
                          'Prochaine relance',
                          c.prochaineRelance == null
                              ? 'Aucune date prévue'
                              : dateCourte(c.prochaineRelance!),
                        ),
                        _information(
                          'Lien de l’offre',
                          c.url.isEmpty ? 'Non renseigné' : c.url,
                        ),
                        _information(
                          'Notes',
                          c.notes.isEmpty ? 'Aucune note' : c.notes,
                        ),
                        _information('Créée le', dateCourte(c.dateCreation)),
                        _information(
                          'Dernière modification',
                          dateCourte(c.dateModification),
                        ),
                        if (_erreur != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _erreur!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: widget.controller.occupe
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => CandidatureFormPage(
                                      controller: widget.controller,
                                      initiale: c,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: widget.controller.occupe || _suppression
                              ? null
                              : _supprimer,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            _suppression ? 'Suppression…' : 'Supprimer',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );

  Widget _information(String titre, String valeur) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SelectableText(valeur),
      ],
    ),
  );
}
