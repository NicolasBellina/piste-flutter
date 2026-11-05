import 'dart:io';

import 'package:piste/models/candidature.dart';

/// Mini-exercice de la page 5 : deux objets, cinq statuts et null safety.
void main() {
  final maintenant = DateTime.now();
  final candidatures = [
    Candidature(
      entreprise: 'Nexora',
      poste: 'Développeur Flutter',
      statut: Statut.envoyee,
      dateCreation: maintenant,
      dateModification: maintenant,
    ),
    Candidature(
      entreprise: 'Asteria',
      poste: 'Développeur mobile',
      statut: Statut.entretien,
      dateCreation: maintenant,
      dateModification: maintenant,
      prochaineRelance: maintenant.add(const Duration(days: 7)),
    ),
  ];
  for (final c in candidatures) {
    stdout.writeln('${c.entreprise} : ${c.poste} (${c.statut.libelle})');
  }
  // entreprise, poste et dates sont requis et non nullables.
  // id est null avant insertion ; prochaineRelance est facultative.
  // notes et url restent non nullables grâce à leur valeur par défaut vide.
}
