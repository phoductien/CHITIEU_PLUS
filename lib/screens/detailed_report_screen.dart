import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';

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
  final Color _cardColor = const Color(0xFF1C2230);
  final Color _incomeColor = const Color(0xFF00E676); // Premium Green
  final Color _expenseColor = const Color(0xFFFF5252); // Red premium
  final Color _accentColor = const Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = _filterTransactions(
          provider.transactions,
          _selectedPeriod,
          false,
        );
        final hasData = transactions.any((tx) => tx.amount > 0);

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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                if (!hasData)
                  _buildEmptyState()
                else ...[
                  _buildSummaryCards(transactions),
                  const SizedBox(height: 24),
                  _buildCategoryAllocation(transactions),
                  const SizedBox(height: 24),
                  _buildTrendLineChart(transactions),
                  const SizedBox(height: 24),
                  _buildBankStatsSection(transactions),
                  const SizedBox(height: 24),
                  _buildBudgetLimits(_getCategorySpending(transactions)),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        );
      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dữ liệu giao dịch',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const Text(
            'Hãy thêm giao dịch để xem báo cáo chi tiết',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
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
                    colorScheme: ColorScheme.dark(
                      primary: _accentColor,
                      onPrimary: Colors.white,
                      surface: _cardColor,
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
            color: isSelected ? _accentColor : _cardColor,
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

  Widget _buildSummaryCards(List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCardItem('THU NHẬP', '+', income, _incomeColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCardItem('CHI TIÊU', '-', expense, _expenseColor),
        ),
      ],
    );
  }

  Widget _buildSummaryCardItem(
    String title,
    String sign,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$sign${NumberFormat('#,###', 'vi_VN').format(amount)}đ',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAllocation(List<TransactionModel> transactions) {
    final categorySpending = _getCategorySpending(transactions);
    if (categorySpending.isEmpty) return const SizedBox.shrink();

    final totalExpense = categorySpending.values.fold(
      0.0,
      (sum, item) => sum + item,
    );
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
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
              const Text(
                'PHÂN BỔ CHI TIÊU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Tổng: ${NumberFormat('#,###', 'vi_VN').format(totalExpense)}đ',
                style: TextStyle(
                  color: _expenseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedCategories.take(5).map((entry) {
            final double percentage = totalExpense > 0
                ? (entry.value / totalExpense)
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(entry.key),
                      color: _accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          minHeight: 4,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(_accentColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###', 'vi_VN').format(entry.value)}đ',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendLineChart(List<TransactionModel> transactions) {
    final dailyData = _groupTransactionsByDate(transactions);
    if (dailyData.isEmpty) return const SizedBox.shrink();

    final List<FlSpot> spots = [];
    final List<DateTime> dates = dailyData.keys.toList()..sort();

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final data = dailyData[date]!;
      final netChange = (data['income'] ?? 0) - (data['expense'] ?? 0);
      spots.add(FlSpot(i.toDouble(), netChange / 1000));
    }

    final bool isTrendingUp =
        spots.isNotEmpty && (spots.last.y >= spots.first.y);
    final chartColor = isTrendingUp ? _incomeColor : _expenseColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
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
              const Text(
                'XU HƯỚNG THU CHI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  _buildChartLegend('TĂNG', _incomeColor),
                  const SizedBox(width: 12),
                  _buildChartLegend('GIẢM', _expenseColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (dates.length / 5).clamp(1, 10).toDouble(),
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= dates.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd/MM').format(dates[index]),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: _cardColor,
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = dates[spot.x.toInt()];
                        final data = dailyData[date]!;
                        final total =
                            (data['income'] ?? 0) - (data['expense'] ?? 0);
                        return LineTooltipItem(
                          '${DateFormat('dd/MM/yyyy').format(date)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${data['count']} giao dịch\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${NumberFormat('#,###', 'vi_VN').format(total)}đ',
                              style: TextStyle(
                                color: total >= 0
                                    ? _incomeColor
                                    : _expenseColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, Map<String, dynamic>> _groupTransactionsByDate(
    List<TransactionModel> txs,
  ) {
    Map<DateTime, Map<String, dynamic>> result = {};
    for (var tx in txs) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      result.putIfAbsent(
        date,
        () => {'income': 0.0, 'expense': 0.0, 'count': 0},
      );
      if (tx.type == TransactionType.income) {
        result[date]!['income'] += tx.amount;
      } else {
        result[date]!['expense'] += tx.amount;
      }
      result[date]!['count'] += 1;
    }
    return result;
  }

  Map<String, double> _getCategorySpending(
    List<TransactionModel> transactions,
  ) {
    Map<String, double> spending = {};
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        spending[tx.category] = (spending[tx.category] ?? 0) + tx.amount;
      }
    }
    return spending;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant;
      case 'Di chuyển':
        return Icons.directions_car;
      case 'Mua sắm':
        return Icons.shopping_bag;
      case 'Giải trí':
        return Icons.movie;
      case 'Sức khỏe':
        return Icons.medical_services;
      case 'Giáo dục':
        return Icons.school;
      default:
        return Icons.category;
    }
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

  Widget _buildBankStatsSection(List<TransactionModel> transactions) {
    Map<String, Map<TransactionType, double>> bankStats = {};
    for (var tx in transactions) {
      String key = tx.bankBrandName.isNotEmpty ? tx.bankBrandName : 'Khác';
      bankStats.putIfAbsent(
        key,
        () => {TransactionType.income: 0, TransactionType.expense: 0},
      );
      bankStats[key]![tx.type] = (bankStats[key]![tx.type] ?? 0) + tx.amount;
    }

    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THỐNG KÊ TÀI KHOẢN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
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
            }),
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
            Text(label, style: TextStyle(color: color, fontSize: 10)),
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
