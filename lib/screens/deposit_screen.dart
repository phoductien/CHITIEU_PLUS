import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/screens/bank_accounts_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  late TextEditingController _amountController;
  int _selectedAmount = 0;
  String? _selectedMethod; // null means direct deposit

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: "500.000");
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    String text = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '');
    if (text.isNotEmpty) {
      int val = int.tryParse(text) ?? 0;
      if (val != _selectedAmount) {
        setState(() {
          _selectedAmount = val;
        });
      }
    }
  }

  void _handleQuickSelect(int amt) {
    setState(() {
      _selectedAmount = amt;
      _amountController.text = NumberFormat(
        '#,###',
        'vi_VN',
      ).format(amt).replaceAll(',', '.');
    });
  }

  String get _walletName {
    final userProvider = context.read<UserProvider>();
    final languageProvider = context.read<LanguageProvider>();
    return userProvider.bankAccounts.isNotEmpty
        ? userProvider.bankAccounts.first
        : languageProvider.translate('wallet_demo');
  }

  Future<void> _handleDeposit() async {
    final transactionProvider = context.read<TransactionProvider>();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    if (_selectedAmount <= 0) return;

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFEC5B13)),
      ),
    );

    try {
      final tx = TransactionModel(
        id: '', // Để service tự generate
        userId: user.uid,
        title: 'Nạp tiền vào $_walletName',
        amount: _selectedAmount.toDouble(),
        category: 'Nạp tiền',
        date: DateTime.now(),
        type: TransactionType.income,
        wallet: 'main',
        note: _selectedMethod == null
            ? 'Nạp tiền trực tiếp'
            : 'Nạp qua phương thức $_selectedMethod',
      );

      await transactionProvider.addTransaction(tx);

      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Nạp tiền thành công',
          body:
              'Bạn vừa nạp ${NumberFormat('#,###').format(_selectedAmount)}đ vào $_walletName.',
          type: NotificationType.transaction,
        );
        Navigator.pop(context); // Tắt loading
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => FadeIn(
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'NẠP TIỀN THÀNH CÔNG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Số tiền ${NumberFormat('#,###').format(_selectedAmount)}đ đã được chuyển vào $_walletName.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC5B13),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tắt dialog
                    Navigator.pop(context); // Quay lại Home
                  },
                  child: const Text(
                    'TUYỆT VỜI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, themeProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildAmountInput(themeProvider),
                          const SizedBox(height: 40),
                          _buildQuickSelection(themeProvider),
                          const SizedBox(height: 40),
                          _buildPaymentMethods(themeProvider),
                          const SizedBox(height: 30),
                          _buildActionButton(),
                          const SizedBox(height: 120), // Height for nav bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavBar(themeProvider, languageProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: themeProvider.foregroundColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Nạp tiền',
            style: TextStyle(
              color: const Color(0xFFFFD180),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(ThemeProvider themeProvider) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Text(
            'NHẬP SỐ TIỀN CẦN NẠP',
            style: TextStyle(
              color: themeProvider.foregroundColor.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // Tự động định dạng dấu chấm phân cách hàng nghìn
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  int? val = int.tryParse(newValue.text.replaceAll('.', ''));
                  if (val == null) return oldValue;
                  final formatted = NumberFormat(
                    '#,###',
                    'vi_VN',
                  ).format(val).replaceAll(',', '.');
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }),
              ],
              style: const TextStyle(
                color: Color(0xFFFFD180),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: Colors.white12),
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFEC5B13).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelection(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _quickAmounts.map((amt) {
          final isSelected = _selectedAmount == amt;
          final label = amt >= 1000
              ? '${(amt / 1000).toInt()}k'
              : amt.toString();

          return GestureDetector(
            onTap: () => _handleQuickSelect(amt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEC5B13).withValues(alpha: 0.8)
                    : themeProvider.secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEC5B13)
                      : themeProvider.borderColor,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : themeProvider.foregroundColor.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethods(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.cyan,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phương thức nạp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMethodItem(
            id: 'momo',
            icon: Icons.smartphone_rounded,
            title: 'Ví điện tử',
            subtitle: 'Momo, ZaloPay',
            iconColor: Colors.pinkAccent,
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          _buildMethodItem(
            id: 'bank',
            icon: Icons.account_balance_rounded,
            title: 'Thẻ ngân hàng',
            subtitle: 'ATM / Internet Banking',
            iconColor: Colors.blueAccent,
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          _buildMethodItem(
            id: 'visa',
            icon: Icons.credit_card_rounded,
            title: 'Thẻ quốc tế',
            subtitle: 'Visa, Mastercard, JCB',
            iconColor: Colors.tealAccent,
            themeProvider: themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: () {
        if (id == 'bank') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BankAccountsScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tính năng nạp qua $title đang được phát triển'),
              backgroundColor: iconColor.withValues(alpha: 0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.secondaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeProvider.borderColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: themeProvider.foregroundColor.withValues(alpha: 0.2),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isEnabled = _selectedAmount >= 50000;
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 800),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[900]!],
                  ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFEC5B13).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: isEnabled ? _handleDeposit : null,
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nạp tiền ngay',
                  style: TextStyle(
                    color: isEnabled ? Colors.black : Colors.white24,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.bolt_rounded,
                  color: isEnabled ? Colors.black : Colors.white24,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
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
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: themeProvider.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.grid_view_rounded, 'TRANG CHỦ', false),
                _buildNavItem(Icons.receipt_long_rounded, 'GIAO DỊCH', true),
                const SizedBox(width: 60),
                _buildNavItem(Icons.analytics_rounded, 'BÁO CÁO', false),
                _buildNavItem(Icons.settings_rounded, 'CÀI ĐẶT', false),
              ],
            ),
          ),
          Positioned(
            top: -15,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeProvider.backgroundColor,
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFFEC5B13) : Colors.white24,
          size: 24,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFEC5B13) : Colors.white24,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
