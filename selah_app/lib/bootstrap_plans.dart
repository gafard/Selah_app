import 'package:hive_flutter/hive_flutter.dart';

Future<(Box, Box)> openPlanCaches() async {
  final plans = await Hive.openBox('plans');
  final planDays = await Hive.openBox('plan_days');
  return (plans, planDays);
}
