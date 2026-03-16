import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  static Database? _database;

  LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Return a dummy database or throw a descriptive error
      // Since the user is testing on Web but wants SQLite, we should ideally use sqflite_common_ffi_web
      // but for now let's just avoid the crash if they are just "trying it out"
      throw Exception('SQLite (sqflite) không hỗ trợ trên trình duyệt Web. Vui lòng chạy trên Android, iOS hoặc Windows.');
    }
    String path = join(await getDatabasesPath(), 'chitieu_plus.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        amount REAL,
        category TEXT,
        date TEXT,
        type TEXT,
        note TEXT,
        wallet TEXT,
        isPinned INTEGER
      )
    ''');
    debugPrint('[LocalStorage] Database tables created.');
  }

  // CRUD for Transactions
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    Map<String, dynamic> data = transaction.toMap();
    // Convert DateTime/Timestamp for SQLite compatibility
    data['date'] = transaction.date.toIso8601String();
    data['isPinned'] = transaction.isPinned ? 1 : 0;
    
    return await db.insert(
      'transactions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getLocalTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'isPinned DESC, date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        title: maps[i]['title'],
        amount: maps[i]['amount'],
        category: maps[i]['category'],
        date: DateTime.parse(maps[i]['date']),
        type: maps[i]['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        note: maps[i]['note'],
        wallet: maps[i]['wallet'] ?? 'main',
        isPinned: maps[i]['isPinned'] == 1,
      );
    });
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    Map<String, dynamic> data = transaction.toMap();
    data['date'] = transaction.date.toIso8601String();
    data['isPinned'] = transaction.isPinned ? 1 : 0;

    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> bulkInsertTransactions(List<TransactionModel> transactions) async {
    final db = await database;
    final batch = db.batch();
    
    for (var transaction in transactions) {
      Map<String, dynamic> data = transaction.toMap();
      data['date'] = transaction.date.toIso8601String();
      data['isPinned'] = transaction.isPinned ? 1 : 0;

      batch.insert(
        'transactions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'chitieu_plus.db');
  }
}
