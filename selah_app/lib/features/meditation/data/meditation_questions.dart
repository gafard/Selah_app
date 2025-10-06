import 'meditation_models.dart';

/// Banque de questions pour la méditation
class MeditationQuestions {
  static const List<MeditationPack> packs = [
    // Pack A - Processus de Découverte
    MeditationPack(
      packId: 'discovery_process',
      title: 'Processus de Découverte',
      description: 'Demander/Chercher/Frapper',
      mcq: [
        // Étape Demander
        McqQuestion(
          id: 'ask_characters',
          title: 'Quels sont les personnages dans ce passage ?',
          choices: [
            'Jésus et ses disciples',
            'Un personnage principal et des témoins',
            'Plusieurs personnages avec des rôles différents',
            'Des personnages anonymes',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'ask_actions',
          title: 'Quelles actions principales sont décrites ?',
          choices: [
            'Une conversation',
            'Un miracle ou un signe',
            'Un enseignement',
            'Un déplacement ou voyage',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'ask_details',
          title: 'Quels détails marquants retiennent ton attention ?',
          choices: [
            'Les paroles prononcées',
            'Le lieu ou le contexte',
            'Les réactions des personnes',
            'Les symboles ou métaphores',
          ],
          allowOther: true,
        ),
        
        // Étape Chercher
        McqQuestion(
          id: 'seek_emotions',
          title: 'Quelles émotions les personnages ressentent-ils probablement ?',
          choices: [
            'Joie et reconnaissance',
            'Surprise et étonnement',
            'Peur et inquiétude',
            'Confusion et questionnement',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'seek_choices',
          title: 'Quels choix ou alternatives s\'offrent aux personnages ?',
          choices: [
            'Croire ou douter',
            'Obéir ou désobéir',
            'Parler ou se taire',
            'Agir ou attendre',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'seek_why',
          title: 'Pourquoi les personnages font-ils ces choix ?',
          choices: [
            'Par foi et confiance',
            'Par peur ou pression',
            'Par amour et compassion',
            'Par obéissance à Dieu',
          ],
          allowOther: true,
        ),
        
        // Étape Frapper
        McqQuestion(
          id: 'knock_actions',
          title: 'Quelles bonnes actions puis-je identifier dans ce passage ?',
          choices: [
            'La foi et la confiance',
            'L\'obéissance et la soumission',
            'L\'amour et la compassion',
            'La persévérance et la patience',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'knock_god',
          title: 'Ce que j\'apprends sur Dieu dans ce passage :',
          choices: [
            'Sa puissance et sa majesté',
            'Son amour et sa grâce',
            'Sa sagesse et sa justice',
            'Sa fidélité et sa bonté',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'knock_neighbor',
          title: 'Ce que j\'apprends sur le prochain :',
          choices: [
            'La valeur de chaque personne',
            'L\'importance de la communauté',
            'Le besoin de compassion',
            'La responsabilité de servir',
          ],
          allowOther: true,
        ),
      ],
      free: [
        FreeQuestion(
          id: 'discovery_summary',
          prompt: 'Rédige en 3-5 phrases ce que tu retiens de cette méditation',
          minLines: 5,
          maxLength: 500,
        ),
      ],
    ),
    
    // Pack B - Lecture Quotidienne
    MeditationPack(
      packId: 'daily_reading',
      title: 'Lecture Quotidienne',
      description: '8 questions d\'étude',
      mcq: [
        McqQuestion(
          id: 'god_revelation',
          title: 'Qu\'est-ce que ce passage révèle sur Dieu ?',
          choices: [
            'Sa nature et son caractère',
            'Ses attributs et ses qualités',
            'Sa relation avec l\'humanité',
            'Ses promesses et ses plans',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'example_follow',
          title: 'Quel exemple puis-je suivre dans ce passage ?',
          choices: [
            'La foi et la confiance',
            'L\'obéissance et la soumission',
            'L\'amour et le service',
            'La persévérance et la patience',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'command_obey',
          title: 'Y a-t-il un ordre à obéir dans ce passage ?',
          choices: [
            'Un commandement direct',
            'Une invitation à suivre',
            'Un principe à appliquer',
            'Un appel à l\'action',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'promise_believe',
          title: 'Quelle promesse puis-je croire dans ce passage ?',
          choices: [
            'Une promesse de bénédiction',
            'Une promesse de protection',
            'Une promesse de guidance',
            'Une promesse de pardon',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'warning_heed',
          title: 'Y a-t-il un avertissement à prendre en compte ?',
          choices: [
            'Un avertissement contre le péché',
            'Un avertissement contre l\'orgueil',
            'Un avertissement contre l\'incrédulité',
            'Un avertissement contre l\'indifférence',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'truth_apply',
          title: 'Quelle vérité puis-je appliquer à ma vie ?',
          choices: [
            'Une vérité sur la foi',
            'Une vérité sur l\'amour',
            'Une vérité sur l\'espérance',
            'Une vérité sur la sagesse',
          ],
          allowOther: true,
        ),
        McqQuestion(
          id: 'parallel_references',
          title: 'Y a-t-il des références parallèles qui me viennent à l\'esprit ?',
          choices: [
            'D\'autres passages bibliques',
            'Des histoires similaires',
            'Des enseignements complémentaires',
            'Des promesses liées',
          ],
          allowOther: true,
        ),
      ],
      free: [
        FreeQuestion(
          id: 'key_verse',
          prompt: 'Verset qui me frappe — recopie-le et explique pourquoi',
          minLines: 3,
          maxLength: 300,
        ),
      ],
    ),
  ];

  /// Récupère un pack par son ID
  static MeditationPack? getPackById(String packId) {
    try {
      return packs.firstWhere((pack) => pack.packId == packId);
    } catch (e) {
      return null;
    }
  }

  /// Récupère un pack par l'option (1 ou 2)
  static MeditationPack? getPackByOption(int option) {
    if (option == 1) {
      return packs.firstWhere((pack) => pack.packId == 'discovery_process');
    } else if (option == 2) {
      return packs.firstWhere((pack) => pack.packId == 'daily_reading');
    }
    return null;
  }

  /// Récupère tous les packs disponibles
  static List<MeditationPack> getAllPacks() {
    return packs;
  }
}
