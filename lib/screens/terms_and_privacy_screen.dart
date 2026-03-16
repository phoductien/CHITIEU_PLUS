import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  final int initialTabIndex;

  const TermsAndPrivacyScreen({
    super.key,
    this.initialTabIndex = 0, // 0 for Privacy, 1 for Terms
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F1323) : const Color(0xFFF5F6F8);
    final surfaceColor = isDark ? const Color(0xFF0F1323) : Colors.white;
    final primaryColor = const Color(0xFF607AFB);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A); // slate-900
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569); // slate-300 / slate-600
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9); // slate-800 / slate-100

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
          ),
          title: Text(
            'Pháp lý & Bảo mật',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: surfaceColor,
              child: TabBar(
                labelColor: primaryColor,
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Quyền riêng tư'),
                  Tab(text: 'Điều khoản'),
                ],
              ),
            ),
          ),
          bottomOpacity: 1,
          shape: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrivacyTab(textColor, bodyColor, primaryColor),
            _buildTermsTab(textColor, bodyColor, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(Color titleColor, Color bodyColor, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chính sách quyền riêng tư',
            style: TextStyle(color: titleColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Chào mừng bạn đến với ChiTieuPlus. Chúng tôi cam kết bảo vệ thông tin cá nhân và quyền riêng tư của bạn. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo mật dữ liệu của bạn khi sử dụng ứng dụng quản lý tài chính của chúng tôi.',
            style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildSection('1. Thu thập thông tin', 'Chúng tôi thu thập thông tin bạn cung cấp trực tiếp cho chúng tôi, chẳng hạn như khi bạn tạo tài khoản, cập nhật hồ sơ hoặc ghi lại các giao dịch tài chính. Thông tin này có thể bao gồm tên, địa chỉ email, và dữ liệu chi tiêu hàng ngày.', primaryColor, bodyColor),
          _buildSection('2. Sử dụng thông tin', 'Dữ liệu của bạn được sử dụng để cung cấp các báo cáo phân tích chi tiêu chính xác, cá nhân hóa trải nghiệm người dùng và cải thiện tính năng thông minh của ứng dụng ChiTieuPlus. Chúng tôi không bao giờ bán dữ liệu cá nhân của bạn cho bên thứ ba.', primaryColor, bodyColor),
          _buildSection('3. Bảo mật dữ liệu', 'Chúng tôi áp dụng các biện pháp bảo mật kỹ thuật và tổ chức nghiêm ngặt để bảo vệ dữ liệu của bạn khỏi sự truy cập trái phép, mất mát hoặc thay đổi. Mọi thông tin giao dịch đều được mã hóa theo tiêu chuẩn ngân hàng.', primaryColor, bodyColor),
          _buildSection('4. Quyền của người dùng', 'Bạn có quyền truy cập, chỉnh sửa hoặc yêu cầu xóa dữ liệu cá nhân của mình bất kỳ lúc nào thông qua phần cài đặt trong ứng dụng hoặc liên hệ với bộ phận hỗ trợ của chúng tôi.', primaryColor, bodyColor),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Cập nhật lần cuối: 1 tháng 3, 2026. Bằng cách tiếp tục sử dụng ứng dụng, bạn đồng ý với các điều khoản trong chính sách này.',
              style: TextStyle(
                color: bodyColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTermsTab(Color titleColor, Color bodyColor, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điều khoản sử dụng',
            style: TextStyle(color: titleColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Vui lòng đọc kỹ các điều khoản sử dụng này trước khi sử dụng ứng dụng ChiTieuPlus. Việc truy cập và sử dụng ứng dụng của bạn đồng nghĩa với việc bạn chấp nhận và tuân thủ các điều khoản này.',
            style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildSection('1. Chấp nhận điều khoản', 'Bằng cách tạo tài khoản hoặc sử dụng bất kỳ phần nào của ứng dụng, bạn xác nhận rằng bạn đã đọc, hiểu và đồng ý bị ràng buộc bởi các điều khoản và điều kiện này.', primaryColor, bodyColor),
          _buildSection('2. Tài khoản người dùng', 'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và mọi hoạt động diễn ra trong tài khoản của mình. Bạn phải cung cấp thông tin chính xác và cập nhật khi đăng ký.', primaryColor, bodyColor),
          _buildSection('3. Quyền sở hữu trí tuệ', 'Mọi nội dung, tính năng và chức năng của ứng dụng (bao gồm văn bản, phần mềm, mã nguồn, biểu tượng) đều thuộc sở hữu của ChiTieuPlus và được bảo vệ bởi luật sở hữu trí tuệ quốc tế.', primaryColor, bodyColor),
          _buildSection('4. Giới hạn trách nhiệm', 'ChiTieuPlus cung cấp công cụ quản lý tài chính mang tính chất tham khảo. Chúng tôi không chịu trách nhiệm cho bất kỳ tổn thất tài chính nào phát sinh từ việc sử dụng ứng dụng hoặc sự phụ thuộc vào các báo cáo tự động.', primaryColor, bodyColor),
          _buildSection('5. Thay đổi điều khoản', 'Chúng tôi có quyền sửa đổi các điều khoản này bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng. Tiếp tục sử dụng ứng dụng đồng nghĩa với việc bạn chấp nhận các thay đổi đó.', primaryColor, bodyColor),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Cập nhật lần cuối: 1 tháng 3, 2026. Nếu có bất kỳ câu hỏi nào, vui lòng liên hệ bộ phận hỗ trợ khách hàng.',
              style: TextStyle(
                color: bodyColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, Color primaryColor, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: bodyColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
