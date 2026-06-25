import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String id;
  final String name;
  final String type; // 'note'
  final String filePath;
  final String subject;
  final DateTime openedAt;

  HistoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.filePath,
    this.subject = '',
    required this.openedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'filePath': filePath,
      'subject': subject,
      'openedAt': openedAt.toIso8601String(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      filePath: json['filePath'] as String,
      subject: json['subject'] as String? ?? '',
      openedAt: DateTime.parse(json['openedAt'] as String),
    );
  }
}

class HistoryService {
  static const String _historyKey = 'file_history';
  static const int _maxHistoryItems = 50;

  final SharedPreferences _prefs;

  HistoryService(this._prefs);

  static Future<HistoryService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return HistoryService(prefs);
  }

  Future<void> addToHistory({
    required String id,
    required String name,
    required String type, // 'note'
    required String filePath,
    String subject = '',
  }) async {
    try {
      final history = await getHistory();

      // Remove if already exists to move it to top
      history.removeWhere((item) => item.id == id);

      // Add new item at the beginning
      final newItem = HistoryItem(
        id: id,
        name: name,
        type: type,
        filePath: filePath,
        subject: subject,
        openedAt: DateTime.now(),
      );

      history.insert(0, newItem);

      // Keep only the latest items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save to SharedPreferences
      final jsonList = history
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await _prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      // Error saving history, silently fail
    }
  }

  Future<List<HistoryItem>> getHistory() async {
    try {
      final jsonList = _prefs.getStringList(_historyKey) ?? [];
      return jsonList
          .map((json) => HistoryItem.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // Error loading history, return empty list
      return [];
    }
  }

  Future<List<HistoryItem>> getNoteHistory() async {
    final history = await getHistory();
    return history.where((item) => item.type == 'note').toList();
  }


  Future<void> removeFromHistory(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);

      final jsonList = history
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await _prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      // Error removing history item, silently fail
    }
  }

  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (e) {
      // Error clearing history, silently fail
    }
  }

  Future<void> clearNoteHistory() async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => item.type == 'note');

      final jsonList = history
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await _prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      // Error clearing note history, silently fail
    }
  }

}
