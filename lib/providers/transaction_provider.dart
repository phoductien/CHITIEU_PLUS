import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/realtime_db_service.dart';
import '../providers/user_provider.dart';

/// TransactionProvider: Quản lý danh sách giao dịch, số dư và đồng bộ hóa dữ liệu.
/// Sử dụng Realtime Database để cập nhật giao dịch tức thì.
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

  /// Tính toán tổng số dư dựa trên danh sách giao dịch hiện tại
  double get totalBalance {
    double balance = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }

  TransactionProvider() {
    _loadLastSyncTime();
    _initAuthListener();
    _init();
  }

  /// Lắng nghe trạng thái đăng nhập để tải lại dữ liệu khi người dùng thay đổi
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

  /// Khởi tạo kết nối Stream với Realtime Database
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

  Future<void> addTransaction(TransactionModel tx, {UserProvider? userProvider}) async {
    await _service.addTransaction(tx);
    
    // Cập nhật số dư thực tế nếu có userProvider
    // Việc này đảm bảo số dư luôn đi kèm với giao dịch mới
    if (userProvider != null) {
      double currentBalance = userProvider.totalBalance;
      if (tx.type == TransactionType.income) {
        currentBalance += tx.amount;
      } else {
        currentBalance -= tx.amount;
      }
      await userProvider.setTotalBalance(currentBalance);
    }
    
    await syncDataWithFirestore();
  }

  Future<void> deleteTransaction(String id) async {
    // Logic: Chỉ xóa bản ghi giao dịch, không gọi cập nhật số dư trong UserProvider
    await _service.deleteTransaction(id);
    await syncDataWithFirestore();
  }

  Future<void> deleteTransactions(List<String> ids) async {
    // Logic: Xóa danh sách giao dịch, số dư chính vẫn giữ nguyên
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

  Future<void> deleteAllTransactions({UserProvider? userProvider, bool resetBalance = false}) async {
    await _service.deleteAllTransactions();
    
    // GHI CHÚ QUAN TRỌNG:
    // 1. Mặc định resetBalance = false: Chỉ xóa lịch sử giao dịch, số dư giữ nguyên.
    // 2. Chỉ khi resetBalance = true: Số dư mới được đưa về 0 (dùng cho nút "Xóa số dư").
    if (resetBalance && userProvider != null) {
      await userProvider.setTotalBalance(0);
    }
    
    await syncDataWithFirestore();
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Đồng bộ hóa dữ liệu thủ công từ Firestore về Realtime Database
  Future<void> syncDataWithFirestore() async {
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Fetch from SePay if linked (logic inside service handles checks)
      await _service.syncWithSePay();

      // 2. Sync Firestore to RTDB
      await _service.syncFirestoreToRealtime();
      // _init() will be triggered by data change in RTDB as well,
      // but we explicitly refresh anyway.
      _init();
      await _updateSyncTime();
    } catch (e) {
      debugPrint('[TransactionProvider] Sync Error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
