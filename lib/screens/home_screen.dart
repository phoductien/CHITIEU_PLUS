import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/screens/notification_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chitieu_plus/screens/ocr_scan_screen.dart';
import 'package:chitieu_plus/widgets/main_drawer.dart';
import 'package:chitieu_plus/widgets/mini_ai_chat_widget.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';

import 'package:chitieu_plus/screens/tabs/home_tab.dart';
import 'package:chitieu_plus/screens/tabs/transaction_tab.dart';
import 'package:chitieu_plus/screens/tabs/budget_tab.dart';
import 'package:chitieu_plus/screens/tabs/report_tab.dart';

class HomeScreen extends StatefulWidget {
  final String? welcomeMessage;
  const HomeScreen({super.key, this.welcomeMessage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAiOverlayOpen = false;

  String _getAiGreeting(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Chào bạn! Tôi có thể giúp gì cho\nngân sách của bạn hôm nay?';
      case 1:
        return 'Giao dịch hôm nay thế nào?\nĐể tôi tóm tắt giúp nhé!';
      case 2:
        return 'Lên kế hoạch thông minh?\nĐể tôi hỗ trợ bạn!';
      case 3:
        return 'Phân tích chi tiêu của bạn?\nTôi luôn sẵn sàng hỗ trợ!';
      default:
        return 'Chào bạn! Tôi có thể giúp gì cho bạn?';
    }
  }

  late StreamSubscription<NotificationModel> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null);

    // Restore session state
    final session = context.read<AppSessionProvider>();
    _currentIndex = session.homeTabIndex;
    session.setLastRoute('home');

    _pageController = PageController(initialPage: _currentIndex);

    // Listen for new notifications
    final notificationProvider = context.read<NotificationProvider>();
    _notificationSubscription = notificationProvider.onNewNotification.listen((
      notification,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification.color.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            notification.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Xem',
                        style: TextStyle(color: Color(0xFFFF6D00)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });

    if (widget.welcomeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.welcomeMessage!),
              backgroundColor: const Color(0xFFFF6D00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _showExitDialog() async {
    final themeProvider = context.read<ThemeProvider>();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: themeProvider.secondaryColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: themeProvider.borderColor),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Color(0xFFFF6D00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thoát ứng dụng',
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn đóng ứng dụng ChiTieuPlus và kết thúc phiên làm việc không?',
              style: TextStyle(
                color: themeProvider.foregroundColor.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: themeProvider.foregroundColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thoát',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          // Thoát hoàn toàn ứng dụng và tiến trình terminal (tương đương nhấn 'q')
          exit(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MainDrawer(),
        backgroundColor: themeProvider.backgroundColor,
        body: Container(
          decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  context.read<AppSessionProvider>().setHomeTabIndex(index);
                },
                children: [
                  HomeTab(
                    onTabChange: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const TransactionTab(),
                  const BudgetTab(),
                  const ReportTab(),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 85, // Nằm ngay trên tab điều hướng
                child: SafeArea(
                  child: ZoomIn(
                    duration: const Duration(milliseconds: 300),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAiOverlayOpen = !_isAiOverlayOpen;
                            });
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEC5B13,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        if (!_isAiOverlayOpen)
                          Positioned(
                            top: -55,
                            right: 15,
                            child: FadeInUp(
                              key: ValueKey<int>(
                                _currentIndex,
                              ), // Re-animate when tab changes
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 500),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: themeProvider.secondaryColor.withValues(
                                    alpha: 0.95,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  border: Border.all(
                                    color: themeProvider.borderColor,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getAiGreeting(_currentIndex),
                                  style: TextStyle(
                                    color: themeProvider.foregroundColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isAiOverlayOpen)
                Positioned(
                  bottom: 160, // right above FAB
                  right: 16,
                  child: SafeArea(
                    child: Material(
                      type: MaterialType.transparency,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: MiniAiChatWidget(
                          onClose: () {
                            setState(() {
                              _isAiOverlayOpen = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(themeProvider, languageProvider),
      ),
    );
  }

  Widget _buildBottomNavBar(
    ThemeProvider themeProvider,
    LanguageProvider languageProvider,
  ) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Glass Background
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: themeProvider.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.grid_view_rounded,
                  languageProvider.translate('tab_home'),
                  themeProvider,
                ),
                _buildNavItem(
                  1,
                  Icons.receipt_long_rounded,
                  languageProvider.translate('tab_transactions'),
                  themeProvider,
                ),
                const SizedBox(width: 60), // Space for AI Scan button
                _buildNavItem(
                  2,
                  Icons.account_balance_wallet_rounded,
                  languageProvider.translate('tab_budget'),
                  themeProvider,
                ),
                _buildNavItem(
                  3,
                  Icons.analytics_rounded,
                  languageProvider.translate('tab_report'),
                  themeProvider,
                ),
              ],
            ),
          ),
          // AI Scan Button (Floating)
          Positioned(
            top: -15,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OcrScanScreen(),
                  ),
                );
                if (result != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddTransactionScreen(initialOcrResult: result),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.backgroundColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC5B13).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    languageProvider.translate('ai_scan'),
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.9,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEC5B13).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFEC5B13)
                  : themeProvider.foregroundColor.withValues(alpha: 0.4),
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFEC5B13)
                  : themeProvider.foregroundColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: TRANG CHỦ ---
