import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../models/device_session_model.dart';

class SecurityManagementScreen extends StatelessWidget {
  const SecurityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bảo mật & Thiết bị',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: themeProvider.foregroundColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Bank Accounts Section ---
              _buildSectionTitle(themeProvider, 'Tài khoản ngân hàng liên kết'),
              const SizedBox(height: 12),
              if (userProvider.bankAccounts.isEmpty)
                _buildEmptyState(
                  themeProvider,
                  'Chưa có tài khoản ngân hàng nào được liên kết.',
                )
              else
                ...userProvider.bankAccounts.map(
                  (bank) => _buildBankCard(
                    context,
                    themeProvider,
                    userProvider,
                    bank,
                  ),
                ),

              const SizedBox(height: 32),

              // --- Device Sessions Section ---
              _buildSectionTitle(themeProvider, 'Thiết bị đang truy cập'),
              const SizedBox(height: 12),
              if (userProvider.deviceSessions.isEmpty)
                _buildEmptyState(
                  themeProvider,
                  'Không tìm thấy thông tin thiết bị.',
                )
              else
                ...userProvider.deviceSessions.map(
                  (session) => _buildDeviceCard(
                    context,
                    themeProvider,
                    userProvider,
                    session,
                  ),
                ),

              const SizedBox(height: 40),

              // Security Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nếu bạn thấy thiết bị lạ, hãy đăng xuất ngay lập tức và đổi mật khẩu để bảo vệ tài khoản.',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withOpacity(0.8),
                          fontSize: 13,
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

  Widget _buildSectionTitle(ThemeProvider theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.foregroundColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.secondaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: theme.foregroundColor.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBankCard(
    BuildContext context,
    ThemeProvider theme,
    UserProvider user,
    String bankName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: TextStyle(
                    color: theme.foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Đã liên kết',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _confirmUnlinkBank(context, user, bankName),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Hủy liên kết',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    ThemeProvider theme,
    UserProvider user,
    DeviceSessionModel session,
  ) {
    final isCurrent = session.isCurrentDevice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCurrent ? Colors.blue : Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDeviceIcon(session.deviceType),
              color: isCurrent ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.deviceName,
                        style: TextStyle(
                          color: theme.foregroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIỆN TẠI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.deviceType} • OS ${session.osVersion}',
                  style: TextStyle(
                    color: theme.foregroundColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  isCurrent
                      ? 'Đang hoạt động'
                      : 'Hoạt động: ${DateFormat('HH:mm, dd/MM/yyyy').format(session.lastActive)}',
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.green
                        : theme.foregroundColor.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              onPressed: () => _confirmLogoutDevice(context, user, session),
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Đăng xuất thiết bị này',
            ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'android':
      case 'ios':
        return Icons.smartphone_rounded;
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.laptop_windows_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  void _confirmUnlinkBank(
    BuildContext context,
    UserProvider user,
    String bankName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy liên kết?'),
        content: Text(
          'Bạn có chắc chắn muốn hủy liên kết tài khoản $bankName không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () {
              user.removeBankAccount(bankName);
              Navigator.pop(context);
            },
            child: const Text(
              'Hủy liên kết',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogoutDevice(
    BuildContext context,
    UserProvider user,
    DeviceSessionModel session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất thiết bị?'),
        content: Text(
          'Thiết bị "${session.deviceName}" sẽ bị đăng xuất khỏi tài khoản của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () {
              user.removeDeviceSession(session.id);
              Navigator.pop(context);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
