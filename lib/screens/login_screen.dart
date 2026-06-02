import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../home.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthService _authService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are offline. Connect to internet to login."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user;
      if (_isLoginMode) {
        user = await _authService.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        user = await _authService.signupWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (user != null && mounted) {
        if (_isLoginMode) {
          // Login mode - go to home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(authService: _authService),
            ),
          );
        } else {
          // Signup mode - go to email verification
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  VerifyEmailScreen(email: _emailController.text.trim()),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Authentication failed";
      if (e.code == 'user-not-found') {
        errorMessage = "User not found";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "Email already in use";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are offline. Connect to internet to reset password."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email to reset password"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link sent! Please check your inbox."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = "Error sending reset email";
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Email Authentication"),
      ),
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
                    const SizedBox(height: 40),

                    /// Header
                    const Text(
                      "Welcome to Student Notes",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginMode ? "Login to continue" : "Create an account",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    /// Email Field
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading && _isOnline,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Password Field
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading && _isOnline,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    if (_isLoginMode) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading || !_isOnline ? null : _handleForgotPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    /// Email Login Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading || !_isOnline
                            ? null
                            : _handleEmailAuth,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLoginMode ? "Login" : "Sign Up",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Toggle Login/Signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode
                              ? "Don't have an account? "
                              : "Already have an account? ",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  setState(() => _isLoginMode = !_isLoginMode);
                                  _emailController.clear();
                                  _passwordController.clear();
                                },
                          child: Text(
                            _isLoginMode ? "Sign Up" : "Login",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
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
