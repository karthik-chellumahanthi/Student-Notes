import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _selectedNotesRegulation;
  bool _isOnline = true;
  final AuthService _authService = AuthService();
  
  int _unreadNotifications = 0;
  StreamSubscription? _notificationsSubscription;
  DateTime? _lastReadTimestamp;

  int get currentIndex => _currentIndex;
  String? get selectedNotesRegulation => _selectedNotesRegulation;
  bool get isOnline => _isOnline;
  int get unreadNotifications => _unreadNotifications;

  HomeProvider({int initialTabIndex = 0}) {
    _currentIndex = initialTabIndex;
    _init();
  }

  Future<void> _init() async {
    await _loadSavedRegulations();
    await _checkInitialConnectivity();
    _setupConnectivityListener();
    await _initNotifications();
  }

  Future<void> _initNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('lastReadTimestamp')) {
      final now = DateTime.now();
      await prefs.setInt('lastReadTimestamp', now.millisecondsSinceEpoch);
      _lastReadTimestamp = now;
    } else {
      _lastReadTimestamp = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('lastReadTimestamp')!);
    }

    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      if (_lastReadTimestamp != null) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data.containsKey('createdAt') && data['createdAt'] != null) {
            final timestamp = data['createdAt'] as Timestamp;
            if (timestamp.toDate().isAfter(_lastReadTimestamp!)) {
              count++;
            }
          }
        }
      }
      _unreadNotifications = count;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to notifications: $e");
    });
  }

  Future<void> markNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('lastReadTimestamp', now.millisecondsSinceEpoch);
    _lastReadTimestamp = now;
    _unreadNotifications = 0;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> setSelectedNotesRegulation(String? regulation) async {
    _selectedNotesRegulation = regulation;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (regulation != null) {
        await prefs.setString('selectedNotesRegulation', regulation);
      } else {
        await prefs.remove('selectedNotesRegulation');
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadSavedRegulations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedNotesRegulation = prefs.getString('selectedNotesRegulation');
      notifyListeners();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _checkInitialConnectivity() async {
    _isOnline = await _authService.hasInternetConnection();
    if (!_isOnline && _currentIndex != 1) {
      _currentIndex = 1; // Go to downloads
    }
    notifyListeners();
  }

  void _setupConnectivityListener() {
    _authService.getConnectivityStream().listen((results) {
      final isOnline = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      _isOnline = isOnline;
      if (!isOnline && _currentIndex != 1) {
        _currentIndex = 1;
      }
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
