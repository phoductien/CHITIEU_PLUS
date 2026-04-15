import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/services/transaction_service.dart';
import 'package:chitieu_plus/utils/download_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chitieu_plus/widgets/custom_date_picker.dart';
import 'package:chitieu_plus/providers/user_provider.dart';

class TransactionTab extends StatefulWidget {
  const TransactionTab({super.key});

  @override
  State<TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<TransactionTab> {
  String _activeFilter = 'Hôm nay';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final transactionService = TransactionService();

      String format = 'db';
      if (kIsWeb) {
        if (!context.mounted) return;
        final chosen = await showDialog<String>(
          context: context,
          builder: (dialogCtx) {
            final theme = dialogCtx.read<ThemeProvider>();
            return AlertDialog(
              backgroundColor: theme.secondaryColor,
              title: Text(
                'Chọn định dạng xuất',
                style: TextStyle(color: theme.foregroundColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.data_object_rounded,
                      color: const Color(0xFFEC5B13),
                    ),
                    title: Text(
                      'JSON',
                      style: TextStyle(
                        color: theme.foregroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Dùng cho dữ liệu khối',
                      style: TextStyle(
                        color: theme.foregroundColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(dialogCtx, 'json'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.table_chart_rounded,
                      color: Colors.green,
                    ),
                    title: Text(
                      'CSV',
                      style: TextStyle(
                        color: theme.foregroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Dễ dàng mở bằng Excel',
                      style: TextStyle(
                        color: theme.foregroundColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(dialogCtx, 'csv'),
                  ),
                ],
              ),
            );
          },
        );
        if (chosen == null) return;
        format = chosen;
      }

      final fileExt = kIsWeb ? format : 'db';
      final fileTypeLabel = kIsWeb ? format.toUpperCase() : 'SQLite';

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang chuẩn bị dữ liệu $fileTypeLabel...')),
      );

      final bytes = await transactionService.exportAllToSqliteBytes(
        webFormat: format,
      );
      final fileName =
          'chitieu_plus_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$fileExt';

      await DownloadHelper.instance.downloadFile(bytes, fileName);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Đang tải xuống: $fileName'
                : 'Đã xuất database thành công: $fileName',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi xuất dữ liệu: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<TransactionModel> _getFilteredTransactions(
    List<TransactionModel> transactions,
  ) {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return transactions.where((tx) {
      final matchesQuery =
          tx.title.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query);

      bool matchesDate = true;
      if (_activeFilter == 'Hôm nay') {
        matchesDate =
            tx.date.year == today.year &&
            tx.date.month == today.month &&
            tx.date.day == today.day;
      } else if (_activeFilter == 'Tuần này') {
        matchesDate = tx.date.isAfter(
          weekStart.subtract(const Duration(seconds: 1)),
        );
      } else if (_activeFilter == 'Tháng này') {
        matchesDate =
            tx.date.year == monthStart.year &&
            tx.date.month == monthStart.month;
      } else if (_activeFilter == 'Tùy chỉnh' &&
          _customStartDate != null &&
          _customEndDate != null) {
        final start = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );
        final end = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          23,
          59,
          59,
        );
        matchesDate =
            tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(end.add(const Duration(seconds: 1)));
      }

      return matchesQuery && matchesDate;
    }).toList();
  }

  void _toggleSelectAll(List<TransactionModel> filtered) {
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        for (var tx in filtered) {
          _selectedIds.add(tx.id);
        }
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    
    final isLoading = transactionProvider.isLoading;
    final allTransactions = transactionProvider.transactions
        .where((tx) => tx.note != 'Nạp qua Ví dùng thử')
        .toList();
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    
    final isGuest = userProvider.bankAccounts.isEmpty;
    double simulatedBalance = 0;
    if (isGuest) {
      double realBalance = 0;
      double demoExpenses = 0;
      for (var tx in transactionProvider.transactions) {
        if (tx.wallet == 'main') {
          realBalance += (tx.type == TransactionType.income ? tx.amount : -tx.amount);
        } else if (tx.wallet == 'demo' && tx.type == TransactionType.expense) {
          demoExpenses += tx.amount;
        }
      }
      simulatedBalance = realBalance - demoExpenses;
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(themeProvider, filteredTransactions),
            _buildSearchAndFilters(themeProvider, filteredTransactions),
            if (isGuest) _buildDemoBalanceBanner(themeProvider, simulatedBalance),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEC5B13),
                      ),
                    )
                  : _buildGroupedTransactionList(
                      filteredTransactions,
                      themeProvider,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoBalanceBanner(ThemeProvider themeProvider, double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFFEC5B13).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFDF520F), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Số dư mô phỏng (Ví dùng thử)',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(balance)}đ',
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: themeProvider.secondaryColor,
                  title: Text('Xóa số dư?', style: TextStyle(color: themeProvider.foregroundColor)),
                  content: Text(
                    'Toàn bộ giao dịch giả lập và tiền nạp dùng thử sẽ bị xóa sạch để làm lại từ đầu.',
                    style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7)),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              
              if (confirm == true && mounted) {
                final txProvider = context.read<TransactionProvider>();
                final demoIds = txProvider.transactions.where((tx) => tx.note == 'Nạp qua Ví dùng thử' || tx.wallet == 'demo').map((tx) => tx.id).toList();
                if (demoIds.isNotEmpty) {
                  await txProvider.deleteTransactions(demoIds);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa số dư ví dùng thử')));
                  }
                }
              }
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEC5B13)),
            tooltip: 'Làm lại từ đầu',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeProvider themeProvider,
    List<TransactionModel> filtered,
  ) {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: themeProvider.foregroundColor,
              ),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            ),
            const SizedBox(width: 12),
            Text(
              'Đã chọn ${_selectedIds.length}',
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomDatePicker(
                  initialStartDate: _customStartDate,
                  initialEndDate: _customEndDate,
                  onApply: (start, end) {
                    setState(() {
                      _customStartDate = start;
                      _customEndDate = end;
                      _activeFilter = 'Tùy chỉnh';
                    });
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Text(
            'Giao dịch',
            style: TextStyle(
              color: themeProvider.foregroundColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEC5B13),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC5B13).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    final count = ids.length;
    final themeProvider = context.read<ThemeProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.secondaryColor,
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(color: themeProvider.foregroundColor),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa $count giao dịch đã chọn?',
          style: TextStyle(
            color: themeProvider.foregroundColor.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TransactionProvider>().deleteTransactions(ids);
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa $count giao dịch')));
      }
    }
  }

  Widget _buildSearchAndFilters(
    ThemeProvider themeProvider,
    List<TransactionModel> filtered,
  ) {
    final isAllSelected =
        filtered.isNotEmpty && _selectedIds.length == filtered.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: themeProvider.foregroundColor),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm giao dịch...',
                      hintStyle: TextStyle(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              if (_isSelectionMode) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _toggleSelectAll(filtered),
                  child: Row(
                    children: [
                      Text(
                        'Chọn tất cả',
                        style: TextStyle(
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isAllSelected,
                          onChanged: (_) => _toggleSelectAll(filtered),
                          activeColor: const Color(0xFFEC5B13),
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: themeProvider.foregroundColor.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _exportDatabase(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeProvider.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.output_rounded,
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.7,
                      ),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Xuất file',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('Hôm nay', themeProvider),
              _buildFilterChip('Tuần này', themeProvider),
              _buildFilterChip('Tháng này', themeProvider),
              _buildFilterChip('Tùy chỉnh', themeProvider),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilterChip(String label, ThemeProvider themeProvider) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC5B13)
              : themeProvider.secondaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : themeProvider.foregroundColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionList(
    List<TransactionModel> transactions,
    ThemeProvider themeProvider,
  ) {
    final filtered = transactions;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: themeProvider.foregroundColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có dữ liệu',
              style: TextStyle(
                color: themeProvider.foregroundColor.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (var tx in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTxs = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        double dayTotal = 0;
        for (var tx in dayTxs) {
          if (tx.type == TransactionType.expense) {
            dayTotal -= tx.amount;
          } else {
            dayTotal += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getFriendlyDate(date),
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${NumberFormat('#,###').format(dayTotal)}đ',
                    style: TextStyle(
                      color: dayTotal >= 0
                          ? Colors.green.withValues(alpha: 0.8)
                          : themeProvider.foregroundColor.withValues(
                              alpha: 0.5,
                            ),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...dayTxs.map((tx) => _buildTransactionCard(tx, themeProvider)),
          ],
        );
      },
    );
  }

  String _getFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    String prefix = '';
    if (txDate == today) {
      prefix = 'HÔM NAY, ';
    } else if (txDate == yesterday) {
      prefix = 'HÔM QUA, ';
    }

    return '$prefix${DateFormat('d THÁNG M').format(date).toUpperCase()}';
  }

  Widget _buildTransactionCard(
    TransactionModel tx,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _selectedIds.contains(tx.id);
    final isIncome = tx.type == TransactionType.income;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedIds.add(tx.id);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(tx.id);
              if (_selectedIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIds.add(tx.id);
            }
          });
        } else {
          _showTransactionDetails(context, tx, themeProvider);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC5B13).withValues(alpha: 0.1)
              : themeProvider.secondaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEC5B13).withValues(alpha: 0.5)
                : themeProvider.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? const Color(0xFFEC5B13)
                      : themeProvider.foregroundColor.withValues(alpha: 0.2),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getCategoryColor(tx.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _getCategoryIcon(tx.category),
                    color: _getCategoryColor(tx.category),
                    size: 20,
                  ),
                  if (tx.isPinned)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: const Icon(
                        Icons.push_pin_rounded,
                        color: Colors.yellowAccent,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('HH:mm').format(tx.date)} • ${tx.category}',
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                      style: TextStyle(
                        color: isIncome
                            ? const Color(0xFF4ADE80)
                            : themeProvider.foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (!_isSelectionMode)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: themeProvider.foregroundColor.withValues(
                            alpha: 0.3,
                          ),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 120),
                        color: themeProvider.secondaryColor,
                        onSelected: (value) async {
                          if (value == 'pin') {
                            await context.read<TransactionProvider>().togglePin(
                              tx.id,
                              tx.isPinned,
                            );
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: themeProvider.secondaryColor,
                                title: Text(
                                  'Xác nhận xóa',
                                  style: TextStyle(
                                    color: themeProvider.foregroundColor,
                                  ),
                                ),
                                content: Text(
                                  'Giao dịch này sẽ bị xóa vĩnh viễn.',
                                  style: TextStyle(
                                    color: themeProvider.foregroundColor
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              await context
                                  .read<TransactionProvider>()
                                  .deleteTransaction(tx.id);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(
                                  tx.isPinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  tx.isPinned ? 'Bỏ ghim' : 'Ghim',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Xóa',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel tx, ThemeProvider themeProvider) {
    final userProvider = context.read<UserProvider>();
    final isGuest = userProvider.bankAccounts.isEmpty;

    List<TransactionModel> walletTransactions;
    if (isGuest && (tx.wallet == 'main' || tx.wallet == 'demo')) {
      walletTransactions = context.read<TransactionProvider>().transactions
          .where((t) => t.wallet == 'main' || t.wallet == 'demo')
          .toList();
    } else {
       walletTransactions = context.read<TransactionProvider>().transactions
          .where((t) => t.wallet == tx.wallet)
          .toList();
    }
    
    walletTransactions.sort((a, b) => a.date.compareTo(b.date));
    double runningBalance = 0;
    for(var t in walletTransactions) {
      if(t.type == TransactionType.income) runningBalance += t.amount;
      else runningBalance -= t.amount;
      
      if(t.id == tx.id) break;
    }
    
    final endingBalance = runningBalance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeProvider.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeProvider.foregroundColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(tx.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(tx.category),
                      color: _getCategoryColor(tx.category),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: TextStyle(
                            color: themeProvider.foregroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tx.category,
                          style: TextStyle(
                            color: themeProvider.foregroundColor.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeProvider.borderColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Số tiền', '${tx.type == TransactionType.income ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ', themeProvider, isAmount: true, isIncome: tx.type == TransactionType.income),
                    const Divider(height: 24),
                    _buildDetailRow('Thời gian', DateFormat('HH:mm:ss - dd/MM/yyyy').format(tx.date), themeProvider),
                    const SizedBox(height: 12),
                    _buildDetailRow('Tài khoản', isGuest ? 'Ví dùng thử' : (tx.wallet == 'main' ? 'Ví chính' : tx.wallet), themeProvider),
                    const SizedBox(height: 12),
                    _buildDetailRow('Số dư cuối', '${NumberFormat('#,###').format(endingBalance)}đ', themeProvider),
                    const SizedBox(height: 12),
                    _buildDetailRow('Nội dung', (tx.note != null && tx.note!.isNotEmpty) ? tx.note! : 'Không có ghi chú', themeProvider),
                    const SizedBox(height: 12),
                    _buildDetailRow('Mã GD', tx.id, themeProvider, isId: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeProvider themeProvider, {bool isAmount = false, bool isIncome = false, bool isId = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeProvider.foregroundColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isAmount ? (isIncome ? const Color(0xFF4ADE80) : Colors.redAccent) : (isId ? themeProvider.foregroundColor.withValues(alpha: 0.4) : themeProvider.foregroundColor),
              fontSize: isId ? 11 : (isAmount ? 18 : 14),
              fontWeight: (isAmount || isId == false) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Di chuyển':
        return Icons.directions_car_rounded;
      case 'Lương':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return const Color(0xFFF97316);
      case 'Mua sắm':
        return const Color(0xFF3B82F6);
      case 'Di chuyển':
        return const Color(0xFFA855F7);
      case 'Lương':
        return const Color(0xFF22C55E);
      default:
        return Colors.blueGrey;
    }
  }
}

// --- TAB 3: NGÂN SÁCH ---
