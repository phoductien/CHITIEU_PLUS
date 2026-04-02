import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String? note;
  final String wallet; // 'main' or 'trial'
  final bool isPinned;
  final Map<String, dynamic>? aiMetadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = TransactionType.expense,
    this.note,
    this.wallet = 'main',
    this.isPinned = false,
    this.aiMetadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'note': note,
      'wallet': wallet,
      'isPinned': isPinned,
      'aiMetadata': aiMetadata,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Khác',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : (map['date'] is String
                ? DateTime.tryParse(map['date']) ?? DateTime.now()
                : (map['date'] is int
                      ? DateTime.fromMillisecondsSinceEpoch(map['date'])
                      : DateTime.now())),
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      note: map['note'],
      wallet: map['wallet'] ?? 'main',
      isPinned: map['isPinned'] ?? false,
      aiMetadata: map['aiMetadata'],
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    TransactionType? type,
    String? note,
    String? wallet,
    bool? isPinned,
    Map<String, dynamic>? aiMetadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      wallet: wallet ?? this.wallet,
      isPinned: isPinned ?? this.isPinned,
      aiMetadata: aiMetadata ?? this.aiMetadata,
    );
  }
}
