import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default to dark as per app style
  bool _isEyeProtection = false;
  String? _backgroundImage; // URL mạng hoặc chuỗi base64 của ảnh tự chọn / Network URL or base64 string for custom background

  bool get isDarkMode => _isDarkMode;
  bool get isEyeProtection => _isEyeProtection;
  String? get backgroundImage => _backgroundImage;

  // Lấy ImageProvider tương ứng với background hiện tại / Get ImageProvider for current background
  ImageProvider? get backgroundImageProvider {
    if (_backgroundImage == null || _backgroundImage!.isEmpty) return null;
    if (_backgroundImage!.startsWith('http')) {
      return NetworkImage(_backgroundImage!);
    } else if (_backgroundImage!.startsWith('data:image/') || _backgroundImage!.contains('base64,')) {
      final base64Str = _backgroundImage!.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return null;
  }

  // Lấy BoxDecoration hoàn chỉnh chứa cả gradient hoặc ảnh nền / Get complete BoxDecoration containing gradient or background image
  BoxDecoration get backgroundDecoration {
    if (backgroundImageProvider != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: backgroundImageProvider!,
          fit: BoxFit.cover,
          // Đảm bảo ảnh nền tối vừa phải để giữ độ tương phản tốt cho chữ / Ensure background is dark enough for text readability
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.65),
            BlendMode.darken,
          ),
        ),
      );
    }
    return BoxDecoration(gradient: backgroundGradient);
  }

  // Dynamic Background Color
  Color get backgroundColor {
    if (_isEyeProtection) return const Color(0xFFFAF3E0); // Warm sepia-like
    return _isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFF082F49); // Dark Blue (Sky 950)
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
    return _isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFF0F4C75); // Lighter blue for light mode cards
  }

  // Dynamic Foreground Color (Text, Icons)
  Color get foregroundColor {
    if (_isEyeProtection) {
      return const Color(0xFF5D4037); // Deep Brown for sepia
    }
    return _isDarkMode
        ? Colors.white
        : Colors.white; // White for both when background is dark
  }

  // Dynamic Border/Divider Color
  Color get borderColor {
    if (_isEyeProtection) return Colors.black.withOpacity(0.1);
    // Use white borders when background is dark (both dark mode and new light mode)
    return Colors.white.withOpacity(0.1);
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleEyeProtection(bool value) {
    _isEyeProtection = value;
    _saveToPrefs();
    notifyListeners();
  }

  // Thiết lập ảnh nền mới / Set new background image
  void setBackgroundImage(String? pathOrUrl) {
    _backgroundImage = pathOrUrl;
    _saveToPrefs();
    notifyListeners();
  }

  // Xóa ảnh nền để dùng gradient mặc định / Clear background image to use default gradient
  void clearBackgroundImage() {
    _backgroundImage = null;
    _saveToPrefs();
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _isEyeProtection = prefs.getBool('isEyeProtection') ?? false;
    _backgroundImage = prefs.getString('backgroundImage');
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isEyeProtection', _isEyeProtection);
    if (_backgroundImage != null) {
      await prefs.setString('backgroundImage', _backgroundImage!);
    } else {
      await prefs.remove('backgroundImage');
    }
  }
}
