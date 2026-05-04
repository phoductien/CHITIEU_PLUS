import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import 'edit_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Màu nền tối theo mẫu
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditTransactionScreen(transaction: transaction),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Phần hiển thị Icon lớn trung tâm
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: const Color(0xFFFEA866), // Màu cam nhạt cho icon
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hiển thị số tiền lớn
            Text(
              '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(transaction.amount)}đ',
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFFCA5A5), // Đỏ nhạt cho chi tiêu
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transaction.category.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Thẻ thông tin chi tiết (Danh mục, Ngày, Ví)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Card background
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Danh mục',
                    transaction.category,
                    Icons.category_rounded,
                    const Color(0xFF00D1FF),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                  ),
                  _buildDetailRow(
                    'Ngày giao dịch',
                    DateFormat("dd 'Th'MM, yyyy").format(transaction.date),
                    Icons.calendar_today_rounded,
                    const Color(0xFF00D1FF),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                  ),
                  _buildDetailRow(
                    'Tài khoản/Ví',
                    transaction.wallet == 'main'
                        ? 'Ví Chính'
                        : transaction.wallet,
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF00D1FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thẻ Ghi chú
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: Color(0xFF00D1FF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GHI CHÚ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (transaction.note != null && transaction.note!.isNotEmpty)
                        ? transaction.note!
                        : 'Không có ghi chú.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thẻ AI Insights
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF061B24), // Màu tối xanh lá/teal
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF00D1FF).withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF00D1FF),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI INSIGHTS',
                        style: TextStyle(
                          color: Color(0xFF00D1FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chi tiêu này cao hơn 15% so với mức trung bình hàng tháng của danh mục ${transaction.category}.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Nút Chỉnh sửa giao dịch
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEA866), Color(0xFFFB923C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditTransactionScreen(transaction: transaction),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Chỉnh sửa giao dịch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nút Xóa giao dịch
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextButton(
                onPressed: () => _confirmDelete(context, themeProvider),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Xóa giao dịch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ xây dựng hàng thông tin chi tiết
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconBgColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconBgColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Hàm xác nhận xóa giao dịch
  void _confirmDelete(BuildContext context, ThemeProvider themeProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa giao dịch này không? Hành động này không thể hoàn tác.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFFCA5A5)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).deleteTransaction(transaction.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  // Các hàm hỗ trợ lấy icon và màu sắc danh mục
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Di chuyển':
        return Icons.directions_car_rounded;
      case 'Lương':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
