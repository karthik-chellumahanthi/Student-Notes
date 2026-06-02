import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/welcome_screen.dart';
import 'screens/maintenance_screen.dart';
import 'home.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RemoteConfigService.initialize();
  await ThemeService.init();

  runApp(const StudentNotesApp());
}

class StudentNotesApp extends StatefulWidget {
  const StudentNotesApp({super.key});

  @override
  State<StudentNotesApp> createState() => _StudentNotesAppState();
}

class _StudentNotesAppState extends State<StudentNotesApp> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Student Notes',
          themeMode: currentMode,
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            primaryColor: const Color(0xFF6B7280),
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blueGrey,
            primaryColor: const Color(0xFF1F2937),
            scaffoldBackgroundColor: const Color(0xFF111827),
          ),
          home: RemoteConfigService.maintenanceMode
              ? const MaintenanceScreen()
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    // While waiting for Firebase to check session
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 120,
                                height: 120,
                              ),
                              const SizedBox(height: 24),
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              const Text('Loading...'),
                            ],
                          ),
                        ),
                      );
                    }
                    // If there's an error, show login
                    if (snapshot.hasError) {
                      return WelcomeScreen(authService: _authService);
                    }

                    // User is logged in
                    if (snapshot.hasData && snapshot.data != null) {
                      return HomeScreen(authService: _authService);
                    }

                    // User is not logged in
                    return WelcomeScreen(authService: _authService);
                  },
                ),
        );
      },
    );
  }
}
