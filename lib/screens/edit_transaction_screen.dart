import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/premium_date_picker.dart';
import 'online_category_screen.dart'; // Thêm import màn hình danh mục trực tuyến

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedWallet;
  late TransactionType _selectedType;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Ăn uống',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFF97316),
    },
    {
      'name': 'Mua sắm',
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Di chuyển',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFFA855F7),
    },
    {
      'name': 'Lương',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF22C55E),
    },
    {
      'name': 'Giải trí',
      'icon': Icons.videogame_asset_rounded,
      'color': const Color(0xFF14B8A6),
    },
    {
      'name': 'Sức khỏe',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Học phí',
      'icon': Icons.school_rounded,
      'color': const Color(0xFFFACC15),
    },
    {
      'name': 'Bảo hiểm',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Tiền điện',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Tiền nước',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF0EA5E9),
    },
    {
      'name': 'Tiền Gas',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Nạp điện thoại',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Nhà cửa',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF64748B),
    },
    {'name': 'Khác', 'icon': Icons.category_rounded, 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo các giá trị từ giao dịch hiện tại
    // Initialize values from the current transaction
    _amountController = TextEditingController(
      text: widget.transaction.amount.toInt().toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedDate = widget.transaction.date;
    _selectedCategory = widget.transaction.category;
    _selectedWallet = widget.transaction.wallet;
    _selectedType = widget.transaction.type;

    // Kiểm tra nếu danh mục hiện tại không có trong danh sách mặc định (có thể là danh mục online đã chọn trước đó)
    // Check if the current category is not in the default list (might be a previously selected online category)
    if (!_categories.any((c) => c['name'] == _selectedCategory)) {
      _categories.insert(_categories.length - 1, {
        'name': _selectedCategory,
        'icon': Icons
            .category_rounded, // Sử dụng icon mặc định hoặc có thể lưu icon trong DB sau này
        'color': Colors.blueGrey,
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final wallets = ['main', ...userProvider.bankAccounts.map((b) => b)];

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT TRANSACTION',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'ChiTieuPlus',
                style: TextStyle(
                  color: const Color(0xFFFEA866),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Tiêu đề phụ và Hiển thị số tiền lớn
            Text(
              'SỐ TIỀN GIAO DỊCH',
              style: TextStyle(
                color: themeProvider.foregroundColor.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFEA866),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white10),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'đ',
                  style: TextStyle(
                    color: const Color(0xFFFEA866).withOpacity(0.7),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Các thẻ lựa chọn chi tiết
            // 1. Danh mục
            _buildSelectionSection(
              'DANH MỤC',
              _selectedCategory,
              _getIconForCategory(_selectedCategory),
              'Thay đổi',
              () => _showCategoryPicker(context, themeProvider),
              themeProvider,
            ),
            const SizedBox(height: 20),

            // 2. Ngày và Giờ giao dịch (Premium UI - Hình 2)
            const Text(
              'NGÀY GIAO DỊCH',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Ô chọn Ngày
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _selectDateTime(context, themeProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E293B).withOpacity(0.5),
                            const Color(0xFF0F172A).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF00D1FF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'dd/MM/yyyy',
                                'vi',
                              ).format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ô chọn Giờ
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _selectDateTime(context, themeProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E293B).withOpacity(0.5),
                            const Color(0xFF0F172A).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF00D1FF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat('HH:mm').format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Tài khoản thanh toán
            _buildWalletSection(
              'TÀI KHOẢN THANH TOÁN',
              _selectedWallet == 'main' ? 'Ví chính' : _selectedWallet,
              Icons.account_balance_wallet_rounded,
              () => _showWalletPicker(context, wallets, themeProvider),
              themeProvider,
            ),
            const SizedBox(height: 24),

            // 4. Ghi chú giao dịch
            _buildNoteSection(themeProvider),
            const SizedBox(height: 48),

            // Nút Lưu thay đổi - Gradient nổi bật
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEA866), Color(0xFFFB923C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFB923C).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _saveChanges(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'LƯU THAY ĐỔI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nút Hủy bỏ
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'HỦY BỎ',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị phần chọn thông tin (Danh mục, Ngày)
  Widget _buildSelectionSection(
    String label,
    String value,
    IconData icon,
    String buttonText,
    VoidCallback onTap,
    ThemeProvider themeProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFEA866), size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: themeProvider.foregroundColor.withOpacity(0.4),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị phần chọn Ví/Tài khoản
  Widget _buildWalletSection(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
    ThemeProvider themeProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFEA866), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: themeProvider.foregroundColor.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: themeProvider.foregroundColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị phần Ghi chú
  Widget _buildNoteSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                color: themeProvider.foregroundColor.withOpacity(0.4),
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'GHI CHÚ GIAO DỊCH',
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            style: TextStyle(
              color: themeProvider.foregroundColor,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú...',
              hintStyle: TextStyle(color: Colors.white10),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Hàm xử lý chọn ngày và giờ với giao diện cao cấp (Premium UI)
  Future<void> _selectDateTime(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    // Hiển thị hộp thoại chọn ngày Premium mới (khớp với Hình 2)
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => PremiumDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      ),
    );

    // Nếu người dùng đã chọn ngày, tiếp tục hiển thị hộp thoại chọn giờ
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              // Đồng bộ màu sắc với DatePicker
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFEC5B13),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
              // Tùy chỉnh giao diện TimePicker
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF0F172A),
                hourMinuteColor: const Color(0xFF1E293B),
                hourMinuteTextColor: Colors.white,
                dialBackgroundColor: const Color(0xFF1E293B),
                dialHandColor: const Color(0xFFEC5B13),
                dialTextColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00D1FF),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Hiển thị danh sách danh mục để chọn
  void _showCategoryPicker(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat['name'];
            return InkWell(
              onTap: () async {
                // Nếu chọn "Khác", mở màn hình danh mục trực tuyến
                // If "Other" is selected, open online category screen
                if (cat['name'] == 'Khác') {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnlineCategoryScreen(),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _selectedCategory = result['name'];
                      // Thêm vào danh sách tạm thời nếu chưa có để hiển thị highlight
                      // Add to temporary list if not present to show highlight
                      if (!_categories.any(
                        (c) => c['name'] == result['name'],
                      )) {
                        _categories.insert(_categories.length - 1, {
                          'name': result['name'],
                          'icon': result['icon'],
                          'color': result['color'],
                        });
                      }
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                } else {
                  setState(() => _selectedCategory = cat['name']);
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat['color']
                          : cat['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      cat['icon'],
                      color: isSelected ? Colors.white : cat['color'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      color: themeProvider.foregroundColor,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Hiển thị danh sách ví để chọn
  void _showWalletPicker(
    BuildContext context,
    List<String> wallets,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: wallets.map((w) {
            return ListTile(
              title: Text(
                w == 'main' ? 'Ví chính' : w,
                style: TextStyle(color: themeProvider.foregroundColor),
              ),
              trailing: _selectedWallet == w
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFEC5B13),
                    )
                  : null,
              onTap: () {
                setState(() => _selectedWallet = w);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Thực hiện lưu thay đổi giao dịch
  void _saveChanges(BuildContext context) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final updatedTransaction = widget.transaction.copyWith(
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      wallet: _selectedWallet,
      note: _noteController.text,
      title: widget
          .transaction
          .title, // Giữ nguyên title hoặc có thể cho sửa nếu muốn
    );

    try {
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).updateTransaction(updatedTransaction);
      if (mounted) {
        Navigator.pop(context); // Quay lại trang chi tiết
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giao dịch thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  IconData _getIconForCategory(String name) {
    return _categories.firstWhere(
      (c) => c['name'] == name,
      orElse: () => _categories.last,
    )['icon'];
  }
}
