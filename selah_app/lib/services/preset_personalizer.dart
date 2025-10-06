import '../models/plan_preset.dart';

class PresetPersonalizer {
  static List<PlanPreset> personalize({
    required List<PlanPreset> all,
    required String experience,
    required String goal,
  }) {
    final out = <PlanPreset>[];
    
    // Pour les nouveaux convertis, prioriser les plans courts et accessibles
    if (experience == 'Nouveau converti') {
      out.addAll(all.where((p) => 
        ['light_15', 'genesis_1_25_14d', 'psalms_40'].contains(p.slug)
      ));
    }
    
    // Pour la discipline quotidienne, prioriser les Psaumes et Proverbes
    if (goal == 'Discipline quotidienne') {
      out.addAll(all.where((p) => 
        ['proverbs_31', 'psalms_40'].contains(p.slug)
      ));
    }
    
    // Pour "Mieux prier", prioriser les Psaumes
    if (goal == 'Mieux prier') {
      out.addAll(all.where((p) => 
        ['psalms_40', 'proverbs_31'].contains(p.slug)
      ));
    }
    
    // Pour "Approfondir la Parole", prioriser les plans plus longs
    if (goal == 'Approfondir la Parole') {
      out.addAll(all.where((p) => 
        ['genesis_1_25_14d', 'whole_bible_365'].contains(p.slug)
      ));
    }
    
    // Pour "Grandir dans la foi", prioriser les plans équilibrés
    if (goal == 'Grandir dans la foi') {
      out.addAll(all.where((p) => 
        ['nt_90', 'bible_180', 'psalms_40'].contains(p.slug)
      ));
    }
    
    // Ajouter les autres plans qui ne sont pas déjà dans la liste
    out.addAll(all.where((p) => !out.any((x) => x.slug == p.slug)));
    
    return out;
  }
}
