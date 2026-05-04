import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as u_html;

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final GlobalKey _reportKey = GlobalKey();
  bool _isSharing = false;
  String _selectedTrendPeriod = 'Tuần';

  Future<void> _captureAndShareReport() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // 1. Capture the widget
      final boundary =
          _reportKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // Web Implementation: Use XFile.fromData or simple download
        try {
          await Share.shareXFiles([
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: 'bao_cao_tai_chinh.png',
            ),
          ], text: 'Báo cáo tài chính từ CHITIEU PLUS ðŸ“Š');
        } catch (webShareError) {
          // Fallback for Web: Download the image if Share API is not supported
          final blob = u_html.Blob([pngBytes]);
          final url = u_html.Url.createObjectUrlFromBlob(blob);
          final anchor = u_html.AnchorElement(href: url)
            ..setAttribute(
              "download",
              "bao_cao_tai_chinh_${DateTime.now().millisecondsSinceEpoch}.png",
            )
            ..click();
          u_html.Url.revokeObjectUrl(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Trình duyệt không hỗ trợ chia sẻ trực tiếp. Đã tự động tải ảnh về máy.',
                ),
              ),
            );
          }
        }
      } else {
        // Mobile/Desktop Implementation (using dart:io and path_provider)
        final tempDir = await getTemporaryDirectory();
        final file = await io.File(
          '${tempDir.path}/bao_cao_tai_chinh_${DateTime.now().millisecondsSinceEpoch}.png',
        ).create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Báo cáo tài chính từ CHITIEU PLUS 📊');
      }
    } catch (e) {
      debugPrint('[ReportTab] Error sharing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chia sẻ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final transactions = transactionProvider.transactions;

    // --- DATA CALCULATION ---
    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);

    double expenseThisMonth = 0;
    double incomeThisMonth = 0;
    double expenseLastMonth = 0;

    Map<String, double> categorySpending = {};
    Map<String, double> categoryIncome = {};
    Map<String, double> categorySavings = {};

    for (var tx in transactions) {
      if (tx.date.isAfter(
        firstDayThisMonth.subtract(const Duration(seconds: 1)),
      )) {
        if (tx.type == TransactionType.income) {
          incomeThisMonth += tx.amount;
          if (tx.category.contains('Tiết kiệm') ||
              tx.category.contains('Đầu tư')) {
            categorySavings[tx.category] =
                (categorySavings[tx.category] ?? 0) + tx.amount;
          } else {
            categoryIncome[tx.category] =
                (categoryIncome[tx.category] ?? 0) + tx.amount;
          }
        } else {
          expenseThisMonth += tx.amount;
          if (tx.category.contains('Tiết kiệm') ||
              tx.category.contains('Đầu tư')) {
            categorySavings[tx.category] =
                (categorySavings[tx.category] ?? 0) + tx.amount;
          } else {
            categorySpending[tx.category] =
                (categorySpending[tx.category] ?? 0) + tx.amount;
          }
        }
      } else if (tx.date.isAfter(
            firstDayLastMonth.subtract(const Duration(seconds: 1)),
          ) &&
          tx.date.isBefore(
            lastDayLastMonth.add(const Duration(hours: 23, minutes: 59)),
          )) {
        if (tx.type == TransactionType.expense) {
          expenseLastMonth += tx.amount;
        }
      }
    }

    double percentChange = 0;
    if (expenseLastMonth > 0) {
      percentChange =
          ((expenseThisMonth - expenseLastMonth) / expenseLastMonth) * 100;
    }

    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    if (transactions.isEmpty) {
      return Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: themeProvider.foregroundColor.withOpacity(0.1),
              ),
              const SizedBox(height: 24),
              Text(
                'CHƯA CÓ DỮ LIỆU',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy thêm giao dịch để xem báo cáo chi tiết',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RepaintBoundary(
            key: _reportKey,
            child: Container(
              color: themeProvider
                  .backgroundColor, // Ensure background is captured
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(themeProvider),
                  const SizedBox(height: 24),
                  _buildMonthlySummary(
                    expenseThisMonth,
                    percentChange,
                    themeProvider,
                    currencyFormat,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PHÂN BỔ CHI TIÊU', themeProvider),
                  const SizedBox(height: 16),
                  _buildAllocationSection(
                    categorySpending,
                    expenseThisMonth,
                    themeProvider,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('XU HƯỚNG TỔNG HỢP', themeProvider),
                  const SizedBox(height: 16),
                  _buildTrendChart(transactions, themeProvider),
                  const SizedBox(height: 32),
                  _buildSectionTitle('CHI TIẾT DANH MỤC', themeProvider),
                  const SizedBox(height: 16),
                  _buildCategoryDetails(
                    categoryIncome,
                    categorySpending,
                    categorySavings,
                    transactions,
                    themeProvider,
                    currencyFormat,
                  ),
                  const SizedBox(height: 32),
                  _buildOracleInsights(
                    categorySpending,
                    incomeThisMonth,
                    expenseThisMonth,
                    themeProvider,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_graph_rounded,
              color: themeProvider.foregroundColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'CHITIEU PLUS',
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _captureAndShareReport,
              child: Icon(
                Icons.share_rounded,
                color: themeProvider.foregroundColor.withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 18,
              backgroundColor: themeProvider.secondaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person_rounded,
                color: themeProvider.foregroundColor,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(
    double total,
    double change,
    ThemeProvider themeProvider,
    NumberFormat format,
  ) {
    final isIncrease = change > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BÁO CÁO THÁNG ${DateTime.now().month}',
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${format.format(total)}đ',
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isIncrease ? Colors.red : Colors.green).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isIncrease ? '+' : ''}${change.toStringAsFixed(1)}% vs tháng trước',
                  style: TextStyle(
                    color: isIncrease ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: themeProvider.foregroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationSection(
    Map<String, double> spending,
    double total,
    ThemeProvider themeProvider,
  ) {
    if (spending.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu chi tiêu',
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.3),
          ),
        ),
      );
    }

    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayItems = sorted.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.foregroundColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: displayItems.map((entry) {
          final percent = total > 0 ? (entry.value / total) : 0.0;
          return Column(
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        themeProvider.foregroundColor.withOpacity(0.05),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        _getCategoryColor(entry.key),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: themeProvider.foregroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.key,
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart(
    List<TransactionModel> txs,
    ThemeProvider themeProvider,
  ) {
    final now = DateTime.now();
    List<Map<String, dynamic>> chartData = [];
    int itemCount = 7;

    if (_selectedTrendPeriod == 'Tuần') {
      itemCount = 7;
      chartData = List.generate(7, (i) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: 6 - i));
        final dailyTxs = txs.where((t) {
          final tDate = t.date;
          return tDate.year == date.year &&
              tDate.month == date.month &&
              tDate.day == date.day;
        }).toList();

        double income = 0;
        double expense = 0;
        double savings = 0;
        int incomeCount = 0;
        int expenseCount = 0;
        int savingsCount = 0;

        for (var t in dailyTxs) {
          final isSavings =
              t.category.contains('Tiết kiệm') || t.category.contains('Đầu tư');
          if (isSavings) {
            savings += t.amount;
            savingsCount++;
          } else if (t.type == TransactionType.income) {
            income += t.amount;
            incomeCount++;
          } else {
            expense += t.amount;
            expenseCount++;
          }
        }

        return {
          'date': date,
          'income': income,
          'expense': expense,
          'savings': savings,
          'incomeCount': incomeCount,
          'expenseCount': expenseCount,
          'savingsCount': savingsCount,
          'label': DateFormat('dd/MM').format(date),
          'shortLabel': DateFormat('E', 'vi_VN').format(date),
        };
      });
    } else if (_selectedTrendPeriod == 'Tháng') {
      itemCount = 4;
      chartData = List.generate(4, (i) {
        // Divide the last 28 days into 4 weeks
        final endDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: (3 - i) * 7));
        final startDay = endDay.subtract(const Duration(days: 6));

        final weeklyTxs = txs.where((t) {
          final tDate = t.date;
          return tDate.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
              tDate.isBefore(endDay.add(const Duration(days: 1)));
        }).toList();

        double income = 0;
        double expense = 0;
        double savings = 0;
        int incomeCount = 0;
        int expenseCount = 0;
        int savingsCount = 0;

        for (var t in weeklyTxs) {
          final isSavings =
              t.category.contains('Tiết kiệm') || t.category.contains('Đầu tư');
          if (isSavings) {
            savings += t.amount;
            savingsCount++;
          } else if (t.type == TransactionType.income) {
            income += t.amount;
            incomeCount++;
          } else {
            expense += t.amount;
            expenseCount++;
          }
        }

        return {
          'date': endDay,
          'income': income,
          'expense': expense,
          'savings': savings,
          'incomeCount': incomeCount,
          'expenseCount': expenseCount,
          'savingsCount': savingsCount,
          'label': 'Tuần ${i + 1}',
          'shortLabel': 'T${i + 1}',
        };
      });
    } else {
      // Year view - 12 months
      itemCount = 12;
      chartData = List.generate(12, (i) {
        final month = i + 1;
        final monthlyTxs = txs
            .where((t) => t.date.year == now.year && t.date.month == month)
            .toList();

        double income = 0;
        double expense = 0;
        double savings = 0;
        int incomeCount = 0;
        int expenseCount = 0;
        int savingsCount = 0;

        for (var t in monthlyTxs) {
          final isSavings =
              t.category.contains('Tiết kiệm') || t.category.contains('Đầu tư');
          if (isSavings) {
            savings += t.amount;
            savingsCount++;
          } else if (t.type == TransactionType.income) {
            income += t.amount;
            incomeCount++;
          } else {
            expense += t.amount;
            expenseCount++;
          }
        }

        return {
          'date': DateTime(now.year, month, 1),
          'income': income,
          'expense': expense,
          'savings': savings,
          'incomeCount': incomeCount,
          'expenseCount': expenseCount,
          'savingsCount': savingsCount,
          'label': 'Tháng $month',
          'shortLabel': 'T$month',
        };
      });
    }

    double maxVal = 0;
    for (var d in chartData) {
      if ((d['income'] as double) > maxVal) maxVal = d['income'] as double;
      if ((d['expense'] as double) > maxVal) maxVal = d['expense'] as double;
      if ((d['savings'] as double) > maxVal) maxVal = d['savings'] as double;
    }
    if (maxVal == 0) maxVal = 1000000;

    return Container(
      height: 300, // Increased height to accommodate selector
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.foregroundColor.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: themeProvider.foregroundColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['Tuần', 'Tháng', 'Năm'].map((period) {
                final isSelected = _selectedTrendPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTrendPeriod = period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.secondaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected
                                ? themeProvider.foregroundColor
                                : themeProvider.foregroundColor.withOpacity(
                                    0.4,
                                  ),
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend(
                'THU NHẬP',
                const Color(0xFF00E5FF),
                themeProvider,
              ), // Electric Cyan
              const SizedBox(width: 16),
              _buildChartLegend(
                'CHI TIÊU',
                const Color(0xFFFF2D55),
                themeProvider,
              ), // Rose Pink
              const SizedBox(width: 16),
              _buildChartLegend(
                'TIẾT KIỆM',
                const Color(0xFFBF5AF2),
                themeProvider,
              ), // Purple
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: themeProvider.secondaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = chartData[groupIndex];
                      final label = data['label'] as String;

                      String type = "";
                      String amountStr = NumberFormat.compactCurrency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(rod.toY);
                      int count = 0;

                      if (rodIndex == 0) {
                        type = "Thu nhập";
                        count = data['incomeCount'] as int;
                      } else if (rodIndex == 1) {
                        type = "Chi tiêu";
                        count = data['expenseCount'] as int;
                      } else {
                        type = "Tiết kiệm";
                        count = data['savingsCount'] as int;
                      }

                      return BarTooltipItem(
                        '$label\n',
                        TextStyle(
                          color: themeProvider.foregroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '$type: $amountStr\n',
                            style: TextStyle(
                              color: rod.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: 'Số lượng: $count',
                            style: TextStyle(
                              color: themeProvider.foregroundColor.withOpacity(
                                0.5,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
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
                        if (value < 0 || value >= itemCount)
                          return const SizedBox.shrink();
                        final data = chartData[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data['shortLabel'].toString(),
                            style: TextStyle(
                              color: themeProvider.foregroundColor.withOpacity(
                                0.3,
                              ),
                              fontSize: _selectedTrendPeriod == 'Năm' ? 8 : 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(itemCount, (i) {
                  final d = chartData[i];
                  return _makeGroupData(
                    i,
                    d['income'] as double,
                    d['expense'] as double,
                    d['savings'] as double,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                'TĂNG (THU NHẬP)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.trending_down, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                'GIẢM (CHI TIÊU)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(
    int x,
    double income,
    double expense,
    double savings,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: income,
          color: const Color(0xFF00E5FF),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: expense,
          color: const Color(0xFFFF2D55),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: savings,
          color: const Color(0xFFBF5AF2),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildChartLegend(
    String label,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDetails(
    Map<String, double> income,
    Map<String, double> spending,
    Map<String, double> savings,
    List<TransactionModel> txs,
    ThemeProvider themeProvider,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (income.isNotEmpty) ...[
          _buildSubSectionTitle('THU NHẬP', Colors.blue, themeProvider),
          const SizedBox(height: 12),
          ..._buildCategoryList(
            income,
            TransactionType.income,
            txs,
            themeProvider,
            format,
          ),
          const SizedBox(height: 24),
        ],
        if (spending.isNotEmpty) ...[
          _buildSubSectionTitle('CHI TIÊU', Colors.orange, themeProvider),
          const SizedBox(height: 12),
          ..._buildCategoryList(
            spending,
            TransactionType.expense,
            txs,
            themeProvider,
            format,
          ),
          const SizedBox(height: 24),
        ],
        if (savings.isNotEmpty) ...[
          _buildSubSectionTitle('TIẾT KIỆM', Colors.cyanAccent, themeProvider),
          const SizedBox(height: 12),
          ..._buildCategoryList(savings, null, txs, themeProvider, format),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSubSectionTitle(
    String title,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryList(
    Map<String, double> data,
    TransactionType? type,
    List<TransactionModel> txs,
    ThemeProvider themeProvider,
    NumberFormat format,
  ) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) {
      final count = txs
          .where(
            (tx) =>
                tx.category == entry.key && (type == null || tx.type == type),
          )
          .length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  color: _getCategoryColor(entry.key),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: themeProvider.foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$count giao dịch',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${format.format(entry.value)}đ',
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

Widget _buildOracleInsights(
  Map<String, double> spending,
  double income,
  double expense,
  ThemeProvider themeProvider,
) {
  String topCategory = "N/A";
  double topAmount = 0;
  spending.forEach((key, value) {
    if (value > topAmount) {
      topAmount = value;
      topCategory = key;
    }
  });

  final savings = income - expense;
  final savingsPercent = income > 0
      ? (savings / income * 100).toStringAsFixed(0)
      : "0";

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          themeProvider.secondaryColor.withOpacity(0.2),
          themeProvider.secondaryColor.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              'ORACLE INSIGHTS',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (topAmount > 0)
          _buildInsightItem(
            Icons.lightbulb_outline_rounded,
            'Hạng mục "$topCategory" đang chiếm tỷ trọng lớn nhất (${NumberFormat('#,###', 'vi_VN').format(topAmount)}đ). Hãy cân nhắc tối ưu hóa khoản này.',
            Colors.amberAccent,
            themeProvider,
          ),
        const SizedBox(height: 20),
        _buildInsightItem(
          Icons.savings_outlined,
          savings > 0
              ? 'Tỷ lệ tiết kiệm tháng này là $savingsPercent%. Bạn đang đi đúng hướng để đạt mục tiêu tài chính!'
              : 'Chi tiêu đang vượt quá thu nhập. Hãy xem lại danh sách giao dịch để cắt giảm các khoản không cần thiết.',
          savings > 0 ? Colors.greenAccent : Colors.redAccent,
          themeProvider,
        ),
      ],
    ),
  );
}

Widget _buildInsightItem(
  IconData icon,
  String text,
  Color color,
  ThemeProvider themeProvider,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: themeProvider.foregroundColor.withOpacity(0.7),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

Color _getCategoryColor(String category) {
  if (category.contains('Tiết kiệm')) return const Color(0xFFBF5AF2);
  if (category.contains('Đầu tư')) return const Color(0xFF5E5CE6);

  switch (category) {
    case 'Ăn uống':
      return const Color(0xFFFF9F0A);
    case 'Di chuyển':
      return const Color(0xFF64D2FF);
    case 'Mua sắm':
      return const Color(0xFFFF375F);
    case 'Giải trí':
      return const Color(0xFFA2845E);
    case 'Sức khỏe':
      return const Color(0xFF30D158);
    case 'Nhà cửa':
      return const Color(0xFF5E5CE6);
    case 'Giáo dục':
      return const Color(0xFFBF5AF2);
    default:
      return Colors.blueGrey;
  }
}

IconData _getCategoryIcon(String category) {
  if (category.contains('Tiết kiệm')) return Icons.savings_rounded;
  if (category.contains('Đầu tư')) return Icons.trending_up_rounded;

  switch (category) {
    case 'Ăn uống':
      return Icons.restaurant_rounded;
    case 'Di chuyển':
      return Icons.directions_car_rounded;
    case 'Mua sắm':
      return Icons.shopping_bag_rounded;
    case 'Giải trí':
      return Icons.movie_filter_rounded;
    case 'Sức khỏe':
      return Icons.medical_services_rounded;
    case 'Nhà cửa':
      return Icons.home_rounded;
    case 'Giáo dục':
      return Icons.school_rounded;
    default:
      return Icons.category_rounded;
  }
}

// --- TAB 4: CÀI ĐẶT ---
