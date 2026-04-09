import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class RealtimeDbService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://chitieuplus-app-default-rtdb.firebaseio.com',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DatabaseReference get _userRef {
    if (_userId == null) throw Exception('User not logged in');
    final isGuest = _auth.currentUser?.isAnonymous ?? false;
    final collection = isGuest ? 'guests' : 'users';
    return _db.ref().child('$collection/$_userId');
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      final map = transaction.toMap();
      map['date'] = transaction.date.toIso8601String();
      await _userRef.child('transactions/${transaction.id}').set(map);
      debugPrint('[RealtimeDB] Transaction saved: ${transaction.id}');
    } catch (e) {
      debugPrint('[RealtimeDB] Error saving transaction: $e');
      rethrow;
    }
  }

  Future<void> syncLocalTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      final Map<String, Map<String, dynamic>> updates = {};
      for (var t in transactions) {
        final map = t.toMap();
        map['date'] = t.date.toIso8601String();
        updates['transactions/${t.id}'] = map;
      }
      await _userRef.update(updates);
      debugPrint('[RealtimeDB] Bulk sync completed.');
    } catch (e) {
      debugPrint('[RealtimeDB] Bulk sync error: $e');
      rethrow;
    }
  }

  // Stream transactions
  Stream<DatabaseEvent> getTransactionsStream() {
    return _userRef.child('transactions').onValue;
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _userRef.child('transactions/$id').remove();
    } catch (e) {
      debugPrint('[RealtimeDB] Error deleting transaction: $e');
      rethrow;
    }
  }

  // Generic update for specific fields
  Future<void> updateTransactionField(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _userRef.child('transactions/$id').update(data);
    } catch (e) {
      debugPrint('[RealtimeDB] Error updating field: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserTransactions() async {
    try {
      await _userRef.child('transactions').remove();
      debugPrint('[RealtimeDB] All transactions deleted for user: $_userId');
    } catch (e) {
      debugPrint('[RealtimeDB] Error deleting all transactions: $e');
      rethrow;
    }
  }

  /// Clears the existing transactions node and writes a fresh list from Firestore.
  /// Used for "Repair Sync" functionality.
  Future<void> overwriteUserTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      // 1. Clear existing
      await _userRef.child('transactions').remove();

      // 2. Prepare bulk update
      if (transactions.isEmpty) return;

      final Map<String, Map<String, dynamic>> updates = {};
      for (var t in transactions) {
        final map = t.toMap();
        map['date'] = t.date.toIso8601String();
        updates['transactions/${t.id}'] = map;
      }

      // 3. Apply
      await _userRef.update(updates);
      debugPrint(
        '[RealtimeDB] Overwrite sync completed with ${transactions.length} items.',
      );
    } catch (e) {
      debugPrint('[RealtimeDB] Overwrite sync error: $e');
      rethrow;
    }
  }
}
