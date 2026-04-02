import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSessionProvider with ChangeNotifier {
  String _lastRoute = 'home';
  int _homeTabIndex = 0;
  int _addTransactionTabIndex = 0;
  
  String get lastRoute => _lastRoute;
  int get homeTabIndex => _homeTabIndex;
  int get addTransactionTabIndex => _addTransactionTabIndex;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _lastRoute = prefs.getString('last_route') ?? 'home';
    _homeTabIndex = prefs.getInt('home_tab_index') ?? 0;
    _addTransactionTabIndex = prefs.getInt('add_transaction_tab_index') ?? 0;
    notifyListeners();
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
    _lastRoute = 'home';
    _homeTabIndex = 0;
    _addTransactionTabIndex = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    await prefs.remove('home_tab_index');
    await prefs.remove('add_transaction_tab_index');
  }
}
