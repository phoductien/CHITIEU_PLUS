import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'local_storage_service.dart';
import 'realtime_db_service.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _local = LocalStorageService();
  final RealtimeDbService _realtime = RealtimeDbService();

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _transactionsRef => _db.collection('transactions');

  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) return;
    
    // Get a new doc reference to get a generated ID if transaction.id is empty
    DocumentReference docRef;
    if (transaction.id.isEmpty) {
      docRef = _transactionsRef.doc();
    } else {
      docRef = _transactionsRef.doc(transaction.id);
    }
    
    final finalId = docRef.id;
    final finalTransaction = transaction.copyWith(id: finalId);

    // 1. Save to Firestore
    await docRef.set(finalTransaction.toMap());
    
    // 2. Save to Realtime DB
    await _realtime.saveTransaction(finalTransaction);
    
    // 3. SQLite is now only updated during export (on-demand)
    // await _local.insertTransaction(finalTransaction);
  }

  Stream<List<TransactionModel>> getTransactions() {
    if (_userId == null) return Stream.value([]);
    
    // UI will listen to Firestore for real-time updates without reload
    return _transactionsRef
        .where('userId', isEqualTo: _userId)
        .orderBy('isPinned', descending: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Delete from Firestore
    await _transactionsRef.doc(id).delete();
    
    // 2. Delete from Realtime DB
    await _realtime.deleteTransaction(id);
    
    // 3. SQLite is now only updated during export (on-demand)
    // await _local.deleteTransaction(id);
  }

  Future<void> deleteTransactions(List<String> ids) async {
    final batch = _db.batch();
    for (var id in ids) {
      batch.delete(_transactionsRef.doc(id));
      
      // Realtime DB deletion
      await _realtime.deleteTransaction(id);
      
      // SQLite is now only updated during export (on-demand)
      // await _local.deleteTransaction(id);
    }
    await batch.commit();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_userId == null) return;
    
    // 1. Update Firestore
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
    
    // 2. Update Realtime DB
    await _realtime.saveTransaction(transaction);
    
    // 3. SQLite is now only updated during export (on-demand)
    // await _local.updateTransaction(transaction);
  }

  Future<void> togglePin(String id, bool currentStatus) async {
    final newStatus = !currentStatus;
    
    // 1. Update Firestore
    await _transactionsRef.doc(id).update({'isPinned': newStatus});
    
    // 2. Update Realtime DB
    await _realtime.updateTransactionField(id, {'isPinned': newStatus});
    
    // 3. SQLite is now only updated during export (on-demand)
    // final db = await _local.database;
    // await db.update('transactions', {'isPinned': newStatus ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Fetches all user transactions from Firestore and saves them to local SQLite database.
  /// Returns the bytes of the generated SQLite file.
  Future<Uint8List> exportAllToSqliteBytes() async {
    if (_userId == null) throw Exception('Vui lòng đăng nhập để xuất dữ liệu.');

    // 1. Fetch all from Firestore
    final snapshot = await _transactionsRef
        .where('userId', isEqualTo: _userId)
        .get();
    
    final transactions = snapshot.docs.map((doc) {
      return TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    // 2. Clear local SQLite and rebuild (Desktop/Mobile only)
    try {
      if (kIsWeb) {
        // Fallback for Web: Export as JSON
        final jsonList = transactions.map((t) {
          final map = t.toMap();
          map['id'] = t.id; // Include ID in export
          // Convert Timestamp to ISO 8601 string for JSON compatibility
          if (map['date'] is Timestamp) {
            map['date'] = (map['date'] as Timestamp).toDate().toIso8601String();
          }
          return map;
        }).toList();
        final jsonString = json.encode(jsonList);
        return Uint8List.fromList(utf8.encode(jsonString));
      }

      await _local.clearAllData();
      await _local.bulkInsertTransactions(transactions);
      
      final dbPath = await _local.getDatabasePath();
      final dbFile = File(dbPath);
      return await dbFile.readAsBytes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllTransactions() async {
    if (_userId == null) return;

    // 1. Get all transaction IDs from Firestore
    final snapshot = await _transactionsRef
        .where('userId', isEqualTo: _userId)
        .get();

    if (snapshot.docs.isEmpty) return;

    // 2. Delete from Firestore using batch
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // 3. Delete from Realtime DB (entire transactions node for the user)
    await _realtime.deleteAllUserTransactions();

    // 4. (Optional) Clear SQLite if needed during export flow rebuild
    await _local.clearAllData();
  }

  Future<String> exportAllToSqlite() async {
    // Keep this for compatibility if needed, though we prefer the bytes version
    await exportAllToSqliteBytes();
    return await _local.getDatabasePath();
  }
}
