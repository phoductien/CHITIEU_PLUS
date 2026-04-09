import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/realtime_db_service.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;
  final RealtimeDbService _rtdbService = RealtimeDbService();
  final TransactionService _service = TransactionService();
  DateTime? _lastSyncTime;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime? get lastSyncTime => _lastSyncTime;

  TransactionProvider() {
    _loadLastSyncTime();
    _initAuthListener();
    _init();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint(
          '[TransactionProvider] User logged in, re-initializing stream...',
        );
        _init();
      } else {
        debugPrint(
          '[TransactionProvider] User logged out, clearing transactions...',
        );
        _transactions = [];
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
      _subscription = _rtdbService.getTransactionsStream().listen(
        (event) {
          final data = event.snapshot.value;
          List<TransactionModel> loaded = [];

          if (data != null) {
            try {
              // Convert RTDB's JS objects natively relying on JSON to avoid JS interop map[\$_get] error
              final safeData = jsonDecode(jsonEncode(data));
              if (safeData is Map) {
                safeData.forEach((key, value) {
                  if (value != null && value is Map) {
                    loaded.add(
                      TransactionModel.fromMap(
                        key.toString(),
                        Map<String, dynamic>.from(value),
                      ),
                    );
                  }
                });
              } else if (safeData is List) {
                for (int i = 0; i < safeData.length; i++) {
                  if (safeData[i] != null && safeData[i] is Map) {
                    loaded.add(
                      TransactionModel.fromMap(
                        i.toString(),
                        Map<String, dynamic>.from(safeData[i] as Map),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('[TransactionProvider] Safe parse error: \$e');
            }
          }

          // Phải sort lại vì Map không giữ thứ tự
          loaded.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.date.compareTo(a.date);
          });

          _transactions = loaded;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[TransactionProvider] RTDB Error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[TransactionProvider] Setup Error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('last_sync_time');
    if (timestamp != null) {
      _lastSyncTime = DateTime.parse(timestamp);
      notifyListeners();
    }
  }

  Future<void> _updateSyncTime() async {
    final now = DateTime.now();
    _lastSyncTime = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', now.toIso8601String());
    notifyListeners();
  }

  Future<void> refresh() async {
    _init();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _service.addTransaction(tx);
    await syncDataWithFirestore();
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteTransaction(id);
    await syncDataWithFirestore();
  }

  Future<void> deleteTransactions(List<String> ids) async {
    await _service.deleteTransactions(ids);
    await syncDataWithFirestore();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _service.updateTransaction(tx);
    await syncDataWithFirestore();
  }

  Future<void> togglePin(String id, bool currentStatus) async {
    await _service.togglePin(id, currentStatus);
    await syncDataWithFirestore();
  }

  Future<void> deleteAllTransactions() async {
    await _service.deleteAllTransactions();
    await syncDataWithFirestore();
  }

  /// Manually triggers a re-sync from Firestore to Realtime DB
  Future<void> syncDataWithFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.syncFirestoreToRealtime();
      // _init() will be triggered by data change in RTDB as well,
      // but we explicitly refresh anyway.
      _init();
      await _updateSyncTime();
    } catch (e) {
      debugPrint('[TransactionProvider] Sync Error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
