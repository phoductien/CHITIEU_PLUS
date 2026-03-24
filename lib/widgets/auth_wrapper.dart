import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitieu_plus/screens/splash_screen.dart';
import 'package:chitieu_plus/screens/home_screen.dart';
import 'package:chitieu_plus/providers/user_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isBypassed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_bypassed_auth') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isBypassed(),
      builder: (context, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user bypassed auth (due to forgot password flow hack)
        if (futureSnapshot.data == true) {
          debugPrint(
            '[DEBUG] AuthWrapper: USER STATE: BYPASSED AUTH (LOGGED IN)',
          );
          return const HomeScreen();
        }

        // Standard Firebase Auth check
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            debugPrint(
              '[DEBUG] AuthWrapper: Stream Status: ${snapshot.connectionState}',
            );

            if (snapshot.connectionState == ConnectionState.active ||
                snapshot.connectionState == ConnectionState.waiting) {
              if (snapshot.hasError) {
                debugPrint(
                  '[DEBUG] AuthWrapper: Stream Error: ${snapshot.error}',
                );
              }

              final User? user = snapshot.data;
              debugPrint(
                '[DEBUG] AuthWrapper: USER STATE: ${user != null ? 'LOGGED IN (${user.email})' : 'LOGGED OUT'}',
              );

              if (user == null || UserProvider.isCleaningUpGuest) {
                return const SplashScreen();
              } else {
                return const HomeScreen();
              }
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
