import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceStatus { present, absent, holiday, none }

class AttendanceService {
  static const String _key = 'daily_attendance_data';

  // Map of "YYYY-MM-DD" to String status
  static Future<Map<String, AttendanceStatus>> getAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_key);
    
    if (dataString == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(dataString);
      Map<String, AttendanceStatus> result = {};
      
      decoded.forEach((key, value) {
        result[key] = AttendanceStatus.values.firstWhere(
          (e) => e.toString() == value,
          orElse: () => AttendanceStatus.none,
        );
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveAttendanceData(Map<String, AttendanceStatus> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, String> toSave = {};
    data.forEach((key, value) {
      if (value != AttendanceStatus.none) {
        toSave[key] = value.toString();
      }
    });

    await prefs.setString(_key, jsonEncode(toSave));
  }

  static String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
