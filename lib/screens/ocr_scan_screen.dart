import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chitieu_plus/services/ai_service.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _processImage(XFile image) async {
    setState(() => _isProcessing = true);
    
    try {
      final bytes = await image.readAsBytes();
      final aiService = AiService();
      
      final prompt = '''
      Hãy đóng vai một chuyên gia kế toán. Tôi sẽ gửi cho bạn một ảnh hóa đơn. 
      Nhiệm vụ của bạn là trích xuất các thông tin sau dưới dạng JSON:
      - title: Tên cửa hàng hoặc nội dung chính của hóa đơn (Ví dụ: "Phở Lý Quốc Sư", "Siêu thị Winmart").
      - amount: Tổng số tiền thanh toán (chỉ lấy số).
      - category: Phân loại vào một trong các mục: Ăn uống, Mua sắm, Di chuyển, Hóa đơn, Giải trí, Sức khỏe, Giáo dục, Khác.
      - date: Ngày trên hóa đơn (định dạng YYYY-MM-DD). Nếu không thấy hãy để ngày hiện tại.
      - note: Ghi chú thêm nếu cần.

      Chỉ trả về JSON, không giải thích gì thêm.
      ''';

      final responseText = await aiService.sendMessage(
        prompt,
        attachments: [
          {'bytes': bytes, 'mimeType': 'image/jpeg'}
        ],
      );

      // Simple JSON extraction from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
        // We'll pass this back to AddTransactionScreen
        if (mounted) {
          Navigator.pop(context, jsonStr);
        }
      } else {
        throw Exception("Không thể nhận diện được hóa đơn. Vui lòng thử lại.");
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Lỗi AI Scan',
          body: e.toString(),
          type: NotificationType.system,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      await _processImage(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Quét hóa đơn AI', style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeProvider.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded, size: 100, color: const Color(0xFFEC5B13).withValues(alpha: 0.1)),
                  const SizedBox(height: 40),
                  Text(
                    'Đặt hóa đơn vào khung hình\nhoặc chọn từ thư viện',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: themeProvider.foregroundColor.withValues(alpha: 0.7), fontSize: 16),
                  ),
                  const SizedBox(height: 60),
                  _buildActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh hóa đơn',
                    themeProvider: themeProvider,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.image_rounded,
                    label: 'Chọn từ thư viện',
                    themeProvider: themeProvider,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFEC5B13)),
                      const SizedBox(height: 20),
                      const Text('Đang phân tích hóa đơn...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Trí tuệ nhân tạo đang xử lý...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required ThemeProvider themeProvider, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: themeProvider.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeProvider.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFEC5B13)),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: themeProvider.foregroundColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

