import 'package:flutter/material.dart';

import '../models/candidature.dart';
import '../state/candidature_controller.dart';
import 'widgets/presentation.dart';

class CandidatureFormPage extends StatefulWidget {
  const CandidatureFormPage({
    super.key,
    required this.controller,
    this.initiale,
  });
  final CandidatureController controller;
  final Candidature? initiale;

  @override
  State<CandidatureFormPage> createState() => _CandidatureFormPageState();
}

class _CandidatureFormPageState extends State<CandidatureFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _entreprise;
  late final TextEditingController _poste;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late Statut _statut;
  DateTime? _relance;
  bool _enregistrementEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final c = widget.initiale;
    _entreprise = TextEditingController(text: c?.entreprise ?? '');
    _poste = TextEditingController(text: c?.poste ?? '');
    _url = TextEditingController(text: c?.url ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _statut = c?.statut ?? Statut.brouillon;
    _relance = c?.prochaineRelance;
  }

  @override
  void dispose() {
    _entreprise.dispose();
    _poste.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _relance ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      helpText: 'Date de relance',
    );
    if (date != null && mounted) setState(() => _relance = date);
  }

  Future<void> _sauvegarder() async {
    if (_enregistrementEnCours ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enregistrementEnCours = true;
      _erreur = null;
    });
    final maintenant = DateTime.now();
    final candidature = Candidature(
      id: widget.initiale?.id,
      entreprise: _entreprise.text.trim(),
      poste: _poste.text.trim(),
      statut: _statut,
      url: _url.text.trim(),
      notes: _notes.text.trim(),
      dateCreation: widget.initiale?.dateCreation ?? maintenant,
      dateModification: maintenant,
      prochaineRelance: _relance,
    );
    try {
      await widget.controller.enregistrer(candidature);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initiale == null
                ? 'Candidature ajoutée.'
                : 'Candidature modifiée.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur =
              'Enregistrement impossible. Tes champs sont conservés, réessaie.',
        );
      }
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_enregistrementEnCours,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initiale == null
              ? 'Nouvelle candidature'
              : 'Modifier la candidature',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Les champs marqués * sont obligatoires.'),
                    const SizedBox(height: 20),
                    if (_erreur != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _erreur!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('entreprise'),
                      controller: _entreprise,
                      enabled: !_enregistrementEnCours,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Entreprise *',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indique le nom de l’entreprise.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('poste'),
                      controller: _poste,
                      enabled: !_enregistrementEnCours,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Poste *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indique le poste recherché.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Statut>(
                      initialValue: _statut,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: [
                        for (final s in Statut.values)
                          DropdownMenuItem(value: s, child: Text(s.libelle)),
                      ],
                      onChanged: _enregistrementEnCours
                          ? null
                          : (s) {
                              if (s != null) setState(() => _statut = s);
                            },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('url'),
                      controller: _url,
                      enabled: !_enregistrementEnCours,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Lien de l’offre',
                        hintText: 'https://…',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        return uri != null &&
                                uri.host.isNotEmpty &&
                                (uri.scheme == 'https' || uri.scheme == 'http')
                            ? null
                            : 'Indique une adresse http:// ou https:// valide.';
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Prochaine relance'),
                      subtitle: Text(
                        _relance == null
                            ? 'Facultative'
                            : dateCourte(_relance!),
                      ),
                      onTap: _enregistrementEnCours ? null : _choisirDate,
                      trailing: _relance == null
                          ? const Icon(Icons.chevron_right)
                          : IconButton(
                              tooltip: 'Retirer la date',
                              onPressed: _enregistrementEnCours
                                  ? null
                                  : () => setState(() => _relance = null),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('notes'),
                      controller: _notes,
                      enabled: !_enregistrementEnCours,
                      minLines: 3,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('enregistrer'),
                      onPressed: _enregistrementEnCours ? null : _sauvegarder,
                      icon: _enregistrementEnCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _enregistrementEnCours
                            ? 'Enregistrement…'
                            : 'Enregistrer',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
