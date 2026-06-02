import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../home.dart';

class WelcomeScreen extends StatefulWidget {
  final AuthService? authService;

  const WelcomeScreen({super.key, this.authService});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late AuthService _authService;
  bool _isLoading = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _checkInitialConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _checkInitialConnectivity() async {
    final isOnline = await _authService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  void _setupConnectivityListener() {
    _authService.getConnectivityStream().listen((results) {
      final isOnline =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  Future<void> _handleGoogleLogin() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are offline. Connect to internet to login."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.loginWithGoogle();

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(authService: _authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google login failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),

                    /// Header
                    const Text(
                      "Welcome to Student Notes",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Get access to all study materials and notes",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 80),

                    /// Continue with Email Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading || !_isOnline
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LoginScreen(authService: _authService),
                                  ),
                                );
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Continue with Email",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Continue with Google Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading || !_isOnline
                            ? null
                            : _handleGoogleLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.account_circle);
                              },
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You are offline. Connect to internet to login.",
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
