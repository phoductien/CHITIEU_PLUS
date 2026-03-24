import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chitieu_plus/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  final StreamController<NotificationModel> _newNotificationController =
      StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get onNewNotification =>
      _newNotificationController.stream;

  void addNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    final newNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, newNotification);
    _newNotificationController.add(newNotification);
    notifyListeners();
  }

  @override
  void dispose() {
    _newNotificationController.close();
    super.dispose();
  }

  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotifications(Set<int> ids) {
    _notifications.removeWhere((n) => ids.contains(n.id));
    notifyListeners();
  }

  // Initial dummy data for demo
  void loadInitialNotifications() {
    if (_notifications.isNotEmpty) return;

    _notifications.addAll([
      NotificationModel(
        id: 1,
        title: 'Giao dịch thành công',
        body: 'Bạn vừa chi 50.000đ cho Phở Lý Quốc Sư',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.transaction,
        isRead: false,
      ),
      NotificationModel(
        id: 2,
        title: 'Cảnh báo chi tiêu',
        body:
            'Bạn đã tiêu 80% ngân sách ăn uống tuần này. Hãy cân nhắc các bữa ăn tại nhà nhé!',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.aiReminder,
        isRead: false,
      ),
      NotificationModel(
        id: 3,
        title: 'Cập nhật hệ thống',
        body:
            'ChiTieuPlus vừa bổ sung tính năng quét hóa đơn tự động bằng AI mới.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.system,
        isRead: true,
      ),
    ]);
    notifyListeners();
  }
}
