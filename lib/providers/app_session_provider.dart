import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSessionProvider with ChangeNotifier {
  String _lastRoute = 'home';
  int _homeTabIndex = 0;
  int _addTransactionTabIndex = 0;
  DateTime? _lastActive;

  String get lastRoute => _lastRoute;
  int get homeTabIndex => _homeTabIndex;
  int get addTransactionTabIndex => _addTransactionTabIndex;
  DateTime? get lastActive => _lastActive;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _lastRoute = prefs.getString('last_route') ?? 'home';
    _homeTabIndex = prefs.getInt('home_tab_index') ?? 0;
    _addTransactionTabIndex = prefs.getInt('add_transaction_tab_index') ?? 0;
    final lastActiveStr = prefs.getString('last_active');
    if (lastActiveStr != null) {
      _lastActive = DateTime.tryParse(lastActiveStr);
    }
    notifyListeners();
  }

  Future<void> updateLastActive() async {
    _lastActive = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active', _lastActive!.toIso8601String());
  }

  Future<void> setLastRoute(String route) async {
    if (_lastRoute == route) return;
    _lastRoute = route;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
  }

  Future<void> setHomeTabIndex(int index) async {
    if (_homeTabIndex == index) return;
    _homeTabIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_tab_index', index);
  }

  Future<void> setAddTransactionTabIndex(int index) async {
    if (_addTransactionTabIndex == index) return;
    _addTransactionTabIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('add_transaction_tab_index', index);
  }

  Future<void> clearSession() async {
    _lastActive = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    await prefs.remove('home_tab_index');
    await prefs.remove('add_transaction_tab_index');
    await prefs.remove('last_active');
  }
}
