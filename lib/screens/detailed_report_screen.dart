import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

enum ReportPeriod { thisMonth, lastMonth, custom }

class DetailedReportScreen extends StatefulWidget {
  const DetailedReportScreen({super.key});

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().syncDataWithFirestore();
    });
  }

  // Colors from the mockup
  final Color _bgColor = const Color(0xFF141824);
  final Color _cardColor = const Color(0xFF1F2636);
  final Color _incomeColor = const Color(0xFF00F0FF);
  final Color _expenseColor = const Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final allTransactions = transactionProvider.transactions;

    // Current period
    final currentTx = _filterTransactions(
      allTransactions,
      _selectedPeriod,
      false,
    );
    // Previous period
    final previousTx = _filterTransactions(
      allTransactions,
      _selectedPeriod,
      true,
    );

    double currentIncome = _calculateTotal(currentTx, TransactionType.income);
    double currentExpense = _calculateTotal(currentTx, TransactionType.expense);

    double prevIncome = _calculateTotal(previousTx, TransactionType.income);
    double prevExpense = _calculateTotal(previousTx, TransactionType.expense);

    // Calculate percentages
    double incomePct = prevIncome == 0
        ? 0
        : ((currentIncome - prevIncome) / prevIncome) * 100;
    double expensePct = prevExpense == 0
        ? 0
        : ((currentExpense - prevExpense) / prevExpense) * 100;

    Map<String, double> categorySpending = {};
    for (var tx in currentTx) {
      if (tx.type == TransactionType.expense) {
        categorySpending[tx.category] =
            (categorySpending[tx.category] ?? 0) + tx.amount;
      }
    }

    // New stats
    int txCount = currentTx.length;
    
    // Day count for average
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    if (_selectedPeriod == ReportPeriod.thisMonth) {
      start = DateTime(now.year, now.month, 1);
      end = now;
    } else if (_selectedPeriod == ReportPeriod.lastMonth) {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0);
    } else if (_customDateRange != null) {
      start = _customDateRange!.start;
      end = _customDateRange!.end;
    } else {
      start = DateTime(now.year, now.month, 1);
      end = now;
    }
    int days = end.difference(start).inDays + 1;
    if (days <= 0) days = 1;
    double avgDailySpend = currentExpense / days;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Báo cáo chi tiết',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final service = TransactionService();
                  await service.exportAllToSqliteBytes(webFormat: 'csv');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xuất file thành công')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              icon: const Icon(
                Icons.file_upload_outlined,
                size: 16,
                color: Color(0xFFFFB74D),
              ),
              label: const Text(
                'Xuất Excel',
                style: TextStyle(color: Color(0xFFFFB74D), fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A201C),
                side: const BorderSide(color: Color(0xFFFFB74D), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildSummaryCards(
              currentIncome,
              currentExpense,
              incomePct,
              expensePct,
              txCount,
              avgDailySpend,
            ),
            const SizedBox(height: 24),
            _buildAiAdvice(categorySpending, currentExpense),
            const SizedBox(height: 24),
            _buildDonutChart(categorySpending, currentExpense),
            const SizedBox(height: 24),
            _buildBarChart(currentTx),
            const SizedBox(height: 24),
            _buildBankStatsSection(currentTx),
            const SizedBox(height: 24),
            _buildBudgetLimits(categorySpending),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
    ReportPeriod period,
    bool isPrevious,
  ) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (period == ReportPeriod.thisMonth) {
      if (!isPrevious) {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
      }
    } else if (period == ReportPeriod.lastMonth) {
      if (!isPrevious) {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else {
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
      }
    } else {
      if (_customDateRange != null) {
        start = _customDateRange!.start;
        end = _customDateRange!.end.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
        if (isPrevious) {
          final duration = end.difference(start);
          end = start.subtract(const Duration(seconds: 1));
          start = start.subtract(duration);
        }
      } else {
        start = DateTime(2000);
        end = now;
      }
    }

    return transactions
        .where(
          (tx) =>
              tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              tx.date.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  double _calculateTotal(List<TransactionModel> txs, TransactionType type) {
    return txs
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodButton('Tháng này', ReportPeriod.thisMonth),
        const SizedBox(width: 8),
        _buildPeriodButton('Tháng trước', ReportPeriod.lastMonth),
        const SizedBox(width: 8),
        _buildPeriodButton('Tùy chọn', ReportPeriod.custom),
      ],
    );
  }

  Widget _buildPeriodButton(String label, ReportPeriod period) {
    bool isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (period == ReportPeriod.custom) {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFF57C00),
                      onPrimary: Colors.white,
                      surface: Color(0xFF1F2636),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _customDateRange = picked;
                _selectedPeriod = period;
              });
            }
          } else {
            setState(() {
              _selectedPeriod = period;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF57C00) : _cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    double income,
    double expense,
    double incomePct,
    double expensePct,
    int txCount,
    double avgDailySpend,
  ) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCardItem(
                'TỔNG THU NHẬP',
                '+',
                income,
                incomePct,
                _incomeColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCardItem(
                'TỔNG CHI TIÊU',
                '-',
                expense,
                expensePct,
                _expenseColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Số lượng GD',
                txCount.toString(),
                Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'TB chi tiêu/ngày',
                '${currencyFormat.format(avgDailySpend / 1000)}k',
                Icons.analytics_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardItem(
    String title,
    String sign,
    double amount,
    double pct,
    Color mainColor,
  ) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    String formattedAmount = '$sign${currencyFormat.format(amount)}k';
    if (amount == 0) formattedAmount = '0k';

    String pctText = '~ ${pct.abs().toStringAsFixed(0)}% so với tháng trước';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: mainColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formattedAmount,
            style: TextStyle(
              color: mainColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                pct >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pctText,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdvice(
    Map<String, double> categorySpending,
    double totalExpense,
  ) {
    String topCategory = 'Ăn uống';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF00F0FF), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF00F0FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Lời khuyên từ AI',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Bạn đã chi tiêu cho '),
                TextSpan(
                  text: topCategory,
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text:
                      ' chiếm tỷ trọng lớn nhất. Hãy thử sử dụng gói coupon mới để tiết kiệm khoảng ',
                ),
                const TextSpan(
                  text: '1,200k',
                  style: TextStyle(
                    color: Color(0xFF00F0FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' trong tuần tới.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> spending, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân bổ chi tiêu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white54),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0 || spending.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          sections: _generatePieSections(spending, total),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TỔNG',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '100%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _generateLegend(spending, total),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(
    Map<String, double> spending,
    double total,
  ) {
    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) {
      return PieChartSectionData(
        color: _getCategoryChartColor(e.key),
        value: e.value,
        title: '',
        radius: 12,
        showTitle: false,
      );
    }).toList();
  }

  List<Widget> _generateLegend(Map<String, double> spending, double total) {
    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) {
      double pct = (e.value / total) * 100;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryChartColor(e.key),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getCategoryChartColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return const Color(0xFFFFB74D);
      case 'Mua sắm':
        return const Color(0xFF00F0FF);
      case 'Di chuyển':
        return const Color(0xFF7986CB);
      case 'Giáo dục':
        return const Color(0xFF81C784);
      default:
        return Colors.white24;
    }
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xu hướng thu chi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Theo thứ',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChartLegend('Thu nhập', _incomeColor),
              const SizedBox(width: 16),
              _buildChartLegend('Chi tiêu', _expenseColor),
            ],
          ),
          const SizedBox(height: 24),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxBarValue(transactions) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: const Color(0xFF2D3748),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)}k',
                          TextStyle(
                            color: rod.color,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getBarXLabel(value.toInt()),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateBarGroups(transactions),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  double _getMaxBarValue(List<TransactionModel> txs) {
    final groups = _groupTransactionsForBarChart(txs);
    double maxV = 0;
    for (var dayMap in groups.values) {
      for (var v in dayMap.values) {
        if (v > maxV) maxV = v;
      }
    }
    return maxV == 0 ? 100 : maxV;
  }

  Map<int, Map<TransactionType, double>> _groupTransactionsForBarChart(
    List<TransactionModel> txs,
  ) {
    Map<int, Map<TransactionType, double>> result = {};
    for (var tx in txs) {
      int key = tx.date.weekday; // 1 to 7
      result.putIfAbsent(
        key,
        () => {TransactionType.income: 0, TransactionType.expense: 0},
      );
      result[key]![tx.type] = (result[key]![tx.type] ?? 0) + (tx.amount / 1000);
    }
    return result;
  }

  List<BarChartGroupData> _generateBarGroups(List<TransactionModel> txs) {
    final groups = _groupTransactionsForBarChart(txs);
    List<BarChartGroupData> data = [];
    for (int i = 1; i <= 7; i++) {
      final dayData =
          groups[i] ?? {TransactionType.income: 0, TransactionType.expense: 0};
      data.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dayData[TransactionType.income] ?? 0,
              color: _incomeColor,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: dayData[TransactionType.expense] ?? 0,
              color: _expenseColor,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    return data;
  }

  Widget _buildBankStatsSection(List<TransactionModel> transactions) {
    Map<String, Map<TransactionType, double>> bankStats = {};
    for (var tx in transactions) {
      String bankName = tx.bankBrandName;
      String accNum = tx.accountNumber;

      // Fallback cho dữ liệu cũ: parse từ note
      if (bankName == 'Khác' && tx.note != null && tx.note!.startsWith('Từ: ')) {
        try {
          final parts = tx.note!.substring(4).split(' (');
          bankName = parts[0];
          if (parts.length > 1) {
            accNum = parts[1].replaceAll(')', '');
          }
        } catch (_) {}
      }

      if (bankName == 'Khác' && accNum.isEmpty) continue; // Bỏ qua nếu không phải GD ngân hàng

      String key = accNum.isEmpty ? bankName : '$bankName - $accNum';
      bankStats.putIfAbsent(
        key,
        () => {TransactionType.income: 0, TransactionType.expense: 0},
      );
      bankStats[key]![tx.type] = (bankStats[key]![tx.type] ?? 0) + tx.amount;
    }

    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê theo tài khoản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (bankStats.isEmpty)
            const Text(
              'Chưa có dữ liệu ngân hàng',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...bankStats.entries.map((entry) {
              final income = entry.value[TransactionType.income] ?? 0;
              final expense = entry.value[TransactionType.expense] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBankStatBar(
                          'Thu',
                          income,
                          _incomeColor,
                          currencyFormat,
                        ),
                        const SizedBox(width: 12),
                        _buildBankStatBar(
                          'Chi',
                          expense,
                          _expenseColor,
                          currencyFormat,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBankStatBar(
    String label,
    double amount,
    Color color,
    NumberFormat format,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
            Text(
              '${format.format(amount)}đ',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getBarXLabel(int index) {
    switch (index) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  Widget _buildBudgetLimits(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngân sách mục tiêu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (categorySpending.containsKey('Ăn uống'))
          _buildBudgetRow(
            'Ăn uống',
            categorySpending['Ăn uống'] ?? 0,
            10000000,
            const Color(0xFFFFB74D),
            Icons.restaurant,
          ),
        if (categorySpending.containsKey('Di chuyển')) ...[
          const SizedBox(height: 16),
          _buildBudgetRow(
            'Di chuyển',
            categorySpending['Di chuyển'] ?? 0,
            5000000,
            const Color(0xFF00F0FF),
            Icons.directions_car,
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetRow(
    String title,
    double current,
    double limit,
    Color color,
    IconData icon,
  ) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    double pct = limit > 0 ? current / limit : 0;
    if (pct > 1) pct = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                '${currencyFormat.format(current / 1000)}k / ${currencyFormat.format(limit / 1000)}k',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withAlpha(51), // 0.2
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
