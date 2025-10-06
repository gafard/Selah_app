import 'package:flutter/services.dart' show rootBundle;
import '../models/plan_preset.dart';

class PlanPresetsRepo {
  static Future<List<PlanPreset>> loadFromAsset() async {
    final raw = await rootBundle.loadString('assets/presets/presets.json');
    return PlanPreset.listFromJson(raw);
  }
}

