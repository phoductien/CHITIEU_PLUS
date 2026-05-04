import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitieu_plus/screens/login_screen.dart';
import 'package:chitieu_plus/screens/splash_screen.dart';
import 'package:chitieu_plus/screens/home_screen.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';
import 'package:chitieu_plus/widgets/app_loading_indicator.dart';

class AuthWrapper extends StatefulWidget {
  final bool skipSplash;
  const AuthWrapper({super.key, this.skipSplash = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasLoggedIn = false;

  Future<bool> _isBypassed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_bypassed_auth') ?? false;
    } catch (_) {
      return false;
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF01142F), Color(0xFF022C4F), Color(0xFF015BB5)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const AppLoadingIndicator(size: 48, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isBypassed(),
      builder: (context, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (futureSnapshot.data == true) {
          return const HomeScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, snapshot) {
            final connectionState = snapshot.connectionState;
            final User? user = snapshot.data;

            // Update _wasLoggedIn if we see a user
            if (user != null && !_wasLoggedIn) {
              _wasLoggedIn = true;
            }

            // If we are waiting and have no initial data, show splash/loader
            if (connectionState == ConnectionState.waiting && user == null) {
              return widget.skipSplash
                  ? _buildLoadingScreen()
                  : const SplashScreen();
            }

            if (user != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<AppSessionProvider>().updateLastActive();
                }
              });

              return widget.skipSplash
                  ? const HomeScreen()
                  : const SplashScreen();
            } else {
              // User is null. Is it a logout or just startup?
              // If we were previously logged in, it's a logout -> show Splash
              if (_wasLoggedIn) {
                return const SplashScreen();
              }

              // Standard startup check for logged out users
              if (UserProvider.isCleaningUpGuest) {
                return widget.skipSplash
                    ? const LoginScreen()
                    : const SplashScreen();
              }
              return widget.skipSplash
                  ? const LoginScreen()
                  : const SplashScreen();
            }
          },
        );
      },
    );
  }
}
