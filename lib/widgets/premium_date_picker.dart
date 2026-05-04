import 'package:flutter/material.dart';

/// Một widget chọn ngày cao cấp với thiết kế hiện đại, hiệu ứng ánh sáng (glow)
/// và hoàn toàn bằng tiếng Việt.
class PremiumDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const PremiumDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<PremiumDatePicker> createState() => _PremiumDatePickerState();
}

class _PremiumDatePickerState extends State<PremiumDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  // Danh sách tên tháng tiếng Việt
  final List<String> _vietnameseMonths = [
    'Tháng 01',
    'Tháng 02',
    'Tháng 03',
    'Tháng 04',
    'Tháng 05',
    'Tháng 06',
    'Tháng 07',
    'Tháng 08',
    'Tháng 09',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      // Điều chỉnh khoảng cách lề để kích thước vừa phải
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ), // Kích thước gọn gàng hơn
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Hiển thị Tháng và Năm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(Icons.chevron_left, _previousMonth),
                    Column(
                      children: [
                        Text(
                          _vietnameseMonths[_currentMonth.month - 1]
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF00D1FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Color(0xFF00D1FF), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NĂM ${_currentMonth.year}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    _buildNavButton(Icons.chevron_right, _nextMonth),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hàng hiển thị Thứ trong tuần (Tiếng Việt)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: (day == 'CN' || day == 'T7')
                              ? const Color(0xFFEC5B13).withOpacity(0.8)
                              : Colors.white.withOpacity(0.2),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Lưới lịch
              Flexible(child: _buildDaysGrid()),

              const SizedBox(height: 16),

              // Nút bấm Hành động: HỦY và CHỌN
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      text: 'HỦY',
                      onTap: () => Navigator.pop(context),
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      text: 'CHỌN',
                      onTap: () => Navigator.pop(context, _selectedDate),
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.03),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;
    final prevMonthLastDay = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;

    List<Widget> dayWidgets = [];

    // Ngày của tháng trước
    for (int i = firstDayOffset - 1; i >= 0; i--) {
      dayWidgets.add(
        _buildDayCell(prevMonthLastDay - i, isCurrentMonth: false),
      );
    }

    // Ngày của tháng hiện tại
    for (int i = 1; i <= daysInMonth; i++) {
      dayWidgets.add(_buildDayCell(i, isCurrentMonth: true));
    }

    // Ngày của tháng sau
    int remainingCells = 42 - dayWidgets.length;
    for (int i = 1; i <= remainingCells; i++) {
      dayWidgets.add(_buildDayCell(i, isCurrentMonth: false));
    }

    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(int day, {required bool isCurrentMonth}) {
    final bool isSelected =
        isCurrentMonth &&
        _selectedDate.day == day &&
        _selectedDate.month == _currentMonth.month &&
        _selectedDate.year == _currentMonth.year;

    final bool isToday =
        isCurrentMonth &&
        DateTime.now().day == day &&
        DateTime.now().month == _currentMonth.month &&
        DateTime.now().year == _currentMonth.year;

    return Center(
      child: GestureDetector(
        onTap: isCurrentMonth
            ? () => setState(
                () => _selectedDate = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                ),
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 32, // Nhỏ hơn một chút để cân đối
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00D1FF), Color(0xFF00B4DB)],
                  )
                : isToday
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D1FF).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
            border: isToday && !isSelected
                ? Border.all(
                    color: const Color(0xFF00D1FF).withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                    ? (isToday
                          ? const Color(0xFF00D1FF)
                          : Colors.white.withOpacity(0.8))
                    : Colors.white.withOpacity(0.1),
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
