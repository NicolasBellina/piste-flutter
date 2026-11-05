import 'package:flutter/material.dart';

import '../models/candidature.dart';
import '../state/candidature_controller.dart';
import 'bilan_view.dart';
import 'candidature_detail_page.dart';
import 'candidature_form_page.dart';
import 'widgets/presentation.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key, required this.controller});
  final CandidatureController controller;

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _onglet = 0;

  Future<void> _ajouter() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CandidatureFormPage(controller: widget.controller),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, child) => Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline),
            SizedBox(width: 10),
            Text('Piste', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: switch (widget.controller.etat) {
              EtatChargement.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              EtatChargement.error => MessageEtat(
                icone: Icons.cloud_off_outlined,
                titre: 'Chargement impossible',
                message:
                    widget.controller.messageErreur ??
                    'Réessaie dans un instant.',
                action: FilledButton.icon(
                  onPressed: widget.controller.occupe
                      ? null
                      : widget.controller.charger,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ),
              EtatChargement.empty || EtatChargement.success =>
                _onglet == 0
                    ? _suivi()
                    : BilanView(controller: widget.controller),
            },
          ),
        ),
      ),
      floatingActionButton:
          widget.controller.etat == EtatChargement.error ||
              widget.controller.etat == EtatChargement.loading
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.controller.occupe ? null : _ajouter,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (index) {
          FocusScope.of(context).unfocus();
          setState(() => _onglet = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Suivi'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Bilan',
          ),
        ],
      ),
    ),
  );

  Widget _suivi() {
    final controller = widget.controller;
    final visibles = controller.visibles;
    // Un seul défilement conserve recherche, filtres et cartes accessibles
    // lorsque le clavier ou une grande taille de texte réduit la hauteur.
    return RefreshIndicator(
      onRefresh: controller.charger,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: visibles.isEmpty ? 2 : visibles.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes candidatures',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Toutes tes démarches, au même endroit.'),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('recherche'),
                  initialValue: controller.recherche,
                  onChanged: controller.rechercher,
                  decoration: const InputDecoration(
                    hintText: 'Entreprise ou poste',
                    labelText: 'Rechercher',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tous'),
                          selected: controller.filtre == null,
                          onSelected: (_) => controller.filtrer(null),
                        ),
                      ),
                      for (final statut in Statut.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(statut.libelle),
                            selected: controller.filtre == statut,
                            onSelected: (_) => controller.filtrer(statut),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${visibles.length} résultat${visibles.length == 1 ? '' : 's'} sur '
                  '${controller.elements.length} candidature${controller.elements.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 12),
              ],
            );
          }
          if (visibles.isEmpty) {
            return MessageEtat(
              icone: Icons.work_outline,
              titre: controller.elements.isEmpty
                  ? 'Ta prochaine piste commence ici'
                  : 'Aucune candidature trouvée',
              message: controller.elements.isEmpty
                  ? 'Appuie sur Ajouter pour suivre ta première candidature.'
                  : 'Modifie la recherche ou choisis un autre statut.',
            );
          }
          final c = visibles[index - 1];
          return Card(
            key: ValueKey(c.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                c.poste,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(c.entreprise),
                  BadgeStatut(statut: c.statut),
                  if (c.prochaineRelance != null)
                    Text('Relance le ${dateCourte(c.prochaineRelance!)}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      CandidatureDetailPage(controller: controller, id: c.id!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
