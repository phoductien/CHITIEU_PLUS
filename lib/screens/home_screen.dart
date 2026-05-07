import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/screens/notification_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chitieu_plus/screens/ocr_scan_screen.dart';
import 'package:chitieu_plus/widgets/main_drawer.dart';
import 'package:chitieu_plus/widgets/mini_ai_chat_widget.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';
import 'package:chitieu_plus/services/ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


import 'package:chitieu_plus/screens/tabs/home_tab.dart';
import 'package:chitieu_plus/screens/tabs/transaction_tab.dart';
import 'package:chitieu_plus/screens/tabs/budget_tab.dart';
import 'package:chitieu_plus/screens/tabs/report_tab.dart';

class HomeScreen extends StatefulWidget {
  final String? welcomeMessage;
  const HomeScreen({super.key, this.welcomeMessage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAiOverlayOpen = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _getAiGreeting(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Chào bạn! Tôi có thể giúp gì cho\nngân sách của bạn hôm nay?';
      case 1:
        return 'Giao dịch hôm nay thế nào?\nĐể tôi tóm tắt giúp nhé!';
      case 2:
        return 'Lên kế hoạch thông minh?\nĐể tôi hỗ trợ bạn!';
      case 3:
        return 'Phân tích chi tiêu của bạn?\nTôi luôn sẵn sàng hỗ trợ!';
      default:
        return 'Chào bạn! Tôi có thể giúp gì cho bạn?';
    }
  }

  late StreamSubscription<NotificationModel> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null);

    // Restore session state
    final session = context.read<AppSessionProvider>();
    _currentIndex = session.homeTabIndex;
    session.setLastRoute('home');

    _pageController = PageController(initialPage: _currentIndex);

