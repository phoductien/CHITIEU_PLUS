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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitieu_plus/widgets/auth_wrapper.dart';
import 'package:chitieu_plus/screens/ai_chat_screen.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chitieu_plus/screens/ocr_scan_screen.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/services/transaction_service.dart';
import 'package:chitieu_plus/utils/download_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:chitieu_plus/screens/terms_and_privacy_screen.dart';
import 'package:chitieu_plus/screens/budget_settings_screen.dart';
import 'package:chitieu_plus/widgets/custom_date_picker.dart';
import 'package:chitieu_plus/widgets/main_drawer.dart';
import 'package:chitieu_plus/screens/user_profile_screen.dart';

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

  String _getAiGreeting(int tabIndex) {
    switch (tabIndex) {
      case 0: return 'Chào bạn! Tôi có thể giúp gì cho\nngân sách của bạn hôm nay?';
      case 1: return 'Giao dịch hôm nay thế nào?\nĐể tôi tóm tắt giúp nhé!';
      case 2: return 'Lên kế hoạch thông minh?\nĐể tôi hỗ trợ bạn!';
      case 3: return 'Phân tích chi tiêu của bạn?\nTôi luôn sẵn sàng hỗ trợ!';
      default: return 'Chào bạn! Tôi có thể giúp gì cho bạn?';
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null);
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.welcomeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.welcomeMessage!),
              backgroundColor: const Color(0xFFFF6D00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      backgroundColor: themeProvider.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: Stack(
          children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              HomeTab(),
              TransactionTab(),
              BudgetTab(),
              ReportTab(),
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
                    FloatingActionButton(
                      heroTag: 'ai_assistant_btn',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AiChatScreen()),
                        );
                      },
                      backgroundColor: const Color(0xFFEC5B13), // primary orange
                      elevation: 8,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
                    ),
                    Positioned(
                      top: -55,
                      right: 15,
                      child: FadeInUp(
                        key: ValueKey<int>(_currentIndex), // Re-animate when tab changes
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: themeProvider.secondaryColor.withValues(alpha: 0.95),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(4),
                            ),
                            border: Border.all(color: themeProvider.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            _getAiGreeting(_currentIndex),
                            style: TextStyle(color: themeProvider.foregroundColor, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: _buildBottomNavBar(themeProvider, languageProvider),
    );
  }

  Widget _buildBottomNavBar(ThemeProvider themeProvider, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: themeProvider.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildNavItem(0, Icons.home_filled, languageProvider.translate('tab_home'), themeProvider),
          _buildNavItem(1, Icons.receipt_long_rounded, languageProvider.translate('tab_transactions'), themeProvider),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const OcrScanScreen()),
                );
                if (result != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(initialOcrResult: result),
                    ),
                  );
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    transform: Matrix4.translationValues(0.0, -24.0, 0.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC5B13),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeProvider.secondaryColor, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ]
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Text(
                      languageProvider.translate('ai_scan'),
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNavItem(2, Icons.account_balance_wallet_rounded, languageProvider.translate('tab_budget'), themeProvider),
          _buildNavItem(3, Icons.analytics_rounded, languageProvider.translate('tab_report'), themeProvider),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeProvider themeProvider) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFEC5B13) : themeProvider.foregroundColor.withValues(alpha: 0.4), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFEC5B13) : themeProvider.foregroundColor.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: TRANG CHỦ ---
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isBalanceVisible = true;
  double _totalBalance = 0;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() { _currentTime = DateTime.now(); });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getFormattedDateTime() {
    final formatter = DateFormat('EEEE, dd/MM/yyyy • HH:mm', 'vi');
    String formatted = formatter.format(_currentTime);
    final parts = formatted.split(', ');
    if (parts.length > 1) {
      final dayNames = parts[0].split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '').join(' ');
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
              const SizedBox(height: 20),
              // Header
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu_rounded, color: themeProvider.foregroundColor, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreetingText(), style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 13)),
                            Text(
                              userProvider.name.isNotEmpty ? userProvider.name : 'Khách',
                              style: TextStyle(color: themeProvider.foregroundColor, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getFormattedDateTime(),
                              style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_rounded, color: themeProvider.foregroundColor, size: 28),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                );
                              },
                            ),
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFFFF6D00), shape: BoxShape.circle),
                                  child: Text(
                                    notificationProvider.unreadCount > 9 ? '9+' : notificationProvider.unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFFFD180),
                            backgroundImage: userProvider.photoUrl.isEmpty 
                                ? const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix') as ImageProvider
                                : (userProvider.photoUrl.startsWith('data:image/') 
                                    ? MemoryImage(base64Decode(userProvider.photoUrl.split(',').last)) 
                                    : NetworkImage(userProvider.photoUrl)) as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Wallet Card
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeProvider.secondaryColor,
                        themeProvider.secondaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeProvider.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode 
                          ? Colors.black.withValues(alpha: 0.3) 
                          : const Color(0xFF0F172A).withValues(alpha: 0.08), 
                        blurRadius: 20, 
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(languageProvider.translate('wallet'), style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 14)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                            child: Icon(
                              _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: themeProvider.foregroundColor.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _isBalanceVisible ? NumberFormat('#,###').format(_totalBalance) : '*********',
                            style: TextStyle(color: themeProvider.foregroundColor, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Text('đ', style: TextStyle(color: Color(0xFFFF6D00), fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionHeader('Giao dịch gần đây', 'Tất cả', themeProvider),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFFEC5B13)))
              else
                _buildTransactionList(transactions, themeProvider),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionText, ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 20, fontWeight: FontWeight.bold)),
        if (actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: themeProvider.secondaryColor, borderRadius: BorderRadius.circular(8)),
            child: Text(actionText, style: const TextStyle(color: Color(0xFFF05D15), fontSize: 12, fontWeight: FontWeight.bold)),
          )
        else if (title == 'Giao dịch gần đây')
          TextButton(
            onPressed: () {},
            child: const Text('Tất cả', style: TextStyle(color: Color(0xFFF05D15), fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }



  Widget _buildTransactionList(List<TransactionModel> transactions, ThemeProvider themeProvider) {
    if (transactions.isEmpty) {
      return FadeInRight(
        duration: const Duration(milliseconds: 600),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeProvider.borderColor),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: themeProvider.foregroundColor.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'Không có dữ liệu',
                style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: transactions.take(5).map((tx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeProvider.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (tx.type == TransactionType.income ? Colors.green : const Color(0xFFEC5B13)).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tx.type == TransactionType.income ? Icons.trending_up : Icons.trending_down,
                    color: tx.type == TransactionType.income ? Colors.green : const Color(0xFFEC5B13),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.date), style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${tx.type == TransactionType.income ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                  style: TextStyle(
                    color: tx.type == TransactionType.income ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- TAB 2: GIAO DỊCH ---
class TransactionTab extends StatefulWidget {
  const TransactionTab({super.key});

  @override
  State<TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<TransactionTab> {
  String _activeFilter = 'Hôm nay';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final transactionService = TransactionService();
      
      String format = 'db';
      if (kIsWeb) {
        if (!context.mounted) return;
        final chosen = await showDialog<String>(
          context: context,
          builder: (dialogCtx) {
            final theme = dialogCtx.read<ThemeProvider>();
            return AlertDialog(
              backgroundColor: theme.secondaryColor,
              title: Text('Chọn định dạng xuất', style: TextStyle(color: theme.foregroundColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.data_object_rounded, color: const Color(0xFFEC5B13)),
                    title: Text('JSON', style: TextStyle(color: theme.foregroundColor, fontWeight: FontWeight.bold)),
                    subtitle: Text('Dùng cho dữ liệu khối', style: TextStyle(color: theme.foregroundColor.withValues(alpha: 0.5), fontSize: 12)),
                    onTap: () => Navigator.pop(dialogCtx, 'json'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.table_chart_rounded, color: Colors.green),
                    title: Text('CSV', style: TextStyle(color: theme.foregroundColor, fontWeight: FontWeight.bold)),
                    subtitle: Text('Dễ dàng mở bằng Excel', style: TextStyle(color: theme.foregroundColor.withValues(alpha: 0.5), fontSize: 12)),
                    onTap: () => Navigator.pop(dialogCtx, 'csv'),
                  ),
                ],
              ),
            );
          },
        );
        if (chosen == null) return;
        format = chosen;
      }

      final fileExt = kIsWeb ? format : 'db';
      final fileTypeLabel = kIsWeb ? format.toUpperCase() : 'SQLite';
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang chuẩn bị dữ liệu $fileTypeLabel...')),
      );

      final bytes = await transactionService.exportAllToSqliteBytes(webFormat: format);
      final fileName = 'chitieu_plus_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$fileExt';
      
      await DownloadHelper.instance.downloadFile(bytes, fileName);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb ? 'Đang tải xuống: $fileName' : 'Đã xuất database thành công: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xuất dữ liệu: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isLoading = transactionProvider.isLoading;
    final allTransactions = transactionProvider.transactions;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(themeProvider),
            _buildSearchAndFilters(themeProvider),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC5B13)))
                : _buildGroupedTransactionList(allTransactions, themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: themeProvider.foregroundColor),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            ),
            const SizedBox(width: 12),
            Text(
              'Đã chọn ${_selectedIds.length}',
              style: TextStyle(color: themeProvider.foregroundColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomDatePicker(
                  initialStartDate: _customStartDate,
                  initialEndDate: _customEndDate,
                  onApply: (start, end) {
                    setState(() {
                      _customStartDate = start;
                      _customEndDate = end;
                      _activeFilter = 'Tùy chỉnh';
                    });
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 20),
            ),
          ),
          Text(
            'Giao dịch',
            style: TextStyle(color: themeProvider.foregroundColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEC5B13),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC5B13).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    final count = ids.length;
    final themeProvider = context.read<ThemeProvider>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.secondaryColor,
        title: Text('Xác nhận xóa', style: TextStyle(color: themeProvider.foregroundColor)),
        content: Text('Bạn có chắc chắn muốn xóa $count giao dịch đã chọn?', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TransactionProvider>().deleteTransactions(ids);
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa $count giao dịch')),
        );
      }
    }
  }

  Widget _buildSearchAndFilters(ThemeProvider themeProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: themeProvider.foregroundColor),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm giao dịch...',
                hintStyle: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search_rounded, color: themeProvider.foregroundColor.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _exportDatabase(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeProvider.borderColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.output_rounded, color: themeProvider.foregroundColor.withValues(alpha: 0.7), size: 14),
                    const SizedBox(width: 6),
                    Text('Xuất file', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('Hôm nay', themeProvider),
              _buildFilterChip('Tuần này', themeProvider),
              _buildFilterChip('Tháng này', themeProvider),
              _buildFilterChip('Tùy chỉnh', themeProvider),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilterChip(String label, ThemeProvider themeProvider) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC5B13) : themeProvider.secondaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : themeProvider.foregroundColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionList(List<TransactionModel> transactions, ThemeProvider themeProvider) {
    // Basic search filtering
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final filtered = transactions.where((tx) {
      final matchesQuery = tx.title.toLowerCase().contains(query) || tx.category.toLowerCase().contains(query);
      
      bool matchesDate = true;
      if (_activeFilter == 'Hôm nay') {
        matchesDate = tx.date.year == today.year && tx.date.month == today.month && tx.date.day == today.day;
      } else if (_activeFilter == 'Tuần này') {
        matchesDate = tx.date.isAfter(weekStart.subtract(const Duration(seconds: 1)));
      } else if (_activeFilter == 'Tháng này') {
        matchesDate = tx.date.year == monthStart.year && tx.date.month == monthStart.month;
      } else if (_activeFilter == 'Tùy chỉnh' && _customStartDate != null && _customEndDate != null) {
        final start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        final end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
        matchesDate = tx.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                      tx.date.isBefore(end.add(const Duration(seconds: 1)));
      }
      
      return matchesQuery && matchesDate;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: themeProvider.foregroundColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('Không có dữ liệu', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.3))),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (var tx in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTxs = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        double dayTotal = 0;
        for (var tx in dayTxs) {
          if (tx.type == TransactionType.expense) {
            dayTotal -= tx.amount;
          } else {
            dayTotal += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getFriendlyDate(date),
                    style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${NumberFormat('#,###').format(dayTotal)}đ',
                    style: TextStyle(
                      color: dayTotal >= 0 ? Colors.green.withValues(alpha: 0.8) : themeProvider.foregroundColor.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...dayTxs.map((tx) => _buildTransactionCard(tx, themeProvider)),
          ],
        );
      },
    );
  }

  String _getFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    String prefix = '';
    if (txDate == today) {
      prefix = 'HÔM NAY, ';
    } else if (txDate == yesterday) {
      prefix = 'HÔM QUA, ';
    }

    return '$prefix${DateFormat('d THÁNG M').format(date).toUpperCase()}';
  }

  Widget _buildTransactionCard(TransactionModel tx, ThemeProvider themeProvider) {
    final isSelected = _selectedIds.contains(tx.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedIds.add(tx.id);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(tx.id);
              if (_selectedIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIds.add(tx.id);
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFEC5B13).withValues(alpha: 0.1)
              : themeProvider.secondaryColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFEC5B13).withValues(alpha: 0.5)
                : themeProvider.borderColor,
          ),
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFFEC5B13) : themeProvider.foregroundColor.withValues(alpha: 0.2),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(tx.category).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _getCategoryIcon(tx.category),
                    color: _getCategoryColor(tx.category),
                    size: 20,
                  ),
                  if (tx.isPinned)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Icon(Icons.push_pin_rounded, color: Colors.yellowAccent, size: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('HH:mm').format(tx.date)} • ${tx.category}',
                    style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.type == TransactionType.income ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                  style: TextStyle(
                    color: tx.type == TransactionType.income ? const Color(0xFF4ADE80) : themeProvider.foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: themeProvider.foregroundColor.withValues(alpha: 0.3), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 120),
                    color: themeProvider.secondaryColor,
                    onSelected: (value) async {
                      if (value == 'pin') {
                        await context.read<TransactionProvider>().togglePin(tx.id, tx.isPinned);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: themeProvider.secondaryColor,
                            title: Text('Xác nhận xóa', style: TextStyle(color: themeProvider.foregroundColor)),
                            content: Text('Giao dịch này sẽ bị xóa vĩnh viễn.', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7))),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await context.read<TransactionProvider>().deleteTransaction(tx.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(tx.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 10),
                            Text(tx.isPinned ? 'Bỏ ghim' : 'Ghim', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 10),
                            Text('Xóa', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống': return Icons.restaurant_rounded;
      case 'Mua sắm': return Icons.shopping_bag_rounded;
      case 'Di chuyển': return Icons.directions_car_rounded;
      case 'Lương': return Icons.account_balance_wallet_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống': return const Color(0xFFF97316);
      case 'Mua sắm': return const Color(0xFF3B82F6);
      case 'Di chuyển': return const Color(0xFFA855F7);
      case 'Lương': return const Color(0xFF22C55E);
      default: return Colors.blueGrey;
    }
  }
}

