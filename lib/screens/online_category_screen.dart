import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Màn hình chọn danh mục trực tuyến với nhiều icon đa dạng
// Online category selection screen with various icons
class OnlineCategoryScreen extends StatefulWidget {
  const OnlineCategoryScreen({super.key});

  @override
  State<OnlineCategoryScreen> createState() => _OnlineCategoryScreenState();
}

class _OnlineCategoryScreenState extends State<OnlineCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Danh sách danh mục "Trực tuyến" (Mô phỏng dữ liệu từ server)
  // Online categories list (Simulating data from server)
  final List<Map<String, dynamic>> _onlineCategories = [
    {
      'name': 'Netflix',
      'icon': Icons.movie_filter_rounded,
      'color': Colors.red,
    },
    {
      'name': 'Spotify',
      'icon': Icons.library_music_rounded,
      'color': Colors.green,
    },
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded, 'color': Colors.blue},
    {'name': 'Spa', 'icon': Icons.spa_rounded, 'color': Colors.pink},
    {'name': 'Coffee', 'icon': Icons.coffee_rounded, 'color': Colors.brown},
    {
      'name': 'Pizza',
      'icon': Icons.local_pizza_rounded,
      'color': Colors.orange,
    },
    {'name': 'Taxi', 'icon': Icons.local_taxi_rounded, 'color': Colors.yellow},
    {
      'name': 'Bay',
      'icon': Icons.flight_takeoff_rounded,
      'color': Colors.lightBlue,
    },
    {'name': 'Khách sạn', 'icon': Icons.hotel_rounded, 'color': Colors.indigo},
    {
      'name': 'Quà tặng',
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.purple,
    },
    {'name': 'Thú cưng', 'icon': Icons.pets_rounded, 'color': Colors.brown},
    {'name': 'Sửa xe', 'icon': Icons.build_rounded, 'color': Colors.grey},
    {
      'name': 'Cắt tóc',
      'icon': Icons.content_cut_rounded,
      'color': Colors.teal,
    },
    {
      'name': 'Sách',
      'icon': Icons.menu_book_rounded,
      'color': Colors.deepOrange,
    },
    {
      'name': 'Điện ảnh',
      'icon': Icons.movie_rounded,
      'color': Colors.redAccent,
    },
    {
      'name': 'Chụp ảnh',
      'icon': Icons.camera_alt_rounded,
      'color': Colors.cyan,
    },
    {
      'name': 'Thể thao',
      'icon': Icons.sports_soccer_rounded,
      'color': Colors.lightGreen,
    },
    {
      'name': 'Bóng rổ',
      'icon': Icons.sports_basketball_rounded,
      'color': Colors.deepOrangeAccent,
    },
    {
      'name': 'Cầu lông',
      'icon': Icons.sports_tennis_rounded,
      'color': Colors.yellowAccent,
    },
    {
      'name': 'Yoga',
      'icon': Icons.self_improvement_rounded,
      'color': Colors.purpleAccent,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Lọc danh sách theo tìm kiếm
    // Filter list based on search query
    final filteredCategories = _onlineCategories.where((cat) {
      return cat['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Nền tối đặc trưng của app
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DANH MỤC TRỰC TUYẾN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm Premium
          // Premium Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm danh mục mới...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF00D1FF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Thông báo cập nhật (Mô phỏng tính năng online)
          // Update notification (Simulating online feature)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_download_rounded,
                  color: Color(0xFF00D1FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Đã cập nhật 20 danh mục mới từ hệ thống',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lưới danh mục
          // Category Grid
          Expanded(
            child: filteredCategories.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      return _buildCategoryItem(cat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị khi không tìm thấy kết quả
  // Widget shown when no results are found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white.withOpacity(0.1),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy danh mục phù hợp',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Widget từng item danh mục
  // Category item widget
  Widget _buildCategoryItem(Map<String, dynamic> cat) {
    return InkWell(
      onTap: () {
        // Trả về kết quả cho màn hình trước
        // Return result to previous screen
        Navigator.pop(context, {
          'name': cat['name'],
          'icon': cat['icon'],
          'color': cat['color'],
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: (cat['color'] as Color).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(cat['icon'], color: cat['color'], size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              cat['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