    // Listen for new notifications
    final notificationProvider = context.read<NotificationProvider>();
    _notificationSubscription = notificationProvider.onNewNotification.listen((
      notification,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification.color.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            notification.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Xem',
                        style: TextStyle(color: Color(0xFFFF6D00)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });

    if (widget.welcomeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.welcomeMessage!),
              backgroundColor: const Color(0xFFFF6D00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _showExitDialog() async {
    final themeProvider = context.read<ThemeProvider>();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: themeProvider.secondaryColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: themeProvider.borderColor),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Color(0xFFFF6D00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thoát ứng dụng',
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn đóng ứng dụng ChiTieuPlus và kết thúc phiên làm việc không?',
              style: TextStyle(
                color: themeProvider.foregroundColor.withOpacity(0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: themeProvider.foregroundColor.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thoát',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Hàm phân tích giọng nói ngoại tuyến (Offline) khi không có mạng hoặc lỗi AI.
  // Thêm xử lý thời gian: Mặc định lấy thời gian hiện tại, nếu phát hiện từ khóa "hôm qua" hoặc "hôm kia" thì trừ ngày tương ứng.
  Map<String, dynamic> _parseSpeechTextOffline(String text) {
    final lower = text.toLowerCase();
    int amount = 0;
    
    final kRegExp = RegExp(r'(\d+)\s*k');
    final trieuRegExp = RegExp(r'(\d+)\s*triệu');
    final matchK = kRegExp.firstMatch(lower);
    final matchTrieu = trieuRegExp.firstMatch(lower);
    
    if (matchK != null) {
      amount = int.parse(matchK.group(1)!) * 1000;
    } else if (matchTrieu != null) {
      amount = int.parse(matchTrieu.group(1)!) * 1000000;
    } else {
      final digitsRegExp = RegExp(r'\d+[\d\.,]*');
      final matchDigits = digitsRegExp.allMatches(lower);
      if (matchDigits.isNotEmpty) {
        final numStr = matchDigits.first.group(0)!.replaceAll('.', '').replaceAll(',', '');
        amount = int.tryParse(numStr) ?? 0;
      }
    }

    String category = 'Khác';
    if (lower.contains('ăn') || lower.contains('phở') || lower.contains('cơm') || lower.contains('uống') || lower.contains('cafe')) {
      category = 'Ăn uống';
    } else if (lower.contains('xe') || lower.contains('xăng') || lower.contains('taxi') || lower.contains('bus') || lower.contains('vé')) {
      category = 'Di chuyển';
    } else if (lower.contains('siêu thị') || lower.contains('mua sắm') || lower.contains('quần áo') || lower.contains('mỹ phẩm')) {
      category = 'Mua sắm';
    } else if (lower.contains('điện')) {
      category = 'Tiền điện';
    } else if (lower.contains('nước')) {
      category = 'Tiền nước';
    } else if (lower.contains('gas') || lower.contains('ga')) {
      category = 'Tiền Gas';
    } else if (lower.contains('điện thoại') || lower.contains('card') || lower.contains('nạp đt')) {
      category = 'Nạp điện thoại';
    } else if (lower.contains('học') || lower.contains('trường') || lower.contains('sách')) {
      category = 'Học phí';
    } else if (lower.contains('bảo hiểm')) {
      category = 'Bảo hiểm';
    } else if (lower.contains('chơi') || lower.contains('game') || lower.contains('phim') || lower.contains('hát')) {
      category = 'Giải trí';
    } else if (lower.contains('khám') || lower.contains('thuốc') || lower.contains('bệnh') || lower.contains('viện')) {
      category = 'Sức khỏe';
    } else if (lower.contains('nhà') || lower.contains('phòng') || lower.contains('thuê')) {
      category = 'Nhà cửa';
    }

    // Thiết lập ngày giờ hiện tại
    DateTime date = DateTime.now();
    if (lower.contains('hôm qua')) {
      date = date.subtract(const Duration(days: 1));
    } else if (lower.contains('hôm kia')) {
      date = date.subtract(const Duration(days: 2));
    }

    return {
      'amount': amount,
      'category': category,
      'title': text,
      'note': 'Ghi bằng giọng nói ngoại tuyến',
      'date': date.toIso8601String(), // Lưu đầy đủ ngày giờ
    };
  }

  void _showVoiceRecordingDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final textController = TextEditingController();
    bool isRecording = false;
    bool isProcessing = false;
    Map<String, dynamic>? parsedTransaction;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Hàm mô phỏng giọng nói cho mục đích chạy thử nhanh
            void simulateSpeech(String sampleText) {
              setModalState(() {
                isRecording = true;
                textController.clear();
                parsedTransaction = null;
              });
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  setModalState(() {
                    isRecording = false;
                    textController.text = sampleText;
                  });
                }
              });
            }

            // Hàm kích hoạt ghi âm và nhận diện giọng nói thực tế từ micro
            Future<void> toggleListening() async {
              if (isRecording) {
                // Nếu đang ghi âm, nhấn lần nữa sẽ dừng ghi âm
                await _speech.stop();
                setModalState(() {
                  isRecording = false;
                });
                return;
              }

              // Kiểm tra quyền truy cập Microphone bằng permission_handler
              var status = await Permission.microphone.status;
              if (!status.isGranted) {
                status = await Permission.microphone.request();
              }

              // Nếu người dùng không cấp quyền truy cập, hiển thị thông báo lỗi bằng tiếng Việt
              if (!status.isGranted) {
                if (context.mounted) {
                  final lang = context.read<LanguageProvider>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.translate('ai_chat_mic_error') ?? 'Không thể truy cập Micro. Vui lòng cấp quyền.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }

              // Khởi tạo thư viện nhận diện giọng nói speech_to_text
              bool available = await _speech.initialize(
                onError: (error) {
                  debugPrint('Lỗi nhận diện giọng nói: $error');
                  setModalState(() {
                    isRecording = false;
                  });
                },
                onStatus: (status) {
                  debugPrint('Trạng thái nhận diện: $status');
                  if (status == 'done' || status == 'notListening') {
                    setModalState(() {
                      isRecording = false;
                    });
                  }
                },
              );

              if (available) {
                setModalState(() {
                  isRecording = true;
                  parsedTransaction = null;
                });
                // Bắt đầu lắng nghe với ngôn ngữ tiếng Việt (vi_VN) và cập nhật nội dung văn bản theo thời gian thực
                await _speech.listen(
                  localeId: 'vi_VN',
                  onResult: (result) {
                    setModalState(() {
                      textController.text = result.recognizedWords;
                      // Giữ con trỏ nhập liệu ở cuối chuỗi văn bản
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textController.text.length),
                      );
                    });
                  },
                );
              } else {
                // Nếu không thể khởi tạo bộ nhận diện, thông báo lỗi cho người dùng
                if (context.mounted) {
                  final lang = context.read<LanguageProvider>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.translate('ai_chat_mic_error') ?? 'Không thể khởi động bộ nhận diện giọng nói.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }

            // Hàm phân tích giọng nói sử dụng AI (Gemini) để trích xuất thông tin giao dịch bao gồm ngày, tháng, giờ.
            Future<void> performAiParsing() async {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              setModalState(() {
                isProcessing = true;
                parsedTransaction = null;
              });

              try {
                final aiService = AiService();
                final now = DateTime.now();
                final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
                
                final prompt = 'Hãy phân tích câu nói ghi chép chi tiêu sau và trả về DUY NHẤT một chuỗi JSON hợp lệ (không kèm markdown, không giải thích gì thêm, không có dấu ```json) chứa thông tin giao dịch.\n'
                    'Ngày giờ hiện tại làm mốc tham chiếu: $nowStr\n\n'
                    'Yêu cầu đặc biệt về THỜI GIAN:\n'
                    '1. Hãy phân tích từ câu nói chi tiết về Ngày, Tháng, Giờ nếu người dùng có đề cập đến (ví dụ: "hôm qua", "sáng nay lúc 8h", "ngày 5 tháng 5", "hồi nãy", "lúc 10h", "tháng trước", "tối qua",...). '
                    'Nếu người dùng có nhắc đến các mốc thời gian này, hãy tính toán so với mốc thời gian hiện tại ($nowStr) để đưa ra giá trị chính xác tuyệt đối.\n'
                    '2. Nếu câu nói KHÔNG đề cập đến ngày hay giờ cụ thể nào, hãy mặc định lấy ngày giờ hiện tại là "$nowStr".\n\n'
                    'Cấu trúc JSON yêu cầu:\n'
                    '{\n'
                    '  "amount": <số tiền nguyên, ví dụ: 45000>,\n'
                    '  "category": "<danh mục phù hợp nhất trong các danh mục sau: Ăn uống, Mua sắm, Học phí, Bảo hiểm, Tiền điện, Tiền nước, Tiền Gas, Nạp điện thoại, Di chuyển, Giải trí, Sức khỏe, Nhà cửa, Khác>",\n'
                    '  "title": "<mô tả ngắn gọn về giao dịch, ví dụ: Ăn trưa phở bò>",\n'
                    '  "note": "<ghi chú chi tiết>",\n'
                    '  "date": "<ngày giờ giao dịch theo định dạng ISO 8601 YYYY-MM-DDTHH:mm:ss>"\n'
                    '}\n\n'
                    'Câu nói của người dùng: "$text"';

                final response = await aiService.sendMessage(prompt);
                Map<String, dynamic> parsedData;
                try {
                  String cleanRes = response.trim();
                  if (cleanRes.startsWith("```")) {
                    cleanRes = cleanRes.replaceAll(RegExp(r'^```json\s*|```$'), '');
                  }
                  cleanRes = cleanRes.trim();
                  final decoded = jsonDecode(cleanRes);
                  parsedData = decoded['transaction'] ?? decoded;
                } catch (_) {
                  parsedData = _parseSpeechTextOffline(text);
                }

                setModalState(() {
                  parsedTransaction = parsedData;
                  isProcessing = false;
                });
              } catch (e) {
                setModalState(() {
                  parsedTransaction = _parseSpeechTextOffline(text);
                  isProcessing = false;
                });
              }
            }

            final padding = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + padding,
              ),
              decoration: BoxDecoration(
                color: themeProvider.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: themeProvider.foregroundColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.mic_rounded,
                              color: Color(0xFF2196F3),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghi chép bằng Giọng nói AI',
                              style: TextStyle(
                                color: themeProvider.foregroundColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: themeProvider.foregroundColor.withOpacity(0.6),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nói chi tiêu của bạn (ví dụ: "Ăn phở bò 45k" hoặc "Đóng tiền điện 500k")',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isRecording)
                            ...List.generate(3, (index) {
                              return Pulse(
                                infinite: true,
                                duration: Duration(milliseconds: 1000 + (index * 300)),
                                child: Container(
                                  width: 80 + (index * 20.0),
                                  height: 80 + (index * 20.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2196F3).withOpacity(0.15),
                                  ),
                                ),
                              );
                            }),
                          GestureDetector(
                            onTap: toggleListening,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isRecording
                                      ? [const Color(0xFFF44336), const Color(0xFFFF5722)]
                                      : [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isRecording ? Colors.red : Colors.blue).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        isRecording ? 'Đang nghe...' : 'Nhấn nút để nói',
                        style: TextStyle(
                          color: isRecording ? const Color(0xFFF44336) : themeProvider.foregroundColor.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Câu nói mẫu (Nhấn để thử ngay):',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(context, "Phở bò gia truyền 45k", simulateSpeech, themeProvider),
                        _buildPresetChip(context, "Mua sắm quần áo 250k", simulateSpeech, themeProvider),
                        _buildPresetChip(context, "Đóng tiền nước 120k", simulateSpeech, themeProvider),
                        _buildPresetChip(context, "Xăng xe máy 50k", simulateSpeech, themeProvider),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: textController,
                      style: TextStyle(color: themeProvider.foregroundColor),
                      decoration: InputDecoration(
                        labelText: 'Nội dung nhận diện giọng nói',
                        labelStyle: TextStyle(color: themeProvider.foregroundColor.withOpacity(0.6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeProvider.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            textController.clear();
                            setModalState(() {
                              parsedTransaction = null;
                            });
                          },
                        ),
                      ),
                      onChanged: (_) {
                        setModalState(() {
                          parsedTransaction = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (parsedTransaction == null)
                      ElevatedButton.icon(
                        onPressed: isProcessing ? null : performAiParsing,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.psychology_rounded),
                        label: Text(isProcessing ? 'AI đang phân tích...' : 'AI Phân tích chi tiêu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.secondaryColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeProvider.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KẾT QUẢ PHÂN TÍCH AI',
                              style: TextStyle(
                                color: const Color(0xFF2196F3),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildResultRow(
                              'Số tiền:',
                              NumberFormat('#,###', 'vi_VN').format(parsedTransaction!['amount'] ?? 0) + ' đ',
                              Icons.payments_rounded,
                              const Color(0xFF4CAF50),
                              themeProvider,
                            ),
                            const Divider(height: 16),
                            _buildResultRow(
                              'Danh mục:',
                              parsedTransaction!['category'] ?? 'Khác',
                              Icons.category_rounded,
                              const Color(0xFFFF9800),
                              themeProvider,
                            ),
                            const Divider(height: 16),
                            _buildResultRow(
                              'Nội dung:',
                              parsedTransaction!['title'] ?? '',
                              Icons.description_rounded,
                              const Color(0xFF2196F3),
                              themeProvider,
                            ),
                            const Divider(height: 16),
                            // Thêm ngày, tháng, giờ được trích xuất từ câu nói giọng nói của người dùng (Xác nhận khớp Hình 2)
                            _buildResultRow(
                              'Thời gian:',
                              (() {
                                if (parsedTransaction!['date'] != null) {
                                  try {
                                    final parsedDate = DateTime.parse(parsedTransaction!['date']);
                                    return DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(parsedDate);
                                  } catch (_) {}
                                }
                                return DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(DateTime.now());
                              })(),
                              Icons.access_time_filled_rounded,
                              const Color(0xFF9C27B0),
                              themeProvider,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(
                                initialOcrResult: jsonEncode(parsedTransaction),
                                isFromVoice: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Xác nhận & Thêm giao dịch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _speech.stop();
    });
  }

  Widget _buildPresetChip(
    BuildContext context,
    String text,
    Function(String) onTap,
    ThemeProvider themeProvider,
  ) {
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          color: themeProvider.foregroundColor,
          fontSize: 12,
        ),
      ),
      backgroundColor: themeProvider.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeProvider.borderColor),
      ),
      onPressed: () => onTap(text),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: themeProvider.foregroundColor.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          // Thoát hoàn toàn ứng dụng và tiến trình terminal (tương đương nhấn 'q')
          exit(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MainDrawer(),
        backgroundColor: themeProvider.backgroundColor,
        body: Container(
          decoration: themeProvider.backgroundDecoration,
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  context.read<AppSessionProvider>().setHomeTabIndex(index);
                },
                children: [
                  HomeTab(
                    onTabChange: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const TransactionTab(),
                  const BudgetTab(),
                  const ReportTab(),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 85, // Nằm ngay trên tab điều hướng
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Chatbot Floating Button
                      ZoomIn(
                        duration: const Duration(milliseconds: 300),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAiOverlayOpen = !_isAiOverlayOpen;
                                });
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEC5B13).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            if (!_isAiOverlayOpen)
                              Positioned(
                                top: -55,
                                right: 15,
                                child: FadeInUp(
                                  key: ValueKey<int>(_currentIndex), // Re-animate when tab changes
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 500),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeProvider.secondaryColor.withValues(alpha: 0.95),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(4),
                                      ),
                                      border: Border.all(
                                        color: themeProvider.borderColor,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _getAiGreeting(_currentIndex),
                                      style: TextStyle(
                                        color: themeProvider.foregroundColor,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mic Button (Nói chi tiêu)
                      ZoomIn(
                        duration: const Duration(milliseconds: 300),
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: themeProvider.secondaryColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: themeProvider.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Nói chi tiêu",
                                style: TextStyle(
                                  color: themeProvider.foregroundColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _showVoiceRecordingDialog(context);
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isAiOverlayOpen)
                Positioned(
                  bottom: 230, // right above both FABs
                  right: 16,
                  child: SafeArea(
                    child: Material(
                      type: MaterialType.transparency,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: MiniAiChatWidget(
                          onClose: () {
                            setState(() {
                              _isAiOverlayOpen = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(
          themeProvider,
          languageProvider,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(
    ThemeProvider themeProvider,
    LanguageProvider languageProvider,
  ) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Glass Background
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: themeProvider.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.grid_view_rounded,
                  languageProvider.translate('tab_home'),
                  themeProvider,
                ),
                _buildNavItem(
                  1,
                  Icons.receipt_long_rounded,
                  languageProvider.translate('tab_transactions'),
                  themeProvider,
                ),
                const SizedBox(width: 60), // Space for AI Scan button
                _buildNavItem(
                  2,
                  Icons.account_balance_wallet_rounded,
                  languageProvider.translate('tab_budget'),
                  themeProvider,
                ),
                _buildNavItem(
                  3,
                  Icons.analytics_rounded,
                  languageProvider.translate('tab_report'),
                  themeProvider,
                ),
              ],
            ),
          ),
          // AI Scan Button (Floating)
          Positioned(
            top: -15,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OcrScanScreen(),
                  ),
                );
                if (result != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddTransactionScreen(initialOcrResult: result),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.backgroundColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC5B13).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    languageProvider.translate('ai_scan'),
                    style: TextStyle(
                      color: themeProvider.foregroundColor.withValues(
                        alpha: 0.9,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEC5B13).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFEC5B13)
                  : themeProvider.foregroundColor.withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFEC5B13)
                  : themeProvider.foregroundColor.withOpacity(0.4),
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: TRANG CHỦ ---
