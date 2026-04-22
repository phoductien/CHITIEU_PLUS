import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final TextEditingController _accountController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _addAccount() {
    final name = _accountController.text.trim();
    if (name.isNotEmpty) {
      context.read<UserProvider>().addBankAccount(name);
      _accountController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm tài khoản "$name"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeAccount(String name) {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = context.read<ThemeProvider>();
        return AlertDialog(
          backgroundColor: themeProvider.secondaryColor,
          title: Text(
            'Xóa tài khoản',
            style: TextStyle(color: themeProvider.foregroundColor),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản "$name"?',
            style: TextStyle(
              color: themeProvider.foregroundColor.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<UserProvider>().removeBankAccount(name);
                Navigator.pop(context);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showMyQr(String accountName) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: themeProvider.foregroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Mã QR của tôi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                accountName,
                style: TextStyle(
                  color: themeProvider.foregroundColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: accountName,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Người khác có thể quét mã này để ghi nhận giao dịch nhanh chóng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC5B13),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final accounts = userProvider.bankAccounts;

    if (userProvider.isGuest) {
      return Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Tài khoản ngân hàng',
            style: TextStyle(
              color: themeProvider.foregroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: themeProvider.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: themeProvider.foregroundColor),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeProvider.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: Color(0xFFEC5B13),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tính năng bị hạn chế',
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn cần đăng nhập để sử dụng các tính năng liên quan đến ngân hàng và quản lý tài khoản.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.foregroundColor.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // The MainDrawer logout logic handles clearing guest and going to AuthWrapper
                      // but here we just pop back so they can sign out or sign in from the profile.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC5B13),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tài khoản ngân hàng',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.foregroundColor),
      ),
      body: Column(
        children: [
          // Input section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    child: TextField(
                      controller: _accountController,
                      style: TextStyle(color: themeProvider.foregroundColor),
                      decoration: InputDecoration(
                        hintText: 'Nhập tên ngân hàng/tài khoản',
                        hintStyle: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addAccount(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addAccount,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC5B13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          size: 64,
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có tài khoản nào',
                          style: TextStyle(
                            color: themeProvider.foregroundColor.withValues(
                              alpha: 0.3,
                            ),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.secondaryColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: themeProvider.foregroundColor.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                account,
                                style: TextStyle(
                                  color: themeProvider.foregroundColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showMyQr(account),
                              icon: const Icon(
                                Icons.qr_code_rounded,
                                color: Color(0xFF3B82F6),
                                size: 22,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeAccount(account),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
