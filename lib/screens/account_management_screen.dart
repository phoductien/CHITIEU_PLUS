import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../providers/user_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'balance_adjustment_screen.dart';

// Màn hình Quản lý Tài khoản: cung cấp các tính năng quản lý ngân hàng, thiết bị và cài đặt bảo mật.
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  // Tập hợp các ID thiết bị được chọn để đăng xuất hàng loạt / Set of selected device IDs for batch logout
  final Set<String> _selectedDeviceIds = {};

  /// Định dạng tiền tệ theo chuẩn Việt Nam (VND)
  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format(amount);
  }

  final List<Map<String, String>> _presetBackgrounds = [
    {
      'name': 'Gradient Gốc',
      'url': '', // Rỗng nghĩa là sử dụng gradient mặc định
    },
    {
      'name': 'Vũ Trụ',
      'url':
          'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Minimal Wave',
      'url':
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Núi Đêm',
      'url':
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Rừng Sương',
      'url':
          'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  Future<void> _pickCustomImage(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64String';
        themeProvider.setBackgroundImage(dataUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật ảnh nền tự chọn thành công!'),
              backgroundColor: Color(0xFF00BFA5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildBackgroundSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final currentBg = themeProvider.backgroundImage;
    final isCustomSelected =
        currentBg != null && currentBg.startsWith('data:image/');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.palette_outlined,
                color: Color(0xFFFFB74D),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Hình nền ứng dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Danh sách hình nền mẫu
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                // Khối nút "Thêm" tự chọn từ điện thoại
                GestureDetector(
                  onTap: () => _pickCustomImage(context, themeProvider),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isCustomSelected
                          ? const Color(0xFFEC5B13).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCustomSelected
                            ? const Color(0xFFEC5B13)
                            : Colors.white10,
                        width: isCustomSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCustomSelected)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Image(
                                image: themeProvider.backgroundImageProvider!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: themeProvider.foregroundColor.withOpacity(
                              0.6,
                            ),
                            size: 28,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          isCustomSelected ? 'Tự chọn' : 'Thêm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isCustomSelected
                                ? const Color(0xFFEC5B13)
                                : themeProvider.foregroundColor.withOpacity(
                                    0.6,
                                  ),
                            fontSize: 11,
                            fontWeight: isCustomSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Các ảnh mẫu có sẵn
                ..._presetBackgrounds.map((bg) {
                  final name = bg['name']!;
                  final url = bg['url']!;

                  final isSelected =
                      (url.isEmpty && currentBg == null) ||
                      (url.isNotEmpty && currentBg == url);

                  return GestureDetector(
                    onTap: () {
                      if (url.isEmpty) {
                        themeProvider.clearBackgroundImage();
                      } else {
                        themeProvider.setBackgroundImage(url);
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEC5B13)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (url.isEmpty)
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0F172A),
                                      Color(0xFF1E293B),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: Colors.grey[900]);
                                },
                              ),
                            // Lớp phủ mờ tên ảnh
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEC5B13),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ các Provider cần thiết
    final userProvider = context.watch<UserProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
          themeProvider.backgroundColor, // Deep navy or dynamic color
      body: Container(
        decoration: themeProvider.backgroundDecoration,
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
                      _buildBalanceCard(context, userProvider.totalBalance),
                      const SizedBox(height: 20),
                      _buildSectionTitle('TÀI KHOẢN ĐANG SỬ DỤNG'),
                      // Hiển thị danh sách ngân hàng đã liên kết
                      ...userProvider.bankAccounts.map(
                        (bank) => FadeInLeft(
                          child: _buildBankItem(context, bank, userProvider),
                        ),
                      ),
                      if (userProvider.bankAccounts.isEmpty)
                        _buildEmptyState('Chưa có tài khoản liên kết'),
                      const SizedBox(height: 30),
                      _buildSectionTitle('PHƯƠNG THỨC ĐĂNG NHẬP HIỆN TẠI'),
                      _buildLoginMethod(userProvider.email),
                      const SizedBox(height: 30),
                      _buildSectionTitle('BẢO MẬT & ĐĂNG NHẬP'),
                      _buildSecurityItem(Icons.history, 'Đổi mật khẩu', true),
                      _buildSecurityItem(
                        Icons.verified_user_outlined,
                        'Xác thực 2 lớp',
                        false,
                        trailing: _buildBadge('BẬT'),
                      ),
                      _buildSecurityItem(
                        Icons.fingerprint,
                        'Sinh trắc học / FaceID',
                        false,
                        trailing: _buildSwitch(true),
                      ),
                      const SizedBox(height: 30),
                      _buildSectionTitle('GIAO DIỆN & HÌNH NỀN'),
                      _buildBackgroundSelector(context, themeProvider),
                      const SizedBox(height: 30),
                      _buildAiSuggestionCard(),
                      const SizedBox(height: 30),
                      _buildSectionTitle('QUẢN LÝ THIẾT BỊ ĐÃ ĐĂNG NHẬP'),
                      // Thanh công cụ đăng xuất hàng loạt nhiều thiết bị / Batch logout toolbar
                      _buildBatchLogoutToolbar(context, userProvider),
                      // Hiển thị danh sách thiết bị đang đăng nhập
                      ...userProvider.deviceSessions.map(
                        (session) => FadeInUp(
                          child: _buildDeviceItem(
                            context,
                            session,
                            userProvider,
                          ),
                        ),
                      ),
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text(
            'ChiTieuPlus',
            style: TextStyle(
              color: Color(0xFFFFB74D),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
                    ? const NetworkImage(
                            'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
                          )
                          as ImageProvider
                    : (user.photoUrl.startsWith('data:image/')
                              ? MemoryImage(
                                  base64Decode(user.photoUrl.split(',').last),
                                )
                              : NetworkImage(user.photoUrl))
                          as ImageProvider,
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
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00BFA5),
                  size: 20,
                ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
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
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(balance).split('VND')[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                    MaterialPageRoute(
                      builder: (context) => const BalanceAdjustmentScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_note,
                  color: Color(0xFFFFB74D),
                  size: 28,
                ),
                tooltip: 'Cập nhật số dư',
              ),
              Icon(
                Icons.wallet,
                color: Colors.white.withOpacity(0.1),
                size: 50,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng mục hiển thị tài khoản ngân hàng đã liên kết
  Widget _buildBankItem(
    BuildContext context,
    String bankInfo,
    UserProvider userProvider,
  ) {
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
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF00BFA5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
            onPressed: () =>
                _confirmUnlinkBank(context, bankInfo, userProvider),
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
                const Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(
    IconData icon,
    String title,
    bool hasArrow, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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
        style: const TextStyle(
          color: Color(0xFFFFB74D),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tài khoản của bạn có thể an toàn hơn nếu kích hoạt thông báo đăng nhập từ thiết bị lạ.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị thông tin thiết bị đã đăng nhập (hỗ trợ đăng xuất từ xa và đăng xuất hàng loạt)
  /// Displays logged-in device info (supports remote logout and batch logout)
  Widget _buildDeviceItem(
    BuildContext context,
    dynamic session,
    UserProvider userProvider,
  ) {
    final isCurrent = session.isCurrentDevice;
    final isSelected = _selectedDeviceIds.contains(session.id);

    Widget itemContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFEC5B13).withOpacity(0.08)
            : const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFEC5B13) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ô đánh dấu chọn thiết bị (chỉ hiện đối với thiết bị khác thiết bị hiện tại)
          // Custom checkbox for non-current devices
          if (!isCurrent) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDeviceIds.remove(session.id);
                  } else {
                    _selectedDeviceIds.add(session.id);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFEC5B13)
                        : Colors.white38,
                    width: 2,
                  ),
                  color: isSelected
                      ? const Color(0xFFEC5B13)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
          ],
          Icon(
            session.deviceType.toLowerCase().contains('phone')
                ? Icons.smartphone
                : Icons.laptop,
            color: isSelected ? const Color(0xFFEC5B13) : Colors.white70,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrent)
                  const Text(
                    'THIẾT BỊ HIỆN TẠI',
                    style: TextStyle(
                      color: Color(0xFF00BFA5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
              onPressed: () =>
                  _confirmLogoutDevice(context, session, userProvider),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Color(0xFFFF8A65), fontSize: 13),
              ),
            ),
        ],
      ),
    );

    // Cho phép chạm vào toàn bộ khung để chọn/bỏ chọn (chỉ khả dụng với thiết bị khác)
    // Tapping anywhere on the item selects/deselects it if it's not the current device
    if (!isCurrent) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedDeviceIds.remove(session.id);
            } else {
              _selectedDeviceIds.add(session.id);
            }
          });
        },
        child: itemContent,
      );
    }

    return itemContent;
  }

  /// Xây dựng thanh công cụ quản lý đăng xuất hàng loạt (Chọn tất cả / Đăng xuất đã chọn)
  /// Build the batch logout toolbar (Select all / Logout selected)
  Widget _buildBatchLogoutToolbar(
    BuildContext context,
    UserProvider userProvider,
  ) {
    final otherDevices = userProvider.deviceSessions
        .where((s) => !s.isCurrentDevice)
        .toList();
    if (otherDevices.isEmpty) return const SizedBox.shrink();

    final allSelected =
        otherDevices.isNotEmpty &&
        otherDevices.every((s) => _selectedDeviceIds.contains(s.id));
    final selectedCount = _selectedDeviceIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Chọn tất cả / Bỏ chọn tất cả
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selectedDeviceIds.clear();
                } else {
                  _selectedDeviceIds.addAll(otherDevices.map((s) => s.id));
                }
              });
            },
            icon: Icon(
              allSelected ? Icons.deselect_outlined : Icons.select_all_outlined,
              color: const Color(0xFFFFB74D),
              size: 20,
            ),
            label: Text(
              allSelected ? 'Bỏ chọn' : 'Chọn tất cả',
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Trạng thái đã chọn và nút đăng xuất hàng loạt
          if (selectedCount > 0)
            FadeInRight(
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Text(
                    'Đã chọn: $selectedCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _confirmLogoutMultipleDevices(context, userProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout, size: 14),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Hiển thị hộp thoại xác nhận đăng xuất hàng loạt các thiết bị đã chọn
  /// Shows confirmation dialog for batch logout of selected devices
  void _confirmLogoutMultipleDevices(
    BuildContext context,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Đăng xuất các thiết bị đã chọn?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ${_selectedDeviceIds.length} thiết bị đã chọn?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              // Lưu danh sách thiết bị để thực hiện xóa
              final idsToLogout = List<String>.from(_selectedDeviceIds);

              // Đóng hộp thoại trước
              Navigator.pop(context);

              // Thực hiện xóa hàng loạt thiết bị từ xa
              for (final id in idsToLogout) {
                await userProvider.removeDeviceSession(id);
              }

              // Cập nhật lại giao diện và xóa lựa chọn
              setState(() {
                _selectedDeviceIds.clear();
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã đăng xuất các thiết bị đã chọn thành công!',
                    ),
                    backgroundColor: Color(0xFF00BFA5),
                  ),
                );
              }
            },
            child: const Text(
              'Xác nhận đăng xuất',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white24,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận hủy liên kết ngân hàng
  void _confirmUnlinkBank(
    BuildContext context,
    String bankInfo,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Hủy liên kết?',
          style: TextStyle(color: Colors.white),
        ),
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
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận đăng xuất thiết bị khác
  void _confirmLogoutDevice(
    BuildContext context,
    dynamic session,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Đăng xuất thiết bị?',
          style: TextStyle(color: Colors.white),
        ),
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
              setState(() {
                _selectedDeviceIds.remove(session.id);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
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
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
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
