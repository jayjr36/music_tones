import 'package:flutter/services.dart';
import 'dart:io';

class RingtoneHelper {
  static const MethodChannel _channel = MethodChannel("custom_ringtone");

  // Set ringtone for Android
  static Future<bool> setRingtone(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final bool result = await _channel.invokeMethod("setRingtone", {"filePath": filePath});
        return result;
      } else if (Platform.isIOS) {
        final bool result = await _channel.invokeMethod("saveRingtone", {"filePath": filePath});
        return result;
      }
      return false;
    } catch (e) {
      print("Error setting ringtone: $e");
      return false;
    }
  }
}
