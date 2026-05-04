import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../widgets/premium_date_picker.dart'; // Thêm import
import 'package:chitieu_plus/providers/app_session_provider.dart';
import '../models/saving_goal_model.dart';
import '../providers/saving_goal_provider.dart';

class AddSavingGoalScreen extends StatefulWidget {
  final SavingGoalModel? initialGoal;
  const AddSavingGoalScreen({super.key, this.initialGoal});

  @override
  State<AddSavingGoalScreen> createState() => _AddSavingGoalScreenState();
}

class _AddSavingGoalScreenState extends State<AddSavingGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  String _selectedIcon = 'savings';
  String _selectedColor = '#F05D15';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'savings', 'icon': Icons.savings_rounded},
    {'name': 'home', 'icon': Icons.home_rounded},
    {'name': 'flight', 'icon': Icons.flight_rounded},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded},
    {'name': 'laptop', 'icon': Icons.laptop_mac_rounded},
    {'name': 'phone', 'icon': Icons.phone_android_rounded},
    {'name': 'star', 'icon': Icons.star_rounded},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded},
  ];

  final List<String> _colors = [
    '#F05D15', // Cam đặc trưng
    '#3B82F6', // Xanh dương
    '#10B981', // Xanh lá
    '#FACC15', // Vàng
    '#EC4899', // Hồng
    '#8B5CF6', // Tím
    '#64748B', // Xám
    '#14B8A6', // Xanh ngọc
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialGoal != null) {
      _titleController.text = widget.initialGoal!.title;
      _targetController.text = widget.initialGoal!.targetAmount
          .toInt()
          .toString();
      _currentController.text = widget.initialGoal!.currentAmount
          .toInt()
          .toString();
      _selectedDate = widget.initialGoal!.deadline;
      _selectedIcon = widget.initialGoal!.icon;
      _selectedColor = widget.initialGoal!.color;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSessionProvider>().setLastRoute('add_saving_goal');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  // Hàm chọn ngày hạn định với giao diện Premium (Image 2 style)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => PremiumDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final goal = SavingGoalModel(
      id: widget.initialGoal?.id ?? const Uuid().v4(),
      userId: user.uid,
      title: _titleController.text.trim(),
      targetAmount: double.parse(
        _targetController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ),
      currentAmount:
          double.tryParse(
            _currentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0.0,
      deadline: _selectedDate,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: widget.initialGoal?.createdAt ?? DateTime.now(),
    );

    try {
      await context.read<SavingGoalProvider>().saveGoal(goal);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialGoal == null
                  ? 'Đã tạo mục tiêu mới!'
                  : 'Đã cập nhật mục tiêu!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialGoal == null
              ? 'Tạo mục tiêu mới'
              : 'Chỉnh sửa mục tiêu',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'TÊN MỤC TIÊU',
                hint: 'Ví dụ: Mua iPhone 16 Pro Max',
                icon: Icons.edit_note_rounded,
                validator: (v) =>
                    v!.isEmpty ? 'Vui lòng nhập tên mục tiêu' : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _targetController,
                label: 'SỐ TIỀN CẦN TIẾT KIỆM',
                hint: '0',
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
                suffixText: 'đ',
                validator: (v) =>
                    v!.isEmpty ? 'Vui lòng nhập số tiền mục tiêu' : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _currentController,
                label: 'SỐ TIỀN ĐÃ CÓ (TÙY CHỌN)',
                hint: '0',
                icon: Icons.account_balance_wallet_rounded,
                keyboardType: TextInputType.number,
                suffixText: 'đ',
              ),
              const SizedBox(height: 24),
              _buildDateField(),
              const SizedBox(height: 32),
              const Text(
                'BIỂU TƯỢNG',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildIconPicker(),
              const SizedBox(height: 32),
              const Text(
                'MÀU SẮC',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF05D15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'LƯU MỤC TIÊU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (widget.initialGoal != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<SavingGoalProvider>().deleteGoal(
                        widget.initialGoal!.id,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'XÓA MỤC TIÊU',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HẠN ĐỊNH',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.5),
                  const Color(0xFF0F172A).withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _icons.map((icon) {
        final isSelected = _selectedIcon == icon['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = icon['name']),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF05D15)
                  : const Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon['icon'],
              color: isSelected ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors.map((colorHex) {
        final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        final isSelected = _selectedColor == colorHex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorHex),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
