import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon;
  final String color;
  final DateTime createdAt;

  SavingGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.icon = 'savings',
    this.color = '#F05D15',
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;
  
  double get remainingAmount => targetAmount - currentAmount;
  
  int get daysRemaining {
    final difference = deadline.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingGoalModel.fromMap(String id, Map<String, dynamic> map) {
    return SavingGoalModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline']) 
          : DateTime.now().add(const Duration(days: 30)),
      icon: map['icon'] ?? 'savings',
      color: map['color'] ?? '#F05D15',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  SavingGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
    DateTime? createdAt,
  }) {
    return SavingGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
