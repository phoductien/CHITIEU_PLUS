import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final accounts = userProvider.bankAccounts;

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