// --- TAB 3: NGÂN SÁCH ---
class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  double _budgetLimit = 5000000;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final allTxs = transactionProvider.transactions;
    
    // Calculate current month's expense
    final now = DateTime.now();
    double currentMonthExpense = 0;
    
    final Map<String, double> catSpent = {
      'Ăn uống': 0, 'Mua sắm': 0, 'Di chuyển': 0, 'Hóa đơn': 0, 'Khác': 0
    };

    for (var tx in allTxs) {
      if (tx.type == TransactionType.expense && tx.date.year == now.year && tx.date.month == now.month) {
        currentMonthExpense += tx.amount;
        if (catSpent.containsKey(tx.category)) {
          catSpent[tx.category] = catSpent[tx.category]! + tx.amount;
        } else {
          catSpent['Khác'] = catSpent['Khác']! + tx.amount;
        }
      }
    }

    final double overBudget = currentMonthExpense > _budgetLimit ? currentMonthExpense - _budgetLimit : 0;
    final bool isOver = overBudget > 0;
    final double percent = _budgetLimit > 0 ? (currentMonthExpense / _budgetLimit).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ngân sách chi tiêu', style: TextStyle(color: themeProvider.foregroundColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () async {
                      final newLimit = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BudgetSettingsScreen()),
                      );
                      if (newLimit != null && newLimit is double && mounted) {
                        setState(() {
                          _budgetLimit = newLimit;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Điều chỉnh', style: TextStyle(color: Color(0xFFF05D15), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Đã tiêu', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 14)),
                              if (isOver)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Vượt ngân sách', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'đ ${NumberFormat('#,###').format(currentMonthExpense)}',
                            style: TextStyle(
                              color: isOver ? Colors.redAccent : themeProvider.foregroundColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : const Color(0xFFF05D15)),
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ngân sách: đ ${NumberFormat('#,###').format(_budgetLimit)}', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 12)),
                              Text(isOver ? 'Vượt quá đ ${NumberFormat('#,###').format(overBudget)}' : 'Còn lại đ ${NumberFormat('#,###').format(_budgetLimit - currentMonthExpense)}', 
                                style: TextStyle(color: isOver ? Colors.redAccent : const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('CHI TIẾT HẠNG MỤC', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    ...catSpent.keys.map((cat) {
                       if (catSpent[cat]! == 0) return const SizedBox.shrink();
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 16),
                         child: Row(
                           children: [
                             Container(
                               width: 40, height: 40,
                               decoration: BoxDecoration(color: themeProvider.foregroundColor.withValues(alpha: 0.05), shape: BoxShape.circle),
                               child: Icon(Icons.category, color: themeProvider.foregroundColor.withValues(alpha: 0.5), size: 20),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(cat, style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 4),
                                   ClipRRect(
                                     borderRadius: BorderRadius.circular(2),
                                     child: LinearProgressIndicator(
                                       value: _budgetLimit > 0 ? (catSpent[cat]! / _budgetLimit).clamp(0.0, 1.0) : 0,
                                       backgroundColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                                       valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                       minHeight: 4,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(width: 16),
                             Text('đ ${NumberFormat('#,###').format(catSpent[cat])}', style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold)),
                           ],
                         ),
                       );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 4: BÁO CÁO ---
class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final transactions = transactionProvider.transactions;
    
    // Calculate Chart Data
    Map<String, double> catTotals = {'Ăn uống': 0, 'Mua sắm': 0, 'Di chuyển': 0, 'Khác': 0};
    List<double> last7Days = List.filled(7, 0.0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        if (catTotals.containsKey(tx.category)) {
          catTotals[tx.category] = catTotals[tx.category]! + tx.amount;
        } else {
          catTotals['Khác'] = catTotals['Khác']! + tx.amount;
        }
        int dayDiff = today.difference(tx.date).inDays;
        if (dayDiff >= 0 && dayDiff < 7) {
          int index = (tx.date.weekday - 1);
          last7Days[index] += tx.amount;
        }
      }
    }

    double maxVal = last7Days.reduce((a, b) => a > b ? a : b);
    List<double> barValues = maxVal > 0 ? last7Days.map((v) => (v / maxVal) * 20).toList() : List.filled(7, 0.0);
    double totalExpense = catTotals.values.reduce((a, b) => a + b);
    List<double> pieValues = totalExpense > 0 ? [
      (catTotals['Ăn uống']! / totalExpense) * 100,
      (catTotals['Mua sắm']! / totalExpense) * 100,
      (catTotals['Di chuyển']! / totalExpense) * 100,
      (catTotals['Khác']! / totalExpense) * 100,
    ] : List.filled(4, 0.0);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Báo cáo tài chính', style: TextStyle(color: themeProvider.foregroundColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: themeProvider.secondaryColor, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text('CƠ CẤU CHI TIÊU', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: _buildDonutChart(themeProvider, pieValues),
                    ),
                    const SizedBox(height: 35),
                    Text('XU HƯỚNG CI TIÊU (7 NGÀY)', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: _buildBarChart(themeProvider, barValues),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(ThemeProvider themeProvider, List<double> pieValues) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 140,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 45,
                    sections: [
                      ...(pieValues[0] == 0 && pieValues[1] == 0 && pieValues[2] == 0 && pieValues[3] == 0 
                        ? [PieChartSectionData(color: themeProvider.foregroundColor.withValues(alpha: 0.1), value: 100, radius: 16, showTitle: false)]
                        : [
                            PieChartSectionData(color: const Color(0xFFFF6D00), value: pieValues[0], radius: 18, showTitle: false),
                            PieChartSectionData(color: Colors.blue, value: pieValues[1], radius: 16, showTitle: false),
                            PieChartSectionData(color: Colors.green, value: pieValues[2], radius: 14, showTitle: false),
                            PieChartSectionData(color: Colors.yellow, value: pieValues[3], radius: 12, showTitle: false),
                          ]),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 1200),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Tổng', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12)),
                      Text(pieValues[0] == 0 && pieValues[1] == 0 ? '0%' : '100%', style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildAllocationItem('Ăn uống', pieValues[0] == 0 ? '0%' : '${pieValues[0].toStringAsFixed(0)}%', const Color(0xFFFF6D00), themeProvider),
              _buildAllocationItem('Mua sắm', pieValues[1] == 0 ? '0%' : '${pieValues[1].toStringAsFixed(0)}%', Colors.blue, themeProvider),
              _buildAllocationItem('Di chuyển', pieValues[2] == 0 ? '0%' : '${pieValues[2].toStringAsFixed(0)}%', Colors.green, themeProvider),
              _buildAllocationItem('Khác', pieValues[3] == 0 ? '0%' : '${pieValues[3].toStringAsFixed(0)}%', Colors.yellow, themeProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationItem(String title, String percent, Color color, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7), fontSize: 14)),
            ],
          ),
          Text(percent, style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeProvider themeProvider, List<double> barValues) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(days[value.toInt() % days.length], style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarData(0, barValues[0], themeProvider),
          _makeBarData(1, barValues[1], themeProvider),
          _makeBarData(2, barValues[2], themeProvider),
          _makeBarData(3, barValues[3], themeProvider),
          _makeBarData(4, barValues[4], themeProvider),
          _makeBarData(5, barValues[5], themeProvider),
          _makeBarData(6, barValues[6], themeProvider),
        ],
      ),
      swapAnimationDuration: const Duration(milliseconds: 1000),
      swapAnimationCurve: Curves.easeOutQuart,
    );
  }

  BarChartGroupData _makeBarData(int x, double y, ThemeProvider themeProvider) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: themeProvider.foregroundColor.withValues(alpha: 0.1),
          width: 14,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: themeProvider.backgroundColor.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

// --- TAB 4: CÀI ĐẶT ---
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
                    style: TextStyle(color: themeProvider.foregroundColor, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(width: 40),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        color: themeProvider.secondaryColor.withValues(alpha: 0.4),
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
                                : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProvider.name.isNotEmpty ? userProvider.name : 'Nguyễn Văn A',
                                  style: TextStyle(color: themeProvider.foregroundColor, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProvider.email.isNotEmpty ? userProvider.email : 'van.a@example.com',
                                  style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 14),
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
                        onTap: () {
                 
                        },
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.smart_toy_rounded,
                        iconColor: const Color(0xFFEC5B13),
                        iconBgColor: const Color(0xFFEC5B13).withValues(alpha: 0.2),
                        title: 'Chat với trợ lý ảo',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AiChatScreen()),
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
                          final url = Uri.parse('https://chitieuplus-app.web.app');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không thể mở liên kết')),
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
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Ngôn ngữ',
                        trailing: Text('Tiếng Việt', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 14)),
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSwitchItem(
                        themeProvider: themeProvider,
                        icon: Icons.dark_mode_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Chế độ sáng/tối',
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleDarkMode(val),
                      ),
                      _buildDivider(themeProvider),
                      _buildSwitchItem(
                        themeProvider: themeProvider,
                        icon: Icons.visibility_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Chế độ bảo vệ mắt',
                        value: themeProvider.isEyeProtection,
                        onChanged: (val) => themeProvider.toggleEyeProtection(val),
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
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
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
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Liên hệ',
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.chat_bubble_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Phản hồi',
                        onTap: () {},
                      ),
                      _buildDivider(themeProvider),
                      _buildSettingsItem(
                        themeProvider: themeProvider,
                        icon: Icons.policy_rounded,
                        iconColor: themeProvider.foregroundColor,
                        iconBgColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
                        title: 'Chính sách & Điều khoản',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndPrivacyScreen(),
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
                              MaterialPageRoute(builder: (context) => const AuthWrapper()),
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
            Text('Xóa tất cả dữ liệu?', style: TextStyle(color: themeProvider.foregroundColor)),
          ],
        ),
        content: Text(
          'Hành động này sẽ xóa vĩnh viễn toàn bộ giao dịch của bạn trên cả Firestore và Realtime Database. Bạn chắc chắn chứ?',
          style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
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
        style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, required ThemeProvider themeProvider}) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(ThemeProvider themeProvider) {
    return Divider(height: 1, thickness: 1, color: themeProvider.borderColor, indent: 64);
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
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            ?trailing,
            if (trailing != null && showArrow) const SizedBox(width: 8),
            if (showArrow) Icon(Icons.chevron_right_rounded, color: themeProvider.foregroundColor.withValues(alpha: 0.4), size: 24),
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
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFEC5B13),
            activeTrackColor: const Color(0xFFEC5B13).withValues(alpha: 0.5),
            inactiveThumbColor: themeProvider.foregroundColor.withValues(alpha: 0.4),
            inactiveTrackColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}


