import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../models/transaction_model.dart';

class BalanceAdjustmentScreen extends StatefulWidget {
  const BalanceAdjustmentScreen({super.key});

  @override
  State<BalanceAdjustmentScreen> createState() =>
      _BalanceAdjustmentScreenState();
}

class _BalanceAdjustmentScreenState extends State<BalanceAdjustmentScreen> {
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _balanceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateBalance(double currentBalance) async {
    final newBalanceStr = _balanceController.text.replaceAll(',', '');
    if (newBalanceStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số dư mới')));
      return;
    }

    final newBalance = double.tryParse(newBalanceStr);
    if (newBalance == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
      return;
    }

    final diff = newBalance - currentBalance;
    if (diff == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final txProvider = context.read<TransactionProvider>();

      final adjustmentTx = TransactionModel(
        id: const Uuid().v4(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        title: _reasonController.text.isNotEmpty
            ? _reasonController.text
            : 'Điều chỉnh số dư',
        amount: diff.abs(),
        category: 'Điều chỉnh',
        date: DateTime.now(),
        type: diff > 0 ? TransactionType.income : TransactionType.expense,
        note: 'Cập nhật số dư thủ công',
        wallet: 'main',
      );

      final userProvider = context.read<UserProvider>();
      await txProvider.addTransaction(
        adjustmentTx,
        userProvider: userProvider,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật số dư thành công')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleResetBalance() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeProvider = context.read<ThemeProvider>();
        return AlertDialog(
          backgroundColor: themeProvider.secondaryColor,
          title: Text(
            'Xóa toàn bộ số dư?',
            style: TextStyle(color: themeProvider.foregroundColor),
          ),
          content: Text(
            'Tất cả giao dịch sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.',
            style: TextStyle(
              color: themeProvider.foregroundColor.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Xóa hết'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      try {
        final userProvider = context.read<UserProvider>();
        await context.read<TransactionProvider>().deleteAllTransactions(
              userProvider: userProvider,
              resetBalance: true,
            );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ số dư')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentBalance = userProvider.totalBalance;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý số dư',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: _buildCurrentBalanceCard(currentBalance, themeProvider),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cập nhật số dư mới',
                      style: TextStyle(
                        color: themeProvider.foregroundColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _balanceController,
                      label: 'Số dư mới',
                      hint: 'Nhập số tiền mong muốn',
                      icon: Icons.account_balance_wallet_rounded,
                      keyboardType: TextInputType.number,
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _reasonController,
                      label: 'Lý do (Tùy chọn)',
                      hint: 'Ví dụ: Kiểm kê lại ví',
                      icon: Icons.edit_note_rounded,
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _handleUpdateBalance(currentBalance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC5B13),
                          shape: RoundedRectanglePlatform.isIOS
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Xác nhận cập nhật',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: _isSaving ? null : _handleResetBalance,
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Xóa toàn bộ số dư & giao dịch',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard(double balance, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư hiện tại',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                NumberFormat('#,###').format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'đ',
                style: TextStyle(
                  color: Color(0xFFEC5B13),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ThemeProvider themeProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: themeProvider.foregroundColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: themeProvider.foregroundColor.withOpacity(0.3),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFFEC5B13), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RoundedRectanglePlatform {
  static bool get isIOS =>
      true; // Mocking for simplicity as per common project structure
}
