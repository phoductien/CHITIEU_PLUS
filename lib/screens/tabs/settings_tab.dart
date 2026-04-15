import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitieu_plus/widgets/auth_wrapper.dart';
import 'package:chitieu_plus/screens/ai_chat_screen.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chitieu_plus/screens/terms_and_privacy_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Row(
              children: [
                Container(width: 40), // spacer for centering
                Expanded(
                  child: Text(
                    'Cài đặt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(width: 40),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // User Profile Section
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFFFFD180),
                            backgroundImage: userProvider.photoUrl.isNotEmpty
                                ? NetworkImage(userProvider.photoUrl)
                                : const NetworkImage(
                                    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
                                  ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProvider.name.isNotEmpty
                                      ? userProvider.name
                                      : 'Nguyễn Văn A',
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
                                      : 'van.a@example.com',
                                  style: TextStyle(
                                    color: themeProvider.foregroundColor
                                        .withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionHeader('Tài khoản & AI', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    children: [
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.person_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: const Color(0xFFEC5B13),
                        title: 'Thông tin tài khoản',
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.smart_toy_rounded,
                        iconColor: const Color(0xFFEC5B13),
                        iconBgColor: const Color(
                          0xFFEC5B13,
                        ).withValues(alpha: 0.2),
                        title: 'Chat với trợ lý ảo',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiChatScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.open_in_browser_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: Colors.blueAccent.withValues(alpha: 0.2),
                        title: 'Mở trong trình duyệt',
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Tùy chỉnh', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    children: [
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.language_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Ngôn ngữ',
                        trailing: Text(
                          'Tiếng Việt',
                          style: TextStyle(
                            color: themeProvider.foregroundColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSwitchItem(
                        themeProvider: themeProvider,
                        icon: Icons.dark_mode_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Chế độ sáng/tối',
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleDarkMode(val),
                      ),
                      _buildDivider(themeProvider),
                      _buildSwitchItem(
                        themeProvider: themeProvider,
                        icon: Icons.visibility_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Chế độ bảo vệ mắt',
                        value: themeProvider.isEyeProtection,
                        onChanged: (val) =>
                            themeProvider.toggleEyeProtection(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Thông báo', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    children: [
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.notifications_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Nhắc nhở thông báo',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Liên hệ & Pháp lý', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    children: [
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.mail_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Liên hệ',
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.chat_bubble_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Phản hồi',
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.policy_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                        title: 'Chính sách & Điều khoản',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsAndPrivacyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.delete_forever_rounded,
                        iconColor: Colors.redAccent,
                        iconBgColor: Colors.redAccent.withValues(alpha: 0.1),
                        title: 'Xóa tất cả dữ liệu (Firestore & RTDB)',
                        onTap: () => _deleteAllData(context),
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.logout_rounded,
                        iconColor: Colors.redAccent,
                        iconBgColor: Colors.redAccent.withValues(alpha: 0.1),
                        title: 'Đăng xuất',
                        showArrow: false,
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
                    ],
                  ),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
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

    if (confirm == true && mounted) {
      try {
        await provider.deleteAllTransactions();

        if (mounted) {
          provider.refresh();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đã xóa toàn bộ dữ liệu thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: themeProvider.foregroundColor.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({
    required List<Widget> children,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ThemeProvider themeProvider) {
    return Divider(
      height: 1,
      thickness: 1,
      color: themeProvider.borderColor,
      indent: 64,
    );
  }

  Widget _buildSettingsItem({
    required ThemeProvider themeProvider,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    Widget? trailing,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ?trailing,
            if (trailing != null && showArrow) const SizedBox(width: 8),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: themeProvider.foregroundColor.withValues(alpha: 0.4),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required ThemeProvider themeProvider,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 16,
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
}
