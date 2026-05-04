import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:intl/intl.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  late double _totalBudget;
  late Map<String, double> _categoryBudgets;
  late TextEditingController _totalBudgetController;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _totalBudget = userProvider.totalBudget;
    _categoryBudgets = Map.from(userProvider.categoryBudgets);

    // Initial default categories if empty
    if (_categoryBudgets.isEmpty) {
      _categoryBudgets = {
        'Ăn uống': 0,
        'Mua sắm': 0,
        'Di chuyển': 0,
        'Nhà cửa': 0,
        'Giải trí': 0,
        'Hóa đơn': 0,
        'Khác': 0,
      };
    }
    _totalBudgetController = TextEditingController(
      text: NumberFormat('#,###').format(_totalBudget),
    );
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  final Map<String, IconData> _catIcons = {
    'Ăn uống': Icons.restaurant,
    'Mua sắm': Icons.shopping_bag,
    'Di chuyển': Icons.directions_car,
    'Nhà cửa': Icons.home,
    'Giải trí': Icons.theater_comedy,
    'Hóa đơn': Icons.receipt,
    'Khác': Icons.more_horiz,
  };

  final Map<String, Color> _catColors = {
    'Ăn uống': const Color(0xFFF05D15),
    'Mua sắm': Colors.blue,
    'Di chuyển': Colors.green,
    'Nhà cửa': Colors.brown,
    'Giải trí': Colors.pink,
    'Hóa đơn': Colors.purple,
    'Khác': Colors.grey,
  };

  double get _allocated => _categoryBudgets.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.foregroundColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thiết lập ngân sách',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(themeProvider),
                  const SizedBox(height: 30),
                  Text(
                    'PHÂN BỐ THEO HẠNG MỤC',
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.6,
                      ),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categoryBudgets.keys.map(
                    (cat) => _buildCategorySlider(cat, themeProvider),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final userProvider = context.read<UserProvider>();
                  await userProvider.setTotalBudget(_totalBudget);
                  await userProvider.setCategoryBudgets(_categoryBudgets);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC5B13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lưu thiết lập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TỔNG NGÂN SÁCH DỰ KIẾN',
            style: TextStyle(
              color: themeProvider.foregroundColor.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'đ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  controller: _totalBudgetController,
                  onChanged: (val) {
                    final normalized = val.replaceAll(',', '');
                    final parsed = double.tryParse(normalized);
                    if (parsed != null) {
                      setState(() {
                        _totalBudget = parsed;
                      });
                      // Update selection
                      final formatted = NumberFormat('#,###').format(parsed);
                      _totalBudgetController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ĐÃ PHÂN BỐ',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Text(
                'đ ${NumberFormat('#,###').format(_allocated)}',
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _totalBudget > 0
                  ? (_allocated / _totalBudget).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: themeProvider.foregroundColor.withValues(
                alpha: 0.1,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                _allocated > _totalBudget
                    ? Colors.redAccent
                    : const Color(0xFF10B981),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlider(String category, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _catColors[category]!.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _catIcons[category],
                  color: _catColors[category],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeProvider.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'đ',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###').format(_categoryBudgets[category]),
                      style: TextStyle(
                        color: themeProvider.foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFFF05D15),
              inactiveTrackColor: themeProvider.foregroundColor.withValues(
                alpha: 0.1,
              ),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFF05D15).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _categoryBudgets[category]!,
              min: 0,
              max: _totalBudget > 0 ? _totalBudget : 1000000,
              onChanged: (val) {
                setState(() {
                  _categoryBudgets[category] = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
