import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/notifications_screen.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  DateTime? _lastReadTimestamp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLastReadTime();
  }

  Future<void> _loadLastReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    
    // If first launch (never opened notifications before), 
    // set the last read time to right now so they don't get red badges for old notifications.
    if (!prefs.containsKey('lastReadTimestamp')) {
      final now = DateTime.now();
      await prefs.setInt('lastReadTimestamp', now.millisecondsSinceEpoch);
      setState(() {
        _lastReadTimestamp = now;
        _isLoading = false;
      });
    } else {
      setState(() {
        _lastReadTimestamp = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('lastReadTimestamp')!);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: null,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // Only fetch the 10 most recent to save data and read costs
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        
        if (snapshot.hasData && _lastReadTimestamp != null) {
          // Count how many of these 10 recent notifications are newer than the last time they looked
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('createdAt') && data['createdAt'] != null) {
              final timestamp = data['createdAt'] as Timestamp;
              if (timestamp.toDate().isAfter(_lastReadTimestamp!)) {
                unreadCount++;
              }
            }
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: Colors.amber[800], // Dark yellow / Gold
                size: 28,
              ),
              onPressed: () async {
                // When clicked, update last read timestamp to right now
                final prefs = await SharedPreferences.getInstance();
                final now = DateTime.now();
                await prefs.setInt('lastReadTimestamp', now.millisecondsSinceEpoch);
                setState(() {
                  _lastReadTimestamp = now;
                });

                // Navigate to the notifications screen
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                }
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
