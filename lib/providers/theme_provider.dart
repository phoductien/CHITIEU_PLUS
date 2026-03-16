import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default to dark as per app style
  bool _isEyeProtection = false;

  bool get isDarkMode => _isDarkMode;
  bool get isEyeProtection => _isEyeProtection;

  // Dynamic Background Color
  Color get backgroundColor {
    if (_isEyeProtection) return const Color(0xFFFAF3E0); // Warm sepia-like
    return _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF082F49); // Dark Blue (Sky 950)
  }

  // Dynamic Background Gradient
  LinearGradient get backgroundGradient {
    if (_isEyeProtection) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFAF3E0), Color(0xFFF5E6CC)],
      );
    }
    if (_isDarkMode) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      );
    }
    // Dark Blue Gradient for Light Mode
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF082F49), Color(0xFF0369A1)], // Sky 950 to Sky 700
    );
  }

  // Dynamic Secondary Surface Color (Cards, App Bars)
  Color get secondaryColor {
    if (_isEyeProtection) return const Color(0xFFFDF5E6); // Old Lace (Warm)
    return _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F4C75); // Lighter blue for light mode cards
  }

  // Dynamic Foreground Color (Text, Icons)
  Color get foregroundColor {
    if (_isEyeProtection) return const Color(0xFF5D4037); // Deep Brown for sepia
    return _isDarkMode ? Colors.white : Colors.white; // White for both when background is dark
  }

  // Dynamic Border/Divider Color
  Color get borderColor {
    if (_isEyeProtection) return Colors.black.withValues(alpha: 0.1);
    // Use white borders when background is dark (both dark mode and new light mode)
    return Colors.white.withValues(alpha: 0.1);
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _saveToPrefs();
    _syncToFirestore();
    notifyListeners();
  }

  void toggleEyeProtection(bool value) {
    _isEyeProtection = value;
    _saveToPrefs();
    _syncToFirestore();
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _isEyeProtection = prefs.getBool('isEyeProtection') ?? false;
    notifyListeners();

    // After loading from prefs, try to sync with Firestore if logged in
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        bool changed = false;
        if (data.containsKey('isDarkMode')) {
          _isDarkMode = data['isDarkMode'];
          changed = true;
        }
        if (data.containsKey('isEyeProtection')) {
          _isEyeProtection = data['isEyeProtection'];
          changed = true;
        }
        if (changed) {
          notifyListeners();
          _saveToPrefs();
        }
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isEyeProtection', _isEyeProtection);
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isDarkMode': _isDarkMode,
        'isEyeProtection': _isEyeProtection,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
