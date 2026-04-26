import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'Tất cả';
  final Set<int> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    
    final txNotifications = transactionProvider.transactions.map((tx) {
      final isTopUp = tx.note == 'Nạp qua Ví dùng thử';
      final isIncome = tx.type == TransactionType.income;
      return NotificationModel(
        id: tx.id.hashCode,
        title: isTopUp ? 'Biến động số dư' : (isIncome ? 'Thu nhập: ${tx.category}' : 'Chi tiêu: ${tx.category}'),
        body: '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ • ${tx.title}\nTài khoản: ${tx.wallet == 'main' ? 'Ví chính' : 'Ví dùng thử'}',
        timestamp: tx.date,
        type: isTopUp ? NotificationType.fluctuation : NotificationType.transaction,
        isRead: true, 
      );
    }).toList();

    final allItems = [...notificationProvider.notifications, ...txNotifications];
    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final filteredNotifications = _selectedFilter == 'Tất cả'
        ? allItems
        : allItems.where((n) => n.typeString == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () {
                notificationProvider.deleteNotifications(_selectedItems);
                setState(() {
                  _selectedItems.clear();
                  _isSelectionMode = false;
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'select') {
                setState(() => _isSelectionMode = !_isSelectionMode);
              } else if (value == 'markRead') {
                notificationProvider.markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'select',
                child: Text(_isSelectionMode ? 'Hủy chọn' : 'Chọn thông báo'),
              ),
              const PopupMenuItem(
                value: 'markRead',
                child: Text('Đánh dấu đã đọc tất cả'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildFilterBar(),
          const SizedBox(height: 20),
          Expanded(
            child: filteredNotifications.isEmpty
                ? const Center(
                    child: Text(
                      'Không có thông báo nào.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : _buildNotificationList(filteredNotifications),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['Tất cả', 'Giao dịch', 'Biến động', 'Quan trọng', 'Tin khác'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              selectedColor: const Color(0xFFFF6D00),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> items) {
    String? lastGroup;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool showHeader = false;
        if (lastGroup != item.dateGroup) {
          lastGroup = item.dateGroup;
          showHeader = true;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  item.dateGroup,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            _buildNotificationCard(item),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    final isSelected = _selectedItems.contains(item.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.type == NotificationType.transaction || item.type == NotificationType.fluctuation) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem và chỉnh sửa hóa đơn tại mục Giao dịch trên thanh điều hướng')));
           return;
        }
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedItems.remove(item.id);
            } else {
              _selectedItems.add(item.id);
            }
          });
        } else {
          context.read<NotificationProvider>().markAsRead(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6D00).withOpacity(0.1)
              : const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6D00) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6D00),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isSelectionMode && item.type != NotificationType.transaction && item.type != NotificationType.fluctuation)
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(item.id);
                    } else {
                      _selectedItems.add(item.id);
                    }
                  });
                },
                activeColor: const Color(0xFFFF6D00),
                shape: const CircleBorder(),
              ),
          ],
        ),
      ),
    );
  }
}

