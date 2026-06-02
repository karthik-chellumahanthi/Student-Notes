import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../home.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _PopScope extends StatelessWidget {
  final Widget child;
  final VoidCallback onWillPop;

  const _PopScope({required this.child, required this.onWillPop});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: child,
    );
  }
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isCheckingVerification = false;
  bool _canResendEmail = true;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmailOnInit();
    
    // Auto-check every 3 seconds
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _autoCheckEmailVerification(),
    );
  }

  Future<void> _sendVerificationEmailOnInit() async {
    try {
      final authService = AuthService();
      await authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sending email: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isCheckingVerification = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;

        if (isVerified && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email verified successfully! Redirecting..."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        } else if (!isVerified && mounted) {
          setState(() => _isCheckingVerification = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Email not verified yet. Please check your email and click the verification link.",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking verification: $e")),
        );
      }
    }
  }

  Future<void> _autoCheckEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          _autoCheckTimer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email automatically verified! Redirecting..."),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      // Silently ignore errors during auto-check
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please wait $_resendCountdown seconds before resending",
            ),
          ),
        );
      }
      return;
    }

    try {
      final authService = AuthService();
      await authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _canResendEmail = false;
          _resendCountdown = 60;
        });

        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _resendCountdown--;
            if (_resendCountdown <= 0) {
              _canResendEmail = true;
              timer.cancel();
            }
          });
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBackButton() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out?"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted && context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Verify Email"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackButton,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                "Verify Your Email",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "We've sent a verification link to:\n\n${widget.email}\n\nPlease click the link in your email to verify your account.\n\nThe app will automatically redirect once verified.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "If you do not receive the email, kindly check your spam folder.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _isCheckingVerification
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _checkEmailVerification,
                            child: const Text(
                              "Check Verification",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _canResendEmail
                                ? _resendVerificationEmail
                                : null,
                            child: Text(
                              _canResendEmail
                                  ? "Resend Verification Email"
                                  : "Resend Email (${_resendCountdown}s)",
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }
}
