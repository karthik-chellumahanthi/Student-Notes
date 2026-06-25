import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.blueGrey[700]! : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : const Color(0xFFD1D5DB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 80,
                    color: isDark ? Colors.grey[500] : Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.displayName ?? "User",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? "No email",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withOpacity(0.6) : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF059669) : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          "Verified",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF34D399) : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          /// Account Information Section
          Text(
            "Account Information",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          /// Email Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blueGrey[700]! : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email Address",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.email ?? "Not available",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          /// Email Verification Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blueGrey[700]! : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email Verification",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _currentUser?.emailVerified ?? false
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _currentUser?.emailVerified ?? false
                          ? (isDark ? const Color(0xFF34D399) : Colors.green)
                          : (isDark ? const Color(0xFFF87171) : Colors.red),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentUser?.emailVerified ?? false
                          ? "Verified"
                          : "Not Verified",
                      style: TextStyle(
                        fontSize: 16,
                        color: _currentUser?.emailVerified ?? false
                            ? (isDark ? const Color(0xFF34D399) : Colors.green)
                            : (isDark ? const Color(0xFFF87171) : Colors.red),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
