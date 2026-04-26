import 'package:flutter/material.dart';

enum NotificationType { transaction, fluctuation, aiReminder, system, security }

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.transaction:
        return Icons.shopping_bag_rounded;
      case NotificationType.fluctuation:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.aiReminder:
        return Icons.smart_toy_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
      case NotificationType.security:
        return Icons.security_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.fluctuation:
        return Colors.lightBlueAccent;
      case NotificationType.aiReminder:
        return Colors.orange;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.security:
        return Colors.yellow;
    }
  }

  String get typeString {
    switch (type) {
      case NotificationType.transaction:
        return 'Giao dịch';
      case NotificationType.fluctuation:
        return 'Biến động';
      case NotificationType.aiReminder:
        return 'Tin khác';
      case NotificationType.system:
        return 'Tin khác';
      case NotificationType.security:
        return 'Quan trọng';
    }
  }

  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (notificationDate == today) {
      return 'HÔM NAY';
    } else if (notificationDate == yesterday) {
      return 'HÔM QUA';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
