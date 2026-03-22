import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class EyeProtectionScreen extends StatefulWidget {
  const EyeProtectionScreen({super.key});

  @override
  State<EyeProtectionScreen> createState() => _EyeProtectionScreenState();
}

class _EyeProtectionScreenState extends State<EyeProtectionScreen> {
  String _selectedMode = 'Cơ bản'; // 'Cơ bản' or 'Giấy'
  bool _isScheduled = false;
  double _colorTemperature = 0.5;
  double _textureLevel = 0.2;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isEyeProtectionOn = themeProvider.isEyeProtection;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: themeProvider.secondaryColor.withValues(alpha: 0.9),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: themeProvider.foregroundColor),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _selectedMode,
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2E1B4E), // Deep purple-ish
                      Color(0xFF0F172A), // Matches dark background
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Chế độ', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    child: Column(
                      children: [
                        _buildMainSwitch(
                          title: 'Chế độ đọc',
                          value: isEyeProtectionOn,
                          onChanged: (val) => themeProvider.toggleEyeProtection(val),
                          themeProvider: themeProvider,
                        ),
                        if (isEyeProtectionOn) ...[
                          Divider(color: themeProvider.borderColor, height: 1),
                          _buildModeOption(
                            icon: Icons.wb_sunny_rounded,
                            title: 'Cơ bản',
                            subtitle: 'Điều chỉnh nhiệt độ màu và kết cấu',
                            isSelected: _selectedMode == 'Cơ bản',
                            onTap: () => setState(() => _selectedMode = 'Cơ bản'),
                            themeProvider: themeProvider,
                          ),
                          _buildModeOption(
                            icon: Icons.description_rounded,
                            title: 'Giấy',
                            subtitle: 'Giảm mỏi mắt với hiệu ứng vân giấy',
                            isSelected: _selectedMode == 'Giấy',
                            onTap: () => setState(() => _selectedMode = 'Giấy'),
                            themeProvider: themeProvider,
                          ),
                        ]
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Lịch trình', themeProvider),
                  _buildCard(
                    themeProvider: themeProvider,
                    child: _buildScheduledSwitch(
                      title: 'Lên lịch',
                      subtitle: 'Đặt thời gian bật và tắt Chế độ đọc',
                      value: _isScheduled,
                      onChanged: (val) => setState(() => _isScheduled = val),
                      themeProvider: themeProvider,
                    ),
                  ),
                  
                  if (isEyeProtectionOn) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Cài đặt chế độ đọc', themeProvider),
                    _buildCard(
                      themeProvider: themeProvider,
                      child: Column(
                        children: [
                          _buildSliderSetting(
                            icon: Icons.tonality_rounded,
                            title: 'Nhiệt độ màu',
                            value: _colorTemperature,
                            onChanged: (val) => setState(() => _colorTemperature = val),
                            themeProvider: themeProvider,
                            gradientColors: const [Color(0xFF64B5F6), Color(0xFFFFB74D)],
                          ),
                          Divider(color: themeProvider.borderColor, height: 1, indent: 20, endIndent: 20),
                          _buildSliderSetting(
                            icon: Icons.texture_rounded,
                            title: 'Kết cấu',
                            value: _textureLevel,
                            onChanged: (val) => setState(() => _textureLevel = val),
                            themeProvider: themeProvider,
                            gradientColors: const [Colors.white, Color(0xFF9E9E9E)],
                          ),
                          Divider(color: themeProvider.borderColor, height: 1, indent: 20, endIndent: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Màu sắc',
                                  style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Tất cả màu',
                                  style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _colorTemperature = 0.5;
                            _textureLevel = 0.2;
                            _selectedMode = 'Cơ bản';
                            _isScheduled = false;
                          });
                        },
                        child: const Text(
                          'Khôi phục mặc định',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: themeProvider.foregroundColor.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required ThemeProvider themeProvider}) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildMainSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeProvider themeProvider,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF8C9EFF), // Soft blue for active switch matching screenshot
            activeTrackColor: const Color(0xFF8C9EFF).withValues(alpha: 0.3),
            inactiveThumbColor: themeProvider.foregroundColor.withValues(alpha: 0.4),
            inactiveTrackColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeProvider themeProvider,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFE6B48F), // Peach/orange-ish thumb matching screenshot
            activeTrackColor: const Color(0xFFE6B48F).withValues(alpha: 0.3),
            inactiveThumbColor: themeProvider.foregroundColor.withValues(alpha: 0.4),
            inactiveTrackColor: themeProvider.foregroundColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF8C9EFF) : themeProvider.foregroundColor.withValues(alpha: 0.5), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? const Color(0xFF8C9EFF) : themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF8C9EFF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required ThemeProvider themeProvider,
    required List<Color> gradientColors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: themeProvider.foregroundColor.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: themeProvider.foregroundColor, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 32,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 2),
                overlayColor: Colors.white.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
