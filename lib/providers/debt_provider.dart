import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/debt_model.dart';
import '../services/realtime_db_service.dart';

class DebtProvider with ChangeNotifier {
  final List<DebtModel> _debts = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  final RealtimeDbService _dbService = RealtimeDbService();

  List<DebtModel> get debts => _debts;
  List<DebtModel> get pendingDebts => _debts.where((d) => d.status == DebtStatus.pending).toList();
  List<DebtModel> get paidDebts => _debts.where((d) => d.status == DebtStatus.paid).toList();
  bool get isLoading => _isLoading;

  double get totalLoan => _debts
      .where((d) => d.type == DebtType.loan && d.status == DebtStatus.pending)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalDebt => _debts
      .where((d) => d.type == DebtType.debt && d.status == DebtStatus.pending)
      .fold(0, (sum, item) => sum + item.amount);

  DebtProvider() {
    _init();
  }

  void _init() {
    _subscription = _dbService.getDebtsStream().listen((event) {
      _debts.clear();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          _debts.add(DebtModel.fromMap(value as Map<dynamic, dynamic>, key as String));
        });
        _debts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addDebt(DebtModel debt) async {
    await _dbService.saveDebt(debt);
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _dbService.saveDebt(debt);
  }

  Future<void> deleteDebt(String id) async {
    await _dbService.deleteDebt(id);
  }

  Future<void> toggleStatus(DebtModel debt) async {
    final newStatus = debt.status == DebtStatus.pending ? DebtStatus.paid : DebtStatus.pending;
    await _dbService.saveDebt(debt.copyWith(status: newStatus));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
