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

    final bgColor = themeProvider.backgroundColor;
    final surfaceColor = themeProvider.secondaryColor;
    final primaryColor = const Color(0xFFEC5B13); // Tông cam chủ đạo
    final textColor = themeProvider.foregroundColor;
    final bodyColor = themeProvider.foregroundColor.withValues(alpha: 0.8);
    final borderColor = themeProvider.borderColor;

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
                unselectedLabelColor: textColor.withValues(alpha: 0.5),
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Quyền riêng tư'),
                  Tab(text: 'Điều khoản'),
                ],
              ),
            ),
          ),
          bottomOpacity: 1,
          shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
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

  Widget _buildPrivacyTab(
    Color titleColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHÍNH SÁCH QUYỀN RIÊNG TƯ',
            style: TextStyle(
              color: titleColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chào mừng bạn đến với ChiTieuPlus. Chúng tôi cam kết bảo vệ sự riêng tư và bảo mật dữ liệu cho thông tin tài chính của bạn.',
            style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildSection(
            '1. LIÊN HỆ VỚI CHÚNG TÔI',
            'Nếu bạn có câu hỏi về bảo vệ dữ liệu hoặc yêu cầu giải quyết các vấn đề liên quan đến dữ liệu cá nhân, vui lòng liên hệ:\nTên đơn vị kiểm soát: ChiTieuPlus Team\nEmail: privacy@chitieuplus.com',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '2. DỮ LIỆU CHÚNG TÔI THU THẬP',
            '1) Dữ liệu bạn cung cấp cho chúng tôi:\n- Thông tin liên hệ (như tên, email).\n- Thông tin hồ sơ (chẳng hạn như ảnh đại diện).\n- Dữ liệu giao dịch chi tiêu, hạn mức ngân sách và các ghi chú bạn tự nguyện nhập.\n2) Dữ liệu thu thập tự động:\n- Dữ liệu về tài khoản, ID thiết bị, hệ điều hành.\n- Tần suất sử dụng app và cấu trúc menu để tối ưu trải nghiệm.\n3) Dữ liệu từ đối tác:\n- Dữ liệu nhận được khi bạn liên kết với Firebase Auth (Google Sign-In).',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '3. TẠI SAO CHÚNG TÔI THU THẬP DỮ LIỆU CỦA BẠN?',
            '1) Để ứng dụng hoạt động:\n- Khởi tạo tài khoản, đồng bộ ví.\n2) Để cá nhân hóa dịch vụ:\n- Cung cấp tính năng trợ lý ảo (AI) để phân tích chi tiêu cá nhân.\n3) Để phân tích, hiển thị báo cáo:\n- Lập các đồ thị, báo cáo phân bổ và xu hướng.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '4. AI CÓ THỂ XEM DỮ LIỆU?',
            'Hoạt động phân tích chi tiêu cá nhân dựa trên tài khoản của bạn. Tuy nhiên, toàn bộ dữ liệu giao dịch được chạy độc lập bảo mật và không bị chia sẻ cho bất kì mục đích quảng cáo bên ngoài nào.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '5. BẢO VỆ VÀ LƯU GIỮ DỮ LIỆU',
            'Chúng tôi mã hóa mật khẩu và các thông tin định danh. Mọi gói tin truyền tải lên cơ sở dữ liệu đều tuân thủ các quy tắc bảo mật. Dữ liệu sẽ được lưu giữ miễn là tài khoản ChiTieuPlus của bạn còn hiệu lực.\nBạn có quyền nhấn nút "Xoá toàn bộ dữ liệu" để loại bỏ mọi vết tích trên Cloud.',
            primaryColor,
            bodyColor,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Cập nhật lần cuối: 21 tháng 3, 2026. Bằng cách tiếp tục sử dụng ứng dụng, bạn đồng ý với các nội dung trên.',
              style: TextStyle(
                color: bodyColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
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
            'ĐIỀU KHOẢN SỬ DỤNG GIAO DỊCH',
            style: TextStyle(
              color: titleColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Vui lòng đọc kỹ các điều khoản sử dụng này trước khi sử dụng ứng dụng ChiTieuPlus. Việc truy cập và sử dụng ứng dụng của bạn đồng nghĩa với việc bạn chấp nhận các điều khoản này.',
            style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildSection(
            '1. TÀI KHOẢN CỦA BẠN',
            '1) Độ tuổi: Để tạo tài khoản ChiTieuPlus, bạn phải đáp ứng độ tuổi tối thiểu theo quy định. Nếu bạn dưới độ tuổi quy định, phụ huynh hoặc người giám hộ hợp pháp của bạn phải đọc và đồng ý với các Điều Khoản này.\n2) Tạo tài khoản: Bạn có quyền sử dụng email hoặc thông tin bên thứ ba để đăng ký. Bạn chịu trách nhiệm hoàn toàn đối với việc bảo mật thông tin đăng nhập.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '2. QUYỀN SỞ HỮU TRÍ TUỆ',
            'Toàn bộ mã nguồn, thiết kế UI/UX, đồ họa và thuật toán AI phân tích chi tiêu đều thuộc bản quyền bảo hộ của hệ thống ChiTieuPlus. Nghiêm cấm mọi hành vi sao chép, làm giả, hoặc phát tán trái phép.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '3. NGUYÊN TẮC HÀNH VI NGƯỜI DÙNG',
            'Bạn bị nghiêm cấm tham gia trực tiếp hoặc gián tiếp vào các hoạt động sau:\na) Lưu trữ ghi chú giao dịch mang tính vi phạm pháp luật hoặc bạo lực.\nb) Khai thác lỗi (bugs), lỗ hổng hệ thống để làm sai lệch biểu đồ báo cáo tài chính.\nc) Cố gắng vượt qua, vô hiệu hóa các biện pháp bảo mật trên Database.\nd) Gửi thư rác (spam) gây tắc nghẽn hệ thống phản hồi của chúng tôi.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '4. GIỚI HẠN VÀ CHẤM DỨT',
            'Trong trường hợp phát hiện vi phạm Mục 3, chúng tôi có toàn quyền (mà không cần báo trước) để:\n- Sửa đổi hoặc tạm ngưng các dịch vụ (như tính năng AI).\n- Chấm dứt và xóa vĩnh viễn tài khoản ChiTieuPlus của bạn trên hệ thống Cloud.',
            primaryColor,
            bodyColor,
          ),
          _buildSection(
            '5. TỪ CHỐI BẢO ĐẢM',
            'Ứng dụng được cung cấp "NGUYÊN TRẠNG". Do tính chất của thuật toán, Trợ lý AI và các biểu đồ phân tích ngân sách chỉ mang tính chất dự báo và tham khảo. Chúng tôi không chịu trách nhiệm bồi thường cho các quyết định đầu tư, tài chính sai lầm của bạn.',
            primaryColor,
            bodyColor,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Cập nhật lần cuối: 21 tháng 3, 2026. Nếu có bất kỳ câu hỏi nào, vui lòng liên hệ bộ phận hỗ trợ thông qua email.',
              style: TextStyle(
                color: bodyColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    Color primaryColor,
    Color bodyColor,
  ) {
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
            style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
