import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;
  final TransactionService _service = TransactionService();

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    _initAuthListener();
    _init();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('[TransactionProvider] User logged in, re-initializing stream...');
        _init();
      } else {
        debugPrint('[TransactionProvider] User logged out, clearing transactions...');
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

    _subscription = _service.getTransactions().listen(
      (data) {
        _transactions = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[TransactionProvider] Error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _init();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _service.addTransaction(tx);
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteTransaction(id);
  }

  Future<void> deleteTransactions(List<String> ids) async {
    await _service.deleteTransactions(ids);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _service.updateTransaction(tx);
  }

  Future<void> togglePin(String id, bool currentStatus) async {
    await _service.togglePin(id, currentStatus);
  }

  Future<void> deleteAllTransactions() async {
    await _service.deleteAllTransactions();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
