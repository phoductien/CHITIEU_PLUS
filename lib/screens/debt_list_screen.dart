import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/debt_card.dart';
import 'add_debt_screen.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý NỢ & Cho vay'),
        backgroundColor: Colors.transparent,
        foregroundColor: themeProvider.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDebtScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryStats(debtProvider),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFF05D15),
            labelColor: const Color(0xFFF05D15),
            unselectedLabelColor: themeProvider.foregroundColor.withOpacity(0.5),
            tabs: const [
              Tab(text: 'CHƯA TRẢ'),
              Tab(text: 'ĐÃ TRẢ'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDebtList(debtProvider.pendingDebts, debtProvider.isLoading, context),
                _buildDebtList(debtProvider.paidDebts, debtProvider.isLoading, context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddDebtScreen()),
        ),
        backgroundColor: const Color(0xFFF05D15),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryStats(DebtProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FadeInLeft(
              child: _buildStatItem(
                'Cho vay',
                provider.totalLoan,
                const Color(0xFF10B981),
                Icons.arrow_downward_rounded,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FadeInRight(
              child: _buildStatItem(
                'NỢ bạn',
                provider.totalDebt,
                const Color(0xFFEF4444),
                Icons.arrow_upward_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###').format(amount)} đ',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList(List<dynamic> debts, bool isLoading, BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF05D15)));
    }

    if (debts.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        return DebtCard(
          debt: debt,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDebtScreen(debt: debt)),
          ),
          onToggleStatus: () => context.read<DebtProvider>().toggleStatus(debt),
        );
      },
    );
  }
}

