import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saving_goal_model.dart';
import '../services/realtime_db_service.dart';

class SavingGoalProvider with ChangeNotifier {
  List<SavingGoalModel> _goals = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;
  final RealtimeDbService _rtdbService = RealtimeDbService();

  List<SavingGoalModel> get goals => _goals;
  bool get isLoading => _isLoading;

  SavingGoalProvider() {
    _initAuthListener();
    _init();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _init();
      } else {
        _goals = [];
        _subscription?.cancel();
        _subscription = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _init() {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = _rtdbService.getGoalsStream().listen(
        (event) {
          final data = event.snapshot.value;
          List<SavingGoalModel> loaded = [];

          if (data != null) {
            try {
              final safeData = jsonDecode(jsonEncode(data));
              if (safeData is Map) {
                safeData.forEach((key, value) {
                  if (value != null && value is Map) {
                    loaded.add(
                      SavingGoalModel.fromMap(
                        key.toString(),
                        Map<String, dynamic>.from(value),
                      ),
                    );
                  }
                });
              }
            } catch (e) {
              debugPrint('[SavingGoalProvider] Safe parse error: $e');
            }
          }

          // Sort by creation date
          loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _goals = loaded;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[SavingGoalProvider] RTDB Error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[SavingGoalProvider] Setup Error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveGoal(SavingGoalModel goal) async {
    await _rtdbService.saveGoal(goal);
  }

  Future<void> deleteGoal(String id) async {
    await _rtdbService.deleteGoal(id);
  }

  Future<void> updateGoalProgress(String id, double additionalAmount) async {
    final goalIndex = _goals.indexWhere((g) => g.id == id);
    if (goalIndex != -1) {
      final updatedGoal = _goals[goalIndex].copyWith(
        currentAmount: _goals[goalIndex].currentAmount + additionalAmount,
      );
      await saveGoal(updatedGoal);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
