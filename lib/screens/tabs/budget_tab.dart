import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/screens/budget_settings_screen.dart';

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final budgetLimit = userProvider.totalBudget;
    final transactionProvider = context.watch<TransactionProvider>();
    final allTxs = transactionProvider.transactions;

    // Calculate current month's expense
    final now = DateTime.now();
    double currentMonthExpense = 0;

    final Map<String, double> catSpent = {
      'Ăn uống': 0,
      'Mua sắm': 0,
      'Di chuyển': 0,
      'Nhà cửa': 0,
      'Giải trí': 0,
      'Hóa đơn': 0,
      'Học phí': 0,
      'Bảo hiểm': 0,
      'Tiền điện': 0,
      'Tiền nước': 0,
      'Khác': 0,
    };

    for (var tx in allTxs) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        currentMonthExpense += tx.amount;
        if (catSpent.containsKey(tx.category)) {
          catSpent[tx.category] = catSpent[tx.category]! + tx.amount;
        } else {
          catSpent['Khác'] = catSpent['Khác']! + tx.amount;
        }
      }
    }

    final double overBudget = currentMonthExpense > budgetLimit
        ? currentMonthExpense - budgetLimit
        : 0;
    final bool isOver = overBudget > 0;
    final double percent = budgetLimit > 0
        ? (currentMonthExpense / budgetLimit).clamp(0.0, 1.0)
        : 0.0;

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
                  Text(
                    'Ngân sách chi tiêu',
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetSettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Điều chỉnh',
                        style: TextStyle(
                          color: Color(0xFFF05D15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        color: themeProvider.secondaryColor.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã tiêu',
                                style: TextStyle(
                                  color: themeProvider.foregroundColor
                                      .withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              if (isOver)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Vượt ngân sách',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'đ ${NumberFormat('#,###').format(currentMonthExpense)}',
                            style: TextStyle(
                              color: isOver
                                  ? Colors.redAccent
                                  : themeProvider.foregroundColor,
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
                              backgroundColor: themeProvider.foregroundColor
                                  .withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? Colors.redAccent
                                    : const Color(0xFFF05D15),
                              ),
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ngân sách: đ ${NumberFormat('#,###').format(budgetLimit)}',
                                style: TextStyle(
                                  color: themeProvider.foregroundColor
                                      .withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                isOver
                                    ? 'Vượt quá đ ${NumberFormat('#,###').format(overBudget)}'
                                    : 'Còn lại đ ${NumberFormat('#,###').format(budgetLimit - currentMonthExpense)}',
                                style: TextStyle(
                                  color: isOver
                                      ? Colors.redAccent
                                      : const Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'CHI TIẾT HẠNG MỤC',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...catSpent.keys.map((cat) {
                      if (catSpent[cat]! == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: themeProvider.foregroundColor.withValues(
                                  alpha: 0.05,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category,
                                color: themeProvider.foregroundColor.withValues(
                                  alpha: 0.5,
                                ),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      color: themeProvider.foregroundColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: (userProvider.categoryBudgets[cat] ?? budgetLimit) > 0
                                          ? (catSpent[cat]! / (userProvider.categoryBudgets[cat] ?? budgetLimit))
                                                .clamp(0.0, 1.0)
                                          : 0,
                                      backgroundColor: themeProvider
                                          .foregroundColor
                                          .withOpacity(0.1),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            catSpent[cat]! > (userProvider.categoryBudgets[cat] ?? budgetLimit)
                                                ? Colors.redAccent
                                                : Colors.blue,
                                          ),
                                      minHeight: 4,
                                    ),
                                  ),
                                  if (userProvider.categoryBudgets.containsKey(cat))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Hạn mức: đ ${NumberFormat('#,###').format(userProvider.categoryBudgets[cat])}',
                                        style: TextStyle(
                                          color: themeProvider.foregroundColor.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'đ ${NumberFormat('#,###').format(catSpent[cat])}',
                                  style: TextStyle(
                                    color: themeProvider.foregroundColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userProvider.categoryBudgets.containsKey(cat))
                                  Text(
                                    catSpent[cat]! > userProvider.categoryBudgets[cat]!
                                        ? 'Vượt ${NumberFormat('#,###').format(catSpent[cat]! - userProvider.categoryBudgets[cat]!)}'
                                        : 'Còn ${NumberFormat('#,###').format(userProvider.categoryBudgets[cat]! - catSpent[cat]!)}',
                                    style: TextStyle(
                                      color: catSpent[cat]! > userProvider.categoryBudgets[cat]!
                                          ? Colors.redAccent
                                          : const Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
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

// --- TAB 4: BÃO CÃO ---

