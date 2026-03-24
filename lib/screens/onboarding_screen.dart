import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/screens/login_screen.dart';
import 'package:chitieu_plus/screens/terms_and_privacy_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (_nameController.text.trim().isNotEmpty) {
        context.read<UserProvider>().setName(_nameController.text.trim());
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(
          milliseconds: 300,
        ), // duration: Định lượng thời gian thi hành khung hình trượt
        curve: Curves
            .easeIn, // curve: Thay đổi tùy chỉnh cảm giác tốc độ lướt trượt trang (có gia tốc)
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment
                .topCenter, // begin: Điểm neo để phát tán mảng chuyển từ dải màu vùng đỉnh
            end: Alignment
                .bottomCenter, // end: Điểm kết ranh sắc tố tại dải dưới cùng
            colors: [
              // colors: Tập hợp tông sắc gradient kết dính tuần tự
              Color(0xFF022C4F),
              Color(0xFF02467D),
              Color(0xFF0174D7),
            ],
            stops: [
              0.0,
              0.4,
              1.0,
            ], // stops: Các mức ngắt nhịp rải rác thang phân số vị trí %
          ),
        ),
        child: SafeArea(
          // SafeArea: Widget bảo đảm nội dung nằm gọn vóc vùng không lẹm viền tai thỏ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // crossAxisAlignment: Nới dãn hết cỡ chiều hoành
            children: [
              // Nút quay lại
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 16.0,
                ), // padding: Xô đẩy nhẹ khỏi vách trần bên trái và trên
                child: Align(
                  alignment: Alignment
                      .centerLeft, // alignment: Ép góc tọa lạc của đối tượng con nhích lệch sang trái
                  child: Visibility(
                    visible: _currentPage > 0,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ), // icon: Truyền tham biến hình vẽ kí hiệu nút bấm
                      onPressed: () {
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          // Xử lý đi ngược về Splash hoặc bỏ qua
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Dấu chấm chỉ báo trang (Indicators)
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // mainAxisAlignment: Chụm dồn thẳng hàng vô trọng tâm giữa dải lưới ngang
                children: List.generate(3, (index) => _buildDot(index: index)),
              ),

              const SizedBox(height: 48),

              // Khu vực nội dung các trang Onboarding có thể vuốt được
              Expanded(
                // Expanded: Nong trương giãn nở cực độ nhồi nhét khuân chiếm toàn bộ không gian trống còn dư
                child: PageView(
                  controller:
                      _pageController, // controller: Kết nối dây chuyền quản trị thông tin vị trí các trang hiện hữu
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage =
                          page; // setState: Xác nhận lại trạng thái để load giao tiếp màn hình sau biến cố thay đổi sự kiện
                    });
                  },
                  children: [_buildPage1(), _buildPage2(), _buildPage3()],
                ),
              ),

              // Cụm các nút bấm ở dưới đáy
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ), // padding: Cắt lấn chiếm hai khoảng bề ngang đồng đều
                child: Column(
                  children: [
                    // Nút Tiếp tục / Bắt đầu ngay
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFF05D15,
                        ), // backgroundColor: Làm thẫm lớp sơn nền khung nút nhấn
                        minimumSize: const Size(
                          double.infinity,
                          56,
                        ), // minimumSize: Ràng buộc kích đo khống chế kích cỡ sàn nền nhỏ nhất có thể
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // borderRadius: Quyết định giới hạn khum tròn các bờ bao gốc tư
                        ),
                        elevation:
                            0, // elevation: Loại bỏ chiều cao lơ lửng, tức chèn bẹp mảng nền mờ đổ tà bóng
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // mainAxisAlignment: Gò ép bó buộc nén cụm chính nằm phơi mình ở vị trí ngay ốc giữa thanh trục
                        children: [
                          Text(
                            _currentPage == 2 ? 'Bắt đầu ngay' : 'Tiếp tục',
                            style: const TextStyle(
                              fontSize:
                                  16, // fontSize: Thay dạng thay thế cỡ phông nét chũ
                              fontWeight: FontWeight
                                  .w700, // fontWeight: Mức chỉ định cho nét khắc gạch của văn tự mang hơi hướng rắn chắc
                              color: Colors.white,
                            ),
                          ),
                          if (_currentPage < 2) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút text "BỎ QUA"
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'BỎ QUA',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.8,
                          ), // color: Cường độ hòa màu tinh xuyết điệm lên văn tự
                          fontWeight: FontWeight
                              .bold, // fontWeight: Định danh trạng thái bản sắc cho nét nét chữ mạnh chọi
                          letterSpacing:
                              1.5, // letterSpacing: Gạt dàn rộng đều nhịp phân luồng giãn khoảng không cho từng từ
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dòng thông báo điều khoản
                    RichText(
                      textAlign: TextAlign
                          .center, // textAlign: Buộc kéo thả quy củ trung hòa đoạn văn đa lớp nằm ngả giữa
                      text: TextSpan(
                        style: TextStyle(
                          fontSize:
                              12, // fontSize: Nhỏ nhặt thu nhỏ biểu tượng kí tự làm chú rễ phụ hoạ
                          color: Colors.white.withValues(
                            alpha: 0.5,
                          ), // color: Rải sắc hòa quyện yếu rờ chìm lịm lẩn sâu vào phong màn
                          height:
                              1.5, // height: Đôn nâng tầng xen lồng múa chênh lệch độ cao cho luồng đoạn dãn dài
                        ),
                        children: [
                          const TextSpan(
                            text: 'Bằng việc tiếp tục, bạn chấp thuận với ',
                          ),
                          TextSpan(
                            text: 'chính sách điều\nkhoản',
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.8,
                              ), // color: Nổi bật đoạn liên kết bằng sắc tố tươi rạng
                              decoration: TextDecoration
                                  .underline, // decoration: Kẻ vẽ hằn in lằng chỉ gạch đít ở vùng thềm chân trang của nội dung
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsAndPrivacyScreen(
                                          initialTabIndex: 1,
                                        ), // 1 is Terms
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' và '),
                          TextSpan(
                            text: 'quyền riêng tư',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsAndPrivacyScreen(
                                          initialTabIndex: 0,
                                        ), // 0 is Privacy
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' của chúng tôi.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tiện ích tạo dấu chấm trang chỉ mức độ tiến trình hiện hành
  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ), // duration: Định mốc phân lượng ấn định thời hóa của diễn tiến hoạt họa
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ), // margin: Trải đệm khoảng nghỉ dồn hông dọc chiều ngang
      height: 6,
      width: _currentPage == index
          ? 24
          : 6, // width: Tăng bành trướng vóc thân chiều rộng lúc chạm bước đánh thức
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFFF05D15)
            : Colors.white.withValues(
                alpha: 0.3,
              ), // color: Thổi hồn sắc cam đậm lúc làm chỉ huy hay lướt bóng xám khi thẩn thờ ngủ yên
        borderRadius: BorderRadius.circular(
          3,
        ), // borderRadius: Tiện gọt dũa nếp cạnh trọn vành vạch
      ),
    );
  }

  // --- TRANG 1: Tính năng chung ---
  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Thẻ nổi bật chào mừng
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 48,
              ), // padding: Nhét nén phình trướng ruột trong bao vây mọi mặt
              decoration: BoxDecoration(
                color: const Color(0xFF034177).withValues(
                  alpha: 0.6,
                ), // color: Lót màn nhung nhuốm men xanh đại dương sâu rờn trong vắt
                borderRadius: BorderRadius.circular(
                  40,
                ), // borderRadius: Vát gọt bốn vế vuông hình trụ thon
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ), // border: Trang sức mài viền màng sợi sáng lóe phản chiếu dịu êm
                  width: 1, // width: Khống chế nét mảnh khảnh viền kẹp dao động
                ),
              ),
              child: Column(
                children: [
                  // Logo Ví App
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF05D15,
                      ), // color: Phết nện khối chất mảng cam son nhiệt huyết mây vương
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // borderRadius: Giũa tróc trơn mướt những nanh sắt lượn rìa của khuôn khung
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment
                            .center, // alignment: Quy chắt chốt tâm đồng nhất giam hãm ngưng tụ các điểm ảnh xê dịch
                        children: [
                          Container(
                            width: 48,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // borderRadius: Mài giũa tròn trịa bờ cạnh nắp bóp
                            ),
                          ),
                          Positioned(
                            right:
                                -1, // right: Vươn ló lọt ranh biên giáp ranh bên thềm sườn phải chệnh chếch
                            child: Container(
                              width: 14,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF05D15),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                    6,
                                  ), // borderRadius.only: Gọt nén tỉa hớt khéo léo bo tròn ở riêng ranh chóp và gác vách mâm mép
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape
                                        .circle, // shape: Nấu nhào thành điệu viên mãn tròn vo nốt khối
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            right: 14,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF05D15,
                                ).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Chào mừng đến\nvới\nChiTieuPlus',
                    textAlign: TextAlign
                        .center, // textAlign: Gom quy về trọng điểm chính ngự uy dũng giũa sảnh diện
                    style: TextStyle(
                      fontSize:
                          28, // fontSize: Uy thế phóng chiếu vóc đại cho diện tích văn mảnh
                      fontWeight: FontWeight
                          .bold, // fontWeight: Trĩu đầm nét bút vững móng in chìm nét bám
                      color: Colors.white,
                      height:
                          1.4, // height: Ép nhịp dãn trống thở luồn dọc tầng cấp các con chữ rớt dòng
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Các dòng tính năng ứng dụng
            _buildFeatureItem(
              Icons.smart_toy_rounded,
              'Quản lý chi tiêu thông minh với AI',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.bar_chart_rounded,
              'Biểu đồ phân tích trực quan',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.cloud_sync_rounded,
              'Sao lưu dữ liệu thời gian thực',
            ),
          ],
        ),
      ),
    );
  }

  // Tùy biến thành phần widget tái sử dụng cho dòng tính năng
  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF5ADBD0),
          size: 28,
        ), // color: Nhuộm đẫm sắc thái hồ hải lam lấp lánh biểu hạt
        const SizedBox(width: 16),
        Expanded(
          // Expanded: Nong vãn bung phủ rợp trọn tàng che những lề khuất còn lưa cạn cợt ngang dọc
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight
                  .w400, // fontWeight: Tu vóc dáng mềm lướt uyển mỏng tang phiêu lưu dòng chữ
            ),
          ),
        ),
      ],
    );
  }

  // --- TRANG 2: Điền Tên người dùng ---
  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .center, // crossAxisAlignment: Dằn nắn gò bó chỉnh hướng phỏng tụ về một điểm hội ngộ trục dọc
          children: [
            const Text(
              'Bạn tên là gì?',
              style: TextStyle(
                fontSize:
                    32, // fontSize: Uy trấn lộng diện quy mô sảnh bề vóc mặt chữ
                fontWeight: FontWeight
                    .bold, // fontWeight: Ép khắc dày chéo nén đậm sâu bóc vóc cự trụ chũm
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chào mừng đến với ChiTieuPlus. Hãy\ncho chúng tôi biết tên của bạn để bắt\nđầu hành trình quản lý tài chính.',
              textAlign: TextAlign
                  .center, // textAlign: Canh bằng ngay ngắn đồng lều nhượng tụ họp gộp vào ngự tâm
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(
                  alpha: 0.85,
                ), // color: Giảm độ xức chói lòe sáng lướt rợp độ câm thâm mờ
                height:
                    1.5, // height: Mở toang dạt dỏng rộng khung chiều hoành nhô cho khoảng giãn văn phong
              ),
            ),
            const SizedBox(height: 48),

            // Form nhập dữ liệu văn bản
            Align(
              alignment: Alignment
                  .centerLeft, // alignment: Xê xuôi dồn xô vách lề vóc dạt thềm về phía đằng tây
              child: Text(
                'Họ và tên của bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight
                      .w500, // fontWeight: Chuẩn nhịp cân bằng không quá mập đậm nẻo trung hòa
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF034177).withValues(
                  alpha: 0.6,
                ), // color: Đổ nền khảm lấp ráo ranh khuông màu dạt hố thụt
                borderRadius: BorderRadius.circular(
                  16,
                ), // borderRadius: Vát khum đẽo vuốt nếp gò tít thềm các gốc góc
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.2,
                  ), // border: Viền gáy kẻ rãnh chuốt đường cày nông sâu ôm ngoài quánh viền
                ),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ), // style: Màu chữ hiển thị khi gõ phím trực tiếp
                decoration: InputDecoration(
                  hintText: 'Nhập tên đầy đủ...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.4,
                    ), // hintStyle: Kẻ sắc chì câm gượng chữ điềm điệt mơ hồ trong hố hoang vắng chờ nhập
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Colors
                        .white54, // prefixIcon: Thêm chèn dấu ấn hình tượng móc phụ đạo biểu thị dấn nhứ đầu khuyên
                  ),
                  border: InputBorder
                      .none, // border: Ruồng bỏ tháo gỡ dấn mác viền bọc thô sơ có gốc tích mặc khởi sẵn sinh
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ), // contentPadding: Thư dãn ráng khoáng trống trượt không làm ngột tắc khoảng chèn trong ngòi biên bọc gông
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khai báo state lưu trữ biến Tiền tệ đã chọn, mặc định là VND
  String _selectedCurrency = 'VND';

  // --- TRANG 3: Chọn Tiền tệ ứng dụng ---
  Widget _buildPage3() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Chọn loại tiền tệ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn tiền tệ chính để theo dõi các khoản\nchi tiêu của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Danh sách các mục thả nổi lặp lại
            _buildCurrencyItem('Vietnamese Dong (VND)', 'đ - Việt Nam', 'VND'),
            const SizedBox(height: 16),
            _buildCurrencyItem('US Dollar (USD)', '\$ - United States', 'USD'),
            const SizedBox(height: 16),
            _buildCurrencyItem('Euro (EUR)', '€ - European Union', 'EUR'),
            const SizedBox(height: 16),
            _buildCurrencyItem(
              'British Pound (GBP)',
              '£ - United Kingdom',
              'GBP',
            ),
          ],
        ),
      ),
    );
  }

  // Khung định dạng tùy chỉnh đơn vị tiền tệ tái cấu trúc
  Widget _buildCurrencyItem(
    String title,
    String subtitle,
    String currencyCode,
  ) {
    bool isSelected =
        _selectedCurrency ==
        currencyCode; // isSelected: Truy xuất tra cứu tính năng phân mảng đúng sai dò coi sự việc trúng khớp chăng
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCurrency =
              currencyCode; // setState: Áp luân chuyển thao tác xí phần xoay trục chuyển nhịp kích vận cõi cơ cấu
        });
        context.read<UserProvider>().setCurrency(currencyCode);
      },
      child: Container(
        padding: const EdgeInsets.all(
          20,
        ), // padding: Cơi nới độ bành lan mâm nệm đệm êm quanh viễn lõi trong cùm hãm
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF034177).withValues(
                  alpha: 0.8,
                ) // color: Hô biến phơi thẫm mảng đục trong mấp mô chuyển dạt theo tín hiệu khơi bấm
              : const Color(0xFF034177).withValues(
                  alpha: 0.3,
                ), // Trạng thái lặng câm mơ màng xám nhạt lu ẩn
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(
                    0xFF5ADBD0,
                  ) // border: Chiếu roi rọi khảm quang phổ lam lục bừng thêu vách bọc ngoài nhú
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected
                ? 1.5
                : 1, // width: Phác thả phân thanh nét gằn rắn đục nếu đúng đích nhắm chọn
          ),
        ),
        child: Row(
          children: [
            Expanded(
              // Expanded: Kéo choàng gánh hết sải mỏn dư quang rạch khoảng vắng ôm trọn cự ngang sườn
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // crossAxisAlignment: Nêm xô đẩy dàn phẳng tấu lên phím dóc trái vuốt gờ
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight
                          .bold, // fontWeight: Chịu cự trọng nét in phơi chắc thẫm nề cội ghim tạc cốt gân
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(
                        alpha: 0.6,
                      ), // color: Thâm hạ tông dòng diễn giải nhòe bóng giảm lóa cướp điểm nhìn
                    ),
                  ),
                ],
              ),
            ),

            // Xây dựng hình tròn check-box đi kèm màu sắc động
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape
                    .circle, // shape: Điêu khắc gọt vỏ khoét nang túi hình cầu tròn lăn
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5ADBD0)
                      : Colors.white.withValues(
                          alpha: 0.4,
                        ), // border: Vẽ chỉ thêu mài cung rãnh ngòi bọc đường quây viền ngoại bao rào
                  width: 2, // width: Đắp vuốt đục dày thanh chỉ khứa nông sâu
                ),
                color: isSelected
                    ? const Color(0xFF5ADBD0)
                    : Colors
                          .transparent, // color: Thả nện khảm lõi nòng rốn dồn dạt sắc xanh hay trong vắt vô màu
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.white,
                      ), // icon: Quẳng chấm điểm huyệt tạc nhân khối tâm xuy trắng tinh ngạo nghễ trĩu mình
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
