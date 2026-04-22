import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/screens/payment_details_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';
import 'package:intl/intl.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  late TextEditingController _amountController;
  int _selectedAmount = 0;

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: "500.000");
    _amountController.addListener(_onAmountChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSessionProvider>().setLastRoute('deposit');
    });
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final userProvider = context.watch<UserProvider>();

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
                          _buildActionButton(userProvider),
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

  Widget _buildActionButton(UserProvider userProvider) {
    final bool hasBank = userProvider.bankAccounts.isNotEmpty;
    final bool canDeposit = userProvider.isGuest || hasBank;
    final bool isEnabled = _selectedAmount >= 50000 && canDeposit;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 800),
      child: Column(
        children: [
          AnimatedOpacity(
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
                onTap: isEnabled
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentDetailsScreen(
                            amount: _selectedAmount.toDouble(),
                          ),
                        ),
                      )
                    : null,
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
          if (!canDeposit)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Vui lòng liên kết ngân hàng để nạp tiền',
                    style: TextStyle(
                      color: Colors.orangeAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
