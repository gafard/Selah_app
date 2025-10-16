import 'anchored_doctrine_base.dart';
import 'modules.dart';

class DoctrinePipeline {
  final List<DoctrineModule> modules;
  DoctrinePipeline(this.modules);

  /// Tous les modules activés
  factory DoctrinePipeline.defaultModules() => DoctrinePipeline([
    FearOfGodDoctrine(),
    HolinessDoctrine(),
    HumilityDoctrine(),
    GraceDoctrine(),
    PrayerDoctrine(),
    WisdomDoctrine(),
  ]);

  List<Map<String, dynamic>> apply(
    List<Map<String, dynamic>> plan, {
    required DoctrineContext context,
  }) {
    print('🕊️ DoctrinePipeline: Application de ${modules.length} modules sur ${plan.length} jours');
    
    var out = plan;
    for (final m in modules) {
      print('🕊️ DoctrinePipeline: Application du module ${m.id}');
      out = m.apply(out, context);
    }
    
    final totalDoctrinalDays = out.where((d) => (d['doctrine'] ?? {}).isNotEmpty).length;
    print('🕊️ DoctrinePipeline: $totalDoctrinalDays jours avec doctrine sur ${out.length} jours');
    
    return out;
  }
}
