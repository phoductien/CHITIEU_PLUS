import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/screens/notification_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/screens/user_profile_screen.dart';
import 'package:chitieu_plus/screens/deposit_screen.dart';
import 'package:chitieu_plus/screens/qr_scanner_screen.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:chitieu_plus/providers/saving_goal_provider.dart';
import 'package:chitieu_plus/widgets/saving_goal_card.dart';
import 'package:chitieu_plus/screens/saving_goals_list_screen.dart';
import 'package:chitieu_plus/screens/balance_adjustment_screen.dart';


class HomeTab extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeTab({super.key, this.onTabChange});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  double _totalBalance = 0;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _syncController;
  Timer? _lastSyncRefreshTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Refresh "time ago" every 30 seconds
    _lastSyncRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _lastSyncRefreshTimer?.cancel();
    _syncController.dispose();
    super.dispose();
  }

  String _getRelativeSyncTime(DateTime? lastSyncTime) {
    if (lastSyncTime == null) return 'Chưa đồng bộ';

    final diff = DateTime.now().difference(lastSyncTime);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return DateFormat('dd/MM/yyyy').format(lastSyncTime);
  }

  String _getFormattedDateTime() {
    final formatter = DateFormat('EEEE, dd/MM/yyyy • HH:mm', 'vi');
    String formatted = formatter.format(_currentTime);
    final parts = formatted.split(', ');
    if (parts.length > 1) {
      final dayNames = parts[0]
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
          .join(' ');
      return '$dayNames, ${parts[1]}';
    }
    return formatted;
  }

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng,';
    } else if (hour == 12) {
      return 'Chào buổi trưa,';
    } else if (hour < 18) {
      return 'Chào buổi chiều,';
    } else {
      return 'Chào buổi tối,';
    }
  }

  void _calculateData(List<TransactionModel> transactions) {
    double balance = 0;
    for (var tx in transactions) {
      if (tx.wallet != 'main') continue; // Chỉ tính toán cho ví chính
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    _totalBalance = balance;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final transactions = transactionProvider.transactions;
    final isLoading = transactionProvider.isLoading;

    // Recalculate data whenever transactions change
    _calculateData(transactions);

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 600 ? screenWidth * 0.1 : 20.0;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header Premium
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.secondaryColor.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeProvider.borderColor,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.menu_rounded,
                              color: themeProvider.foregroundColor,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreetingText(),
                              style: TextStyle(
                                color: themeProvider.foregroundColor.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              userProvider.name.isNotEmpty
                                  ? userProvider.name
                                  : 'Khách',
                              style: TextStyle(
                                color: themeProvider.foregroundColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEC5B13,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getFormattedDateTime(),
                                style: const TextStyle(
                                  color: Color(0xFFEC5B13),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          ),
                          badgeCount: notificationProvider.unreadCount,
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderButton(
                          icon: Icons.qr_code_scanner_rounded,
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final result = await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            );
                            if (result != null && mounted) {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(
                                    initialQrResult: result,
                                  ),
                                ),
                              );
                            }
                          },
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserProfileScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEC5B13),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFFFD180),
                              backgroundImage: userProvider.photoUrl.isEmpty
                                  ? const NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
                                        )
                                        as ImageProvider
                                  : (userProvider.photoUrl.startsWith(
                                              'data:image/',
                                            )
                                            ? MemoryImage(
                                                base64Decode(
                                                  userProvider.photoUrl
                                                      .split(',')
                                                      .last,
                                                ),
                                              )
                                            : NetworkImage(
                                                userProvider.photoUrl,
                                              ))
                                        as ImageProvider,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Wallet Card Premium
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E293B), // Navy 800
                        Color(0xFF0F172A), // Navy 900
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFEC5B13).withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: userProvider.bankAccounts.isNotEmpty 
                                        ? Colors.green.withOpacity(0.1)
                                        : const Color(0xFFEC5B13).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      userProvider.bankAccounts.isNotEmpty 
                                        ? Icons.account_balance_rounded
                                        : Icons.account_balance_wallet_rounded,
                                      color: userProvider.bankAccounts.isNotEmpty 
                                        ? Colors.greenAccent
                                        : const Color(0xFFEC5B13),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProvider.bankAccounts.isNotEmpty
                                            ? 'TÀI KHOẢN LIÊN KẾT'
                                            : (userProvider.isGuest
                                                ? languageProvider.translate('wallet_demo')
                                                : languageProvider.translate('wallet_main')),
                                        style: TextStyle(
                                          color: themeProvider.foregroundColor
                                              .withOpacity(0.4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        userProvider.bankAccounts.isNotEmpty
                                            ? userProvider.bankAccounts.first
                                            : 'Ví chính',
                                        style: TextStyle(
                                          color: themeProvider.foregroundColor
                                              .withOpacity(0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                      onTap: () async {
                                        if (_syncController.isAnimating) return;
                                        final messenger = ScaffoldMessenger.of(context);
                                        _syncController.repeat();
                                        try {
                                          await context
                                              .read<TransactionProvider>()
                                              .syncDataWithFirestore();
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đồng bộ dữ liệu thành công!',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('Lỗi: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          _syncController.stop();
                                          _syncController.reset();
                                        }
                                      },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getRelativeSyncTime(
                                            transactionProvider.lastSyncTime,
                                          ),
                                          style: TextStyle(
                                            color: themeProvider.foregroundColor
                                                .withOpacity(0.35),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        RotationTransition(
                                          turns: _syncController,
                                          child: Icon(
                                            Icons.sync_rounded,
                                            color: themeProvider.foregroundColor
                                                .withOpacity(0.5),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _isBalanceVisible =
                                          !_isBalanceVisible,
                                    ),
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: themeProvider.foregroundColor
                                          .withOpacity(0.5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.more_horiz_rounded,
                                    color: themeProvider.foregroundColor
                                        .withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _isBalanceVisible
                                    ? NumberFormat(
                                        '#,###',
                                      ).format(_totalBalance)
                                    : '*********',
                                style: TextStyle(
                                  color: themeProvider.foregroundColor,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
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
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DepositScreen(),
                                  ),
                                ),
                                child: _buildActionChip(
                                  icon: Icons.add_circle_outline_rounded,
                                  label: 'Nạp tiền',
                                  color: const Color(0xFFEC5B13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                                child: _buildActionChip(
                                  icon: Icons.history_rounded,
                                  label: 'Lịch sử',
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BalanceAdjustmentScreen(),
                                  ),
                                ),
                                child: _buildActionChip(
                                  icon: Icons.edit_note_rounded,
                                  label: 'Cập nhật',
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Analysis QuickView
              _buildAnalysisSection(themeProvider, transactions),
              const SizedBox(height: 30),

              // Saving Goals Section
              _buildSavingGoalsSection(context, themeProvider),
              const SizedBox(height: 30),

              _buildSectionHeader('Giao dịch gần đây', 'Tất cả', themeProvider),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEC5B13)),
                )
              else
                _buildTransactionList(
                  transactions.where((tx) => tx.note != 'Nạp qua Ví dùng thử').toList(),
                  themeProvider,
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String? actionText,
    ThemeProvider themeProvider, {
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap ?? () {
              if (actionText == 'Tất cả' || title == 'Giao dịch gần đây') {
                widget.onTabChange?.call(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  color: Color(0xFFEC5B13),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else if (title == 'Giao dịch gần đây')
          TextButton(
            onPressed: () => widget.onTabChange?.call(1),
            child: const Text(
              'Tất cả',
              style: TextStyle(
                color: Color(0xFFEC5B13),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
    required ThemeProvider themeProvider,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: IconButton(
            icon: Icon(icon, color: themeProvider.foregroundColor, size: 22),
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEC5B13),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingGoalsSection(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Mục tiêu tiết kiệm',
          'Tất cả',
          themeProvider,
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavingGoalsListScreen()),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<SavingGoalProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF05D15))),
              );
            }

            if (provider.goals.isEmpty) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavingGoalsListScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: themeProvider.secondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeProvider.borderColor, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.add_task_rounded, color: themeProvider.foregroundColor.withOpacity(0.3), size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có mục tiêu. Nhấn để tạo mới!',
                        style: TextStyle(color: themeProvider.foregroundColor.withOpacity(0.5), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: provider.goals.length,
                itemBuilder: (context, index) {
                  return SavingGoalCard(
                    goal: provider.goals[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavingGoalsListScreen()),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisSection(
    ThemeProvider themeProvider,
    List<TransactionModel> transactions,
  ) {
    double income = 0;
    double expense = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    double total = income + expense;
    double expensePercent = total > 0 ? expense / total : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân tích chi tiêu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onTabChange?.call(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC5B13).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Xem báo cáo',
                        style: TextStyle(
                          color: Color(0xFFEC5B13),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFEC5B13),
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisItem(
                      'Thu nhập',
                      income,
                      Colors.green,
                      themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildAnalysisItem(
                      'Chi tiêu',
                      expense,
                      const Color(0xFFEC5B13),
                      themeProvider,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 35,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFFEC5B13),
                              value: expensePercent * 100,
                              radius: 12,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: Colors.green.withOpacity(0.2),
                              value: (1 - expensePercent) * 100,
                              radius: 8,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(expensePercent * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Đã chi',
                            style: TextStyle(
                              color: themeProvider.foregroundColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(
    String label,
    double amount,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: themeProvider.foregroundColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat('#,###').format(amount)}đ',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
    List<TransactionModel> transactions,
    ThemeProvider themeProvider,
  ) {
    if (transactions.isEmpty) {
      return FadeInRight(
        duration: const Duration(milliseconds: 600),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48,
                color: themeProvider.foregroundColor.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có dữ liệu',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.take(5).length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;

        return FadeInRight(
          delay: Duration(milliseconds: 100 * index),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.borderColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isIncome ? Colors.green : const Color(0xFFEC5B13))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.keyboard_double_arrow_down_rounded
                        : Icons.keyboard_double_arrow_up_rounded,
                    color: isIncome ? Colors.green : const Color(0xFFEC5B13),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: TextStyle(
                          color: themeProvider.foregroundColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM, HH:mm', 'vi').format(tx.date),
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                      style: TextStyle(
                        color: isIncome
                            ? Colors.greenAccent
                            : themeProvider.foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (tx.category.isNotEmpty)
                      Text(
                        tx.category,
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- TAB 2: GIAO DỊCH ---

