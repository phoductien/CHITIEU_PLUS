import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';

import '../providers/user_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../constants/api_constants.dart';
import 'balance_adjustment_screen.dart';

// Màn hình Quản lý Tài khoản: cung cấp các tính năng quản lý ngân hàng, thiết bị và cài đặt bảo mật.
class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  /// Định dạng tiền tệ theo chuẩn Việt Nam (VND)
  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ các Provider cần thiết
    final userProvider = context.watch<UserProvider>();
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep navy
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildProfileHeader(userProvider),
                      const SizedBox(height: 30),
                      _buildSectionTitle('TÓM TẮT TÀI CHÍNH'),
                      _buildBalanceCard(context, txProvider.totalBalance),
                      const SizedBox(height: 20),
                      _buildSectionTitle('TÀI KHOẢN ĐANG SỬ DỤNG'),
                      // Hiển thị danh sách ngân hàng đã liên kết
                      ...userProvider.bankAccounts.map((bank) => FadeInLeft(
                            child: _buildBankItem(context, bank, userProvider),
                          )),
                      if (userProvider.bankAccounts.isEmpty)
                        _buildEmptyState('Chưa có tài khoản liên kết'),
                      const SizedBox(height: 30),
                      _buildSectionTitle('ĐỒNG BỘ TỰ ĐỘNG (SEPAY)'),
                      _buildSePayWebhookSection(context, userProvider.uid, txProvider),
                      const SizedBox(height: 30),
                      _buildSectionTitle('PHƯƠNG THỨC ĐĂNG NHẬP HIỆN TẠI'),
                      _buildLoginMethod(userProvider.email),
                      const SizedBox(height: 30),
                      _buildSectionTitle('BẢO MẬT & ĐĂNG NHẬP'),
                      _buildSecurityItem(Icons.history, 'Đổi mật khẩu', true),
                      _buildSecurityItem(Icons.verified_user_outlined, 'Xác thực 2 lớp', false, trailing: _buildBadge('BẬT')),
                      _buildSecurityItem(Icons.fingerprint, 'Sinh trắc học / FaceID', false, trailing: _buildSwitch(true)),
                      const SizedBox(height: 30),
                      _buildAiSuggestionCard(),
                      const SizedBox(height: 30),
                      _buildSectionTitle('QUẢN LÝ THIẾT BỊ ĐÃ ĐĂNG NHẬP'),
                      // Hiển thị danh sách thiết bị đang đăng nhập
                      ...userProvider.deviceSessions.map((session) => FadeInUp(
                            child: _buildDeviceItem(context, session, userProvider),
                          )),
                      const SizedBox(height: 40),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Column(
            children: [
              Text(
                'Account',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                'Management',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Text(
            'ChiTieuPlus',
            style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider user) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrl.isEmpty
                    ? const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix') as ImageProvider
                    : (user.photoUrl.startsWith('data:image/')
                        ? MemoryImage(base64Decode(user.photoUrl.split(',').last))
                        : NetworkImage(user.photoUrl)) as ImageProvider,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF00BFA5), size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.isNotEmpty ? user.name : 'Người dùng',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Premium Alchemist',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFB74D),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SỐ DƯ KHẢ DỤNG',
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(balance).split('VND')[0],
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                'VND',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BalanceAdjustmentScreen()),
                  );
                },
                icon: const Icon(Icons.edit_note, color: Color(0xFFFFB74D), size: 28),
                tooltip: 'Cập nhật số dư',
              ),
              Icon(Icons.wallet, color: Colors.white.withOpacity(0.1), size: 50),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng mục hiển thị tài khoản ngân hàng đã liên kết
  Widget _buildBankItem(BuildContext context, String bankInfo, UserProvider userProvider) {
    // Info format: "BankName - AccountNumber"
    final parts = bankInfo.split(' - ');
    final bankName = parts[0];
    final accountNo = parts.length > 1 ? parts[1] : '';
    final maskedNo = accountNo.length > 4 
      ? '**** ${accountNo.substring(accountNo.length - 4)}' 
      : accountNo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance, color: Color(0xFF00BFA5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  maskedNo,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 20),
            onPressed: () => _confirmUnlinkBank(context, bankInfo, userProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethod(String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.email_outlined, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, bool hasArrow, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null) trailing,
          if (hasArrow) const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB87333).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitch(bool value) {
    return Switch(
      value: value,
      onChanged: (_) {},
      activeColor: const Color(0xFFEC5B13),
      activeTrackColor: const Color(0xFFEC5B13).withOpacity(0.3),
    );
  }

  Widget _buildAiSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
          const Color(0xFF0F172A).withOpacity(0.8),
          const Color(0xFF1E293B).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF00BFA5), size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gợi ý từ AI',
                  style: TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  'Tài khoản của bạn có thể an toàn hơn nếu kích hoạt thông báo đăng nhập từ thiết bị lạ.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị thông tin thiết bị đã đăng nhập (hỗ trợ đăng xuất từ xa)
  Widget _buildDeviceItem(BuildContext context, dynamic session, UserProvider userProvider) {
    final isCurrent = session.isCurrentDevice;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            session.deviceType.toLowerCase().contains('phone') ? Icons.smartphone : Icons.laptop,
            color: Colors.white70,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (isCurrent)
                  const Text(
                    'THIẾT BỊ HIỆN TẠI',
                    style: TextStyle(color: Color(0xFF00BFA5), fontSize: 10, fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    'Đăng nhập: ${DateFormat('dd/MM/yyyy').format(session.lastActive)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => _confirmLogoutDevice(context, session, userProvider),
              child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFFF8A65), fontSize: 13)),
            ),
        ],
      ),
    );
  }

  /// Nút đăng xuất chính của ứng dụng
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF311B92), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _handleMainLogout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSePayWebhookSection(BuildContext context, String uid, TransactionProvider txProvider) {
    final webhookUrl = '${ApiConstants.sepayWebhookUrl}?userId=$uid&key=${ApiConstants.sepayWebhookKey}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt, color: Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 10),
              const Text(
                'Webhook URL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              _buildBadge('ACTIVE'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sử dụng URL này để cấu hình Webhook trên SePay.vn để tự động đồng bộ giao dịch ngân hàng.',
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    webhookUrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: webhookUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép Webhook URL'),
                        backgroundColor: Color(0xFF00BFA5),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy, color: Color(0xFFFFB74D), size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: txProvider.isSyncing 
                ? null 
                : () async {
                    try {
                      await txProvider.syncDataWithFirestore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đồng bộ thành công!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi đồng bộ: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D).withOpacity(0.1),
                foregroundColor: const Color(0xFFFFB74D),
                side: const BorderSide(color: Color(0xFFFFB74D), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: txProvider.isSyncing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB74D)))
                : const Icon(Icons.refresh, size: 18),
              label: Text(txProvider.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận hủy liên kết ngân hàng
  void _confirmUnlinkBank(BuildContext context, String bankInfo, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hủy liên kết?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn hủy liên kết tài khoản $bankInfo?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              userProvider.removeBankAccount(bankInfo);
              Navigator.pop(context);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận đăng xuất thiết bị khác
  void _confirmLogoutDevice(BuildContext context, dynamic session, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Đăng xuất thiết bị?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Thiết bị ${session.deviceName} sẽ bị đăng xuất khỏi tài khoản của bạn.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              userProvider.removeDeviceSession(session.id);
              Navigator.pop(context);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Xử lý đăng xuất chính (Xóa thông tin khách nếu có)
  Future<void> _handleMainLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Đăng xuất?', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await UserProvider.cleanupGuestIfAny();
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_bypassed_auth');
      await prefs.remove('bypassed_email');

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }
}
