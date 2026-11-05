/// Valeurs persistées stables : les libellés de l'interface peuvent évoluer.
enum Statut {
  brouillon('Brouillon'),
  envoyee('Envoyée'),
  entretien('Entretien'),
  offre('Offre'),
  refusee('Refusée');

  const Statut(this.libelle);
  final String libelle;

  static Statut depuisStockage(String? valeur) => Statut.values.firstWhere(
    (statut) => statut.name == valeur,
    orElse: () => Statut.brouillon,
  );
}

class Candidature {
  const Candidature({
    this.id,
    required this.entreprise,
    required this.poste,
    this.statut = Statut.brouillon,
    required this.dateCreation,
    required this.dateModification,
    this.notes = '',
    this.url = '',
    this.prochaineRelance,
  });

  /// Null avant la première insertion ; SQLite attribue ensuite un identifiant.
  final int? id;
  final String entreprise;
  final String poste;
  final Statut statut;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String notes;
  final String url;
  final DateTime? prochaineRelance;

  Map<String, Object?> toDatabase() => {
    if (id != null) 'id': id,
    'entreprise': entreprise,
    'poste': poste,
    'status': statut.name,
    'notes': notes,
    'url': url,
    'date_creation': dateCreation.toIso8601String(),
    'date_modification': dateModification.toIso8601String(),
    'prochaine_relance': prochaineRelance?.toIso8601String(),
  };

  factory Candidature.fromDatabase(Map<String, Object?> ligne) => Candidature(
    id: ligne['id'] as int?,
    entreprise: ligne['entreprise'] as String,
    poste: ligne['poste'] as String,
    statut: Statut.depuisStockage(ligne['status'] as String?),
    notes: ligne['notes'] as String? ?? '',
    url: ligne['url'] as String? ?? '',
    dateCreation: DateTime.parse(ligne['date_creation'] as String),
    dateModification: DateTime.parse(
      (ligne['date_modification'] ?? ligne['date_creation']) as String,
    ),
    prochaineRelance: ligne['prochaine_relance'] == null
        ? null
        : DateTime.parse(ligne['prochaine_relance'] as String),
  );
}
