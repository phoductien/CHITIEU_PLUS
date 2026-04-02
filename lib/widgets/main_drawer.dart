import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/auth_wrapper.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/terms_and_privacy_screen.dart';
import '../screens/eye_protection_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/bank_accounts_screen.dart';
import 'dart:convert';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Drawer(
      backgroundColor: themeProvider.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFFFD180),
                      backgroundImage: userProvider.photoUrl.isEmpty
                          ? const NetworkImage(
                                  'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
                                )
                                as ImageProvider
                          : (userProvider.photoUrl.startsWith('data:image/')
                                    ? MemoryImage(
                                        base64Decode(
                                          userProvider.photoUrl.split(',').last,
                                        ),
                                      )
                                    : NetworkImage(userProvider.photoUrl))
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProvider.name.isNotEmpty
                              ? userProvider.name
                              : 'Khách',
                          style: TextStyle(
                            color: themeProvider.foregroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProvider.email.isNotEmpty
                              ? userProvider.email
                              : 'guest@chitieuplus.internal',
                          style: TextStyle(
                            color: themeProvider.foregroundColor.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDrawerItem(
                        context: context,
                        themeProvider: themeProvider,
                        icon: Icons.smart_toy_rounded,
                        title: 'Chat với trợ lý ảo',
                        iconColor: const Color(0xFFEC5B13),
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiChatScreen(),
                            ),
                          );
                        },
                      ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.mail_rounded,
                      title: 'Liên hệ',
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Phản hồi',
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.open_in_browser_rounded,
                      title: 'Mở trang web',
                      onTap: () async {
                        final url = Uri.parse(
                          'https://chitieuplus-app.web.app',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể mở liên kết'),
                              ),
                            );
                          }
                        }
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Divider(
                        color: themeProvider.borderColor,
                        thickness: 1,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'CÀI ĐẶT',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.language_rounded,
                      title: 'Ngôn ngữ',
                      trailing: Text(
                        'Tiếng Việt',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {},
                    ),
                    _buildDrawerSwitch(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.dark_mode_rounded,
                      title: 'Chế độ sáng/tối',
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleDarkMode(val),
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.visibility_rounded,
                      title: 'Chế độ bảo vệ mắt',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EyeProtectionScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.notifications_rounded,
                      title: 'Thông báo',
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.policy_rounded,
                      title: 'Chính sách & Điều khoản',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndPrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.account_balance_rounded,
                      title: 'Tài khoản ngân hàng',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BankAccountsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.delete_forever_rounded,
                      title: 'Xóa toàn bộ dữ liệu',
                      titleColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteAllData(context);
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Divider(
                        color: themeProvider.borderColor,
                        thickness: 1,
                      ),
                    ),

                    _buildDrawerItem(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.logout_rounded,
                      title: 'Đăng xuất',
                      titleColor: const Color(0xFFE53935),
                      iconColor: const Color(0xFFE53935),
                      onTap: () async {
                        await UserProvider.cleanupGuestIfAny();
                        await FirebaseAuth.instance.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('is_bypassed_auth');
                        await prefs.remove('bypassed_email');

                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const AuthWrapper(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        'Phiên bản : 2.0.4',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  iconColor ??
                  themeProvider.foregroundColor.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      titleColor ??
                      themeProvider.foregroundColor.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSwitch({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.foregroundColor.withValues(alpha: 0.7),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: themeProvider.foregroundColor.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFEC5B13),
            activeTrackColor: const Color(0xFFEC5B13).withValues(alpha: 0.5),
            inactiveThumbColor: themeProvider.foregroundColor.withValues(
              alpha: 0.4,
            ),
            inactiveTrackColor: themeProvider.foregroundColor.withValues(
              alpha: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              'Xóa tất cả dữ liệu?',
              style: TextStyle(color: themeProvider.foregroundColor),
            ),
          ],
        ),
        content: Text(
          'Hành động này sẽ xóa vĩnh viễn toàn bộ giao dịch của bạn trên cả Firestore và Realtime Database. Bạn chắc chắn chứ?',
          style: TextStyle(
            color: themeProvider.foregroundColor.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: themeProvider.foregroundColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await provider.deleteAllTransactions();

        if (context.mounted) {
          provider.refresh();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đã xóa toàn bộ dữ liệu thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa dữ liệu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
