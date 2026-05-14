import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'sepay_qr_generator_screen.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  double _currentCash = 0;
  double _currentBank = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _currentCash = userProvider.cashBalance;
    _currentBank = userProvider.bankBalance;

    _cashController.text = _currencyFormat.format(_currentCash).replaceAll(',', '.');
    _bankController.text = _currencyFormat.format(_currentBank).replaceAll(',', '.');

    _cashController.addListener(_updateCalculations);
    _bankController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    final cashText = _cashController.text.replaceAll('.', '').replaceAll(',', '');
    final bankText = _bankController.text.replaceAll('.', '').replaceAll(',', '');

    setState(() {
      _currentCash = double.tryParse(cashText) ?? 0;
      _currentBank = double.tryParse(bankText) ?? 0;
    });
  }

  Future<void> _saveBalances() async {
    setState(() => _isSaving = true);
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalances(cash: _currentCash, bank: _currentBank);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã cập nhật số dư thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu số dư: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final total = _currentCash + _currentBank;
    double debt = 0;
    if (_currentCash < 0) debt += _currentCash.abs();
    if (_currentBank < 0) debt += _currentBank.abs();

    return Container(
      decoration: themeProvider.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                // Custom premium Header
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: themeProvider.secondaryColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: themeProvider.borderColor),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: themeProvider.foregroundColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Quản Lý Số Dư',
                          style: TextStyle(
                            color: themeProvider.foregroundColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        // Total Balance Dynamic Card
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          child: _buildSummaryCard(
                            title: 'TỔNG SỐ DƯ HIỆN TẠI',
                            amount: total,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFFEC5B13),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Total Debt Card (highlighted if negative balance exist)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: _buildSummaryCard(
                            title: 'TỔNG NỢ',
                            amount: debt,
                            gradient: debt > 0
                                ? const LinearGradient(
                                    colors: [Color(0xFF7F1D1D), Color(0xFF450A0A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      themeProvider.secondaryColor,
                                      themeProvider.secondaryColor.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            icon: Icons.credit_card_off_rounded,
                            iconColor: debt > 0 ? Colors.redAccent : Colors.grey,
                            isDebt: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Premium Payment QR Tool Promo Card
                        FadeInUp(
                          duration: const Duration(milliseconds: 650),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              color: themeProvider.secondaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: themeProvider.borderColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    top: -20,
                                    child: Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 120,
                                      color: const Color(0xFFEC5B13).withOpacity(0.08),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEC5B13).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2_rounded,
                                                color: Color(0xFFEC5B13),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tạo QR Chuyển Khoản',
                                                    style: TextStyle(
                                                      color: themeProvider.foregroundColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Tạo mã QR nhận tiền VietQR nhanh chóng',
                                                    style: TextStyle(
                                                      color: themeProvider.foregroundColor.withOpacity(0.5),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const SepayQrGeneratorScreen(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEC5B13),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            minimumSize: const Size(double.infinity, 45),
                                            elevation: 0,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Bắt đầu tạo ngay',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 16),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        FadeInUp(
                          duration: const Duration(milliseconds: 700),
                          child: Text(
                            'Điều Chỉnh Nguồn Tiền',
                            style: TextStyle(
                              color: themeProvider.foregroundColor.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cash Input
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: _buildInputCard(
                            controller: _cashController,
                            title: 'Số dư Ví Tiền Mặt',
                            subtitle: 'Nhập số dư tiền mặt thực tế',
                            icon: Icons.payments_rounded,
                            accentColor: Colors.greenAccent,
                            themeProvider: themeProvider,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Bank Account Input
                        FadeInUp(
                          duration: const Duration(milliseconds: 900),
                          child: _buildInputCard(
                            controller: _bankController,
                            title: 'Số dư Ví Ngân Hàng',
                            subtitle: userProvider.bankAccounts.isNotEmpty
                                ? 'Tài khoản: ${userProvider.bankAccounts.join(", ")}'
                                : 'Nhập tổng số dư các tài khoản ngân hàng',
                            icon: Icons.account_balance_rounded,
                            accentColor: Colors.blueAccent,
                            themeProvider: themeProvider,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC5B13), Color(0xFFC2410C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC5B13).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveBalances,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.save_rounded, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text(
                                          'Lưu Thay Đổi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Gradient gradient,
    required IconData icon,
    required Color iconColor,
    bool isDebt = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyFormat.format(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'đ',
                style: TextStyle(
                  color: iconColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isDebt && amount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bạn đang chi tiêu vượt quá số dư thực tế!',
                    style: TextStyle(
                      color: Colors.redAccent.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: themeProvider.foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) return;
                String cleanText = value.replaceAll('.', '').replaceAll(',', '');
                double? val = double.tryParse(cleanText);
                if (val != null) {
                  final formatted = _currencyFormat.format(val).replaceAll(',', '.');
                  if (value != formatted) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
