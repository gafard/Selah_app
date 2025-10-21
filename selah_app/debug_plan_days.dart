import 'package:hive_flutter/hive_flutter.dart';
import 'lib/models/plan_models.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('plans');
  await Hive.openBox('plan_days');
  
  const planId = '88b09cc8-8a59-4c88-9e95-7541ac3c997f';
  
  // Récupérer le plan actif
  final planBox = Hive.box('plans');
  final planData = planBox.get('active_plan');
  print('📋 Plan actif: $planData');
  
  // Récupérer les jours du plan
  final daysBox = Hive.box('plan_days');
  final daysData = daysBox.get('days:$planId:1:0');
  
  if (daysData == null) {
    print('❌ Aucun jour trouvé pour le plan $planId');
    return;
  }
  
  print('📅 Jours du plan (${daysData.length} jours):');
  
  for (int i = 0; i < daysData.length && i < 3; i++) {
    final dayData = daysData[i] as Map<String, dynamic>;
    final day = PlanDay.fromJson(dayData);
    
    print('\n📖 Jour ${day.dayIndex}:');
    print('   Date: ${day.date}');
    print('   Lectures:');
    
    for (final reading in day.readings) {
      print('     - ${reading.book} ${reading.range}');
    }
  }
}



