import 'dart:io';
import 'package:flutter/material.dart';
import 'intelligent_alarm_service.dart';
import 'ios_alarm_service.dart';

class CrossPlatformAlarmService {
  static Future<void> scheduleAlarm(TimeOfDay time) async {
    if (Platform.isAndroid) {
      // Utiliser le système Android existant
      await IntelligentAlarmService.instance.scheduleAlarm(time);
    } else if (Platform.isIOS) {
      // Utiliser le nouveau système iOS
      await IOSAlarmService.instance.scheduleAlarm(time);
    }
  }
  
  static Future<void> cancelAllAlarms() async {
    if (Platform.isAndroid) {
      await IntelligentAlarmService.instance.cancelAllAlarms();
    } else if (Platform.isIOS) {
      await IOSAlarmService.instance.cancelAllAlarms();
    }
  }
  
  static Future<bool> isAlarmScheduled() async {
    if (Platform.isAndroid) {
      return await IntelligentAlarmService.instance.isAlarmScheduled();
    } else if (Platform.isIOS) {
      return await IOSAlarmService.instance.isAlarmScheduled();
    }
    return false;
  }
}





