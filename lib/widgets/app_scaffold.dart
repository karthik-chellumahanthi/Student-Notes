import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/welcome_screen.dart';
import 'notification_icon.dart';
import '../services/theme_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onBottomNavTap;
  final Function(int)? onDrawerNavigate;
  final bool showDrawer;
  final bool showBottomNav;

  const AppScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    required this.onBottomNavTap,
    this.onDrawerNavigate,
    this.showDrawer = true,
    this.showBottomNav = true,
  });

  void _showFeedbackDialog(BuildContext context) {
    // First ask if user is enjoying the app
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you enjoying the app?'),
          content: const Text(
            'We would love to hear your thoughts about Student Notes!',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                // Negative response - show feedback form
                _showInAppFeedbackDialog(context);
              },
              child: const Text('No', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(context).pop();
                // Positive response - redirect to Play Store
                _openPlayStore(context);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openPlayStore(BuildContext context) async {
    final url = Uri.parse(RemoteConfigService.playStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the store link. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInAppFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    String selectedRating = '5';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Share Your Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate Your Experience',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRating = i.toString();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.star,
                                size: 32,
                                color: int.parse(selectedRating) >= i
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us what you think...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                  ),
                  onPressed: () async {
                    if (feedbackController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your feedback'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      await FirebaseFirestore.instance.collection('feedback').add({
                        'rating': int.parse(selectedRating),
                        'feedback': feedbackController.text.trim(),
                        'userId': user?.uid ?? 'anonymous',
                        'userEmail': user?.email ?? 'anonymous',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback! Rating: $selectedRating⭐',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to send feedback. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to logout? You will need to login again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = AuthService();
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.menu_book),
            SizedBox(width: 8),
            Text("Student Notes"),
          ],
        ),
        actions: const [NotificationIcon(), SizedBox(width: 8)],
      ),
      drawer: showDrawer
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF6B7280)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(
                          Icons.account_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Pop all nested screens to get back to HomeScreen
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // Update the current index to home
                      if (onDrawerNavigate != null) {
                        onDrawerNavigate!(0);
                      } else {
                        onBottomNavTap(0);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Downloads'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Pop all nested screens first, then navigate to home with downloads tab
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      if (onDrawerNavigate != null) {
                        onDrawerNavigate!(1);
                      } else {
                        onBottomNavTap(1);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: const Text('More'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Pop all nested screens first, then navigate to home with more tab
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      if (onDrawerNavigate != null) {
                        onDrawerNavigate!(2);
                      } else {
                        onBottomNavTap(2);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Pop all nested screens first, then navigate to home with profile tab
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      if (onDrawerNavigate != null) {
                        onDrawerNavigate!(3);
                      } else {
                        onBottomNavTap(3);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Theme.of(context).brightness == Brightness.dark 
                          ? Icons.dark_mode 
                          : Icons.light_mode
                    ),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (value) {
                        ThemeService.toggleTheme(value);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Feedback'),
                    onTap: () {
                      Navigator.pop(context);
                      _showFeedbackDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmationDialog(context);
                    },
                  ),
                ],
              ),
            )
          : null,
      body: body,
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              selectedItemColor: const Color(0xFF6B7280),
              unselectedItemColor: Colors.grey[400],
              onTap: onBottomNavTap,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.download),
                  label: "Downloads",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.apps), label: "More"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            )
          : null,
    );
  }
}
