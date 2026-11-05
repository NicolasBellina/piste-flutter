import 'package:flutter/foundation.dart';

import '../data/candidature_repository.dart';
import '../models/candidature.dart';

enum EtatChargement { loading, success, empty, error }

class CandidatureController extends ChangeNotifier {
  CandidatureController(this.repository);
  final CandidatureRepository repository;
  List<Candidature> _elements = [];
  EtatChargement etat = EtatChargement.loading;
  String? messageErreur;
  String _recherche = '';
  Statut? _filtre;
  bool _occupe = false;
  bool _detruit = false;

  bool get occupe => _occupe;
  String get recherche => _recherche;
  Statut? get filtre => _filtre;
  List<Candidature> get elements => List.unmodifiable(_elements);
  List<Candidature> get visibles {
    final query = _recherche.trim().toLowerCase();
    return _elements
        .where(
          (c) =>
              (_filtre == null || c.statut == _filtre) &&
              '${c.entreprise} ${c.poste}'.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  int nombre(Statut statut) =>
      _elements.where((c) => c.statut == statut).length;
  double proportion(Statut statut) =>
      _elements.isEmpty ? 0 : nombre(statut) / _elements.length;
  Candidature? parId(int id) {
    for (final c in _elements) {
      if (c.id == id) return c;
    }
    return null;
  }

  void rechercher(String valeur) {
    _recherche = valeur;
    _notifier();
  }

  void filtrer(Statut? statut) {
    _filtre = statut;
    _notifier();
  }

  Future<void> charger() async {
    if (_occupe || _detruit) return;
    _occupe = true;
    etat = EtatChargement.loading;
    messageErreur = null;
    _notifier();
    try {
      await _relire();
    } catch (_) {
      _elements = [];
      etat = EtatChargement.error;
      messageErreur = 'Impossible de charger les candidatures. Réessaie.';
    } finally {
      _occupe = false;
      _notifier();
    }
  }

  Future<void> _relire() async {
    final elements = await repository.toutes();
    if (_detruit) return;
    _elements = elements;
    etat = elements.isEmpty ? EtatChargement.empty : EtatChargement.success;
    messageErreur = null;
  }

  Future<void> enregistrer(Candidature candidature) =>
      _modifier(() => repository.enregistrer(candidature));

  Future<void> supprimer(int id) => _modifier(() => repository.supprimer(id));

  Future<void> _modifier(Future<void> Function() operation) async {
    if (_occupe || _detruit) {
      throw StateError('Une opération est déjà en cours.');
    }
    _occupe = true;
    messageErreur = null;
    _notifier();
    try {
      await operation();
      // Une écriture confirmée ne doit jamais être répétée si seule la relecture
      // échoue : le formulaire peut fermer et l'accueil propose Réessayer.
      try {
        await _relire();
      } catch (_) {
        _elements = [];
        etat = EtatChargement.error;
        messageErreur =
            'Modification enregistrée, mais la liste ne peut pas être '
            'rechargée. Réessaie le chargement.';
      }
    } catch (_) {
      messageErreur =
          'Modification impossible. Les données saisies sont conservées.';
      rethrow;
    } finally {
      _occupe = false;
      _notifier();
    }
  }

  void _notifier() {
    if (!_detruit) notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
