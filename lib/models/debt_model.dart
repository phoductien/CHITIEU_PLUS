import 'package:flutter/material.dart';

enum DebtType { debt, loan }
enum DebtStatus { pending, paid }

class DebtModel {
  final String id;
  final String name;
  final double amount;
  final DateTime? dueDate;
  final DebtType type;
  final DebtStatus status;
  final String note;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.name,
    required this.amount,
    this.dueDate,
    required this.type,
    this.status = DebtStatus.pending,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebtModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DebtModel(
      id: id,
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      type: map['type'] == 'loan' ? DebtType.loan : DebtType.debt,
      status: map['status'] == 'paid' ? DebtStatus.paid : DebtStatus.pending,
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  DebtModel copyWith({
    String? name,
    double? amount,
    DateTime? dueDate,
    DebtType? type,
    DebtStatus? status,
    String? note,
  }) {
    return DebtModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
