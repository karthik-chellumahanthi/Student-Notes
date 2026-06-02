import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculationRecord {
  final String id;
  final String type; // 'CGPA', 'SGPA', 'Percentage'
  final String details;
  final String result;
  final DateTime date;

  CalculationRecord({
    required this.id,
    required this.type,
    required this.details,
    required this.result,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'details': details,
        'result': result,
        'date': date.toIso8601String(),
      };

  factory CalculationRecord.fromJson(Map<String, dynamic> json) =>
      CalculationRecord(
        id: json['id'],
        type: json['type'],
        details: json['details'],
        result: json['result'],
        date: DateTime.parse(json['date']),
      );
}

class CalculatorHistoryService {
  static const String _key = 'calculator_history';

  static Future<void> addRecord(CalculationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    history.insert(0, jsonEncode(record.toJson()));
    // Keep last 100
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }
    await prefs.setStringList(_key, history);
  }

  static Future<List<CalculationRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    return history.map((e) => CalculationRecord.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
