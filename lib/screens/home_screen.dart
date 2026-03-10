import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  final String? welcomeMessage;
  const HomeScreen({super.key, this.welcomeMessage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.welcomeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.welcomeMessage!),
              backgroundColor: const Color(0xFF0D47A1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chào mừng,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            userProvider.name.isNotEmpty ? userProvider.name : 'Nguyễn Văn A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                  );
                                },
                              ),
                              if (notificationProvider.unreadCount > 0)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6D00),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        notificationProvider.unreadCount > 9 ? '9+' : notificationProvider.unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFFFD180),
                            backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                // Wallet Card
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B),
                          Color(0xFF1E293B).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onLongPress: () {
                                notificationProvider.addNotification(
                                  title: 'Demo Thông báo',
                                  body: 'Đây là thông báo mẫu được gửi lúc ${DateTime.now().hour}:${DateTime.now().minute}',
                                  type: NotificationType.aiReminder,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã gửi thông báo demo!')),
                                );
                              },
                              child: const Text(
                                'Ví chính',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBalanceVisible = !_isBalanceVisible;
                                });
                              },
                              child: Icon(
                                _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _isBalanceVisible ? '25,000,000' : '*********',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'đ',
                              style: TextStyle(
                                color: Color(0xFFFF6D00),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6D00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Chi tiết',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Spending Trends Section
                _buildSectionHeader('Xu hướng chi tiêu', 'Tuần này'),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _buildBarChart(),
                  ),
                ),
                const SizedBox(height: 30),
                // Expense Allocation Section
                _buildSectionHeader('Phân bổ chi tiêu', null),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _buildDonutChart(),
                  ),
                ),
                const SizedBox(height: 30),
                // Recent Transactions Section
                _buildSectionHeader('Giao dịch gần đây', 'Tất cả'),
                const SizedBox(height: 16),
                _buildTransactionList(),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFF6D00),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildSectionHeader(String title, String? actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 45),
          _makeGroupData(1, 35),
          _makeGroupData(2, 65),
          _makeGroupData(3, 30),
          _makeGroupData(4, 50),
          _makeGroupData(5, 40),
          _makeGroupData(6, 25),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF334155),
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart() {
    return Row(
      children: [
        SizedBox(
          height: 130,
          width: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(color: const Color(0xFFFF6D00), value: 45, radius: 20, showTitle: false),
                PieChartSectionData(color: const Color(0xFF2196F3), value: 25, radius: 22, showTitle: false),
                PieChartSectionData(color: const Color(0xFF4CAF50), value: 15, radius: 18, showTitle: false),
                PieChartSectionData(color: const Color(0xFFFFEB3B), value: 15, radius: 16, showTitle: false),
              ],
            ),
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            children: [
              _buildAllocationItem('Ăn uống', '45%', const Color(0xFFFF6D00)),
              _buildAllocationItem('Mua sắm', '25%', const Color(0xFF2196F3)),
              _buildAllocationItem('Di chuyển', '15%', const Color(0xFF4CAF50)),
              _buildAllocationItem('Khác', '15%', const Color(0xFFFFEB3B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationItem(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Text(percent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      {'title': 'Phở Lý Quốc Sư', 'time': 'Hôm nay, 08:30', 'amount': '- 65.000đ', 'category': 'ĂN UỐNG', 'icon': Icons.restaurant_rounded, 'color': Colors.orange},
      {'title': 'Uniqlo Vincom', 'time': 'Hôm qua, 19:15', 'amount': '- 499.000đ', 'category': 'MUA SẮM', 'icon': Icons.shopping_bag_rounded, 'color': Colors.blue},
      {'title': 'Grab Bike', 'time': 'Hôm qua, 07:45', 'amount': '- 22.000đ', 'category': 'DI CHUYỂN', 'icon': Icons.motorcycle_rounded, 'color': Colors.green},
    ];

    return Column(
      children: transactions.map((tx) {
        return FadeInRight(
          duration: const Duration(milliseconds: 600),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tx['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(tx['icon'] as IconData, color: tx['color'] as Color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(tx['time'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tx['amount'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(tx['category'] as String, style: TextStyle(color: (tx['color'] as Color).withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: const Color(0xFF1E293B),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Trang chủ'),
            _buildNavItem(1, Icons.receipt_long_rounded, 'Giao dịch'),
            const SizedBox(width: 40),
            _buildNavItem(2, Icons.pie_chart_rounded, 'Báo cáo'),
            _buildNavItem(3, Icons.settings_rounded, 'Cài đặt'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFFF6D00) : Colors.white54),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF6D00) : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

