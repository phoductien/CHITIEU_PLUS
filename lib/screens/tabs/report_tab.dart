import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';

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
    Map<String, double> catTotals = {
      'Ăn uống': 0,
      'Mua sắm': 0,
      'Di chuyển': 0,
      'Khác': 0,
    };
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
    List<double> barValues = maxVal > 0
        ? last7Days.map((v) => (v / maxVal) * 20).toList()
        : List.filled(7, 0.0);
    double totalExpense = catTotals.values.reduce((a, b) => a + b);
    List<double> pieValues = totalExpense > 0
        ? [
            (catTotals['Ăn uống']! / totalExpense) * 100,
            (catTotals['Mua sắm']! / totalExpense) * 100,
            (catTotals['Di chuyển']! / totalExpense) * 100,
            (catTotals['Khác']! / totalExpense) * 100,
          ]
        : List.filled(4, 0.0);

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
                    'Báo cáo tài chính',
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeProvider.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
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
                    const SizedBox(height: 10),
                    Text(
                      'CƠ CẤU CHI TIÊU',
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: themeProvider.borderColor),
                      ),
                      child: _buildDonutChart(themeProvider, pieValues),
                    ),
                    const SizedBox(height: 35),
                    Text(
                      'XU HƯỚNG CHI TIÊU',
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
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      decoration: BoxDecoration(
                        color: themeProvider.secondaryColor.withValues(
                          alpha: 0.4,
                        ),
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
                      ...(pieValues[0] == 0 &&
                              pieValues[1] == 0 &&
                              pieValues[2] == 0 &&
                              pieValues[3] == 0
                          ? [
                              PieChartSectionData(
                                color: themeProvider.foregroundColor.withValues(
                                  alpha: 0.1,
                                ),
                                value: 100,
                                radius: 16,
                                showTitle: false,
                              ),
                            ]
                          : [
                              PieChartSectionData(
                                color: const Color(0xFFFF6D00),
                                value: pieValues[0],
                                radius: 18,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                color: Colors.blue,
                                value: pieValues[1],
                                radius: 16,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                color: Colors.green,
                                value: pieValues[2],
                                radius: 14,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                color: Colors.yellow,
                                value: pieValues[3],
                                radius: 12,
                                showTitle: false,
                              ),
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
                      Text(
                        'Tổng',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        pieValues[0] == 0 && pieValues[1] == 0 ? '0%' : '100%',
                        style: TextStyle(
                          color: themeProvider.foregroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
              _buildAllocationItem(
                'Ăn uống',
                pieValues[0] == 0
                    ? '0%'
                    : '${pieValues[0].toStringAsFixed(0)}%',
                const Color(0xFFFF6D00),
                themeProvider,
              ),
              _buildAllocationItem(
                'Mua sắm',
                pieValues[1] == 0
                    ? '0%'
                    : '${pieValues[1].toStringAsFixed(0)}%',
                Colors.blue,
                themeProvider,
              ),
              _buildAllocationItem(
                'Di chuyển',
                pieValues[2] == 0
                    ? '0%'
                    : '${pieValues[2].toStringAsFixed(0)}%',
                Colors.green,
                themeProvider,
              ),
              _buildAllocationItem(
                'Khác',
                pieValues[3] == 0
                    ? '0%'
                    : '${pieValues[3].toStringAsFixed(0)}%',
                Colors.yellow,
                themeProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationItem(
    String title,
    String percent,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: themeProvider.foregroundColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            percent,
            style: TextStyle(
              color: themeProvider.foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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
                  child: Text(
                    days[value.toInt() % days.length],
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
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
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: themeProvider.backgroundColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

// --- TAB 4: CÀI ĐẶT ---
