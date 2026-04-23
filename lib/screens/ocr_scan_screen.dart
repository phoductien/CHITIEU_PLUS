import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:chitieu_plus/services/ai_service.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class OcrScanScreen extends StatefulWidget {
  final String? customPrompt;
  const OcrScanScreen({super.key, this.customPrompt});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;
  bool _isFlashOn = false;

  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    context.read<AppSessionProvider>().setLastRoute('ocr_scan');
    _initCamera();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera({CameraDescription? specificCamera}) async {
    if (!mounted) return;

    // Explicitly check for camera permission
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(
            () => _cameraError =
                'Bạn cần cấp quyền truy cập máy ảnh để sử dụng tính năng này.',
          );
        }
        return;
      }
    }

    setState(() {
      _cameraError = null;
      _isCameraInitialized = false;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription selectedCamera;

        if (specificCamera != null) {
          selectedCamera = specificCamera;
        } else {
          // Automatically select the back camera by default
          try {
            selectedCamera = _cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
            );
          } catch (e) {
            // If no back camera found, use the first available one
            selectedCamera = _cameras!.first;
          }
        }

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        if (mounted) {
          setState(
            () => _cameraError = 'Không tìm thấy camera nào trên thiết bị.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Lỗi khởi tạo camera: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final currentDescription = _cameraController?.description;
    CameraDescription? nextCamera;

    if (currentDescription?.lensDirection == CameraLensDirection.back) {
      // Switch to front
      try {
        nextCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        // Stay on current if no front camera
      }
    } else {
      // Switch to back
      try {
        nextCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
      } catch (_) {
        // Stay on current if no back camera
      }
    }

    if (nextCamera != null && nextCamera != currentDescription) {
      await _cameraController?.dispose();
      _initCamera(specificCamera: nextCamera);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processImage(XFile image) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await image.readAsBytes();
      final aiService = AiService();

      final prompt = widget.customPrompt ?? '''
      Hãy đóng vai một chuyên gia kế toán. Tôi sẽ gửi cho bạn một ảnh hóa đơn. 
      Nhiệm vụ của bạn là trích xuất các thông tin sau dưới dạng JSON:
      - title: Tên cửa hàng hoặc nội dung chính của hóa đơn (Ví dụ: "Phở Lý Quốc Sư", "Siêu thị Winmart").
      - amount: Tổng số tiền thanh toán (chỉ lấy số).
      - category: Phân loại vào: Ăn uống, Mua sắm, Di chuyển, Nhà cửa, Học phí, Bảo hiểm, Tiền điện, Tiền nước, Tiền Gas, Nạp điện thoại, Giải trí, Lương, Khác.
      - date: Ngày giờ trên hóa đơn (chuẩn ISO8601: YYYY-MM-DDTHH:mm:ss). Nếu không thay, hãy để trống.
      - note: Ghi chú thêm nếu cần.

      Chỉ trả về JSON, không giải thích gì thêm.
      ''';

      final responseText = await aiService.sendMessage(
        prompt,
        attachments: [
          {'bytes': bytes, 'mimeType': 'image/jpeg'},
        ],
      );

      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_isCameraInitialized ||
        _cameraError != null) {
      return;
    }
    try {
      final XFile image = await _cameraController!.takePicture();
      await _processImage(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chụp ảnh: $e')));
      }
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _initCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFb54d19),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEC5B13)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: FittedBox(
        fit: BoxFit.cover,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildScannerAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, child) {
            final scanHeight = 80.0;
            final topPos =
                _scanAnimation.value * (constraints.maxHeight + scanHeight) -
                scanHeight;
            return Stack(
              children: [
                Positioned(
                  top: topPos,
                  left: 0,
                  right: 0,
                  height: scanHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF00D1FF).withValues(alpha: 0.0),
                          const Color(0xFF00D1FF).withValues(alpha: 0.1),
                          const Color(0xFF8978F8).withValues(alpha: 0.3),
                        ],
                      ),
                      border: const Border(
                        bottom: BorderSide(
                          color: Color(0xFF00D1FF),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Keeps Gallery and Guide at their original positions
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent, // More premium minimalist
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00D1FF),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFF4A4A4A,
              ), // Solid grey exactly like the screenshot
            ),
          ),
          const SizedBox(height: 20), // Compensate label height of side buttons
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 10,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2838),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Color(0xFF6B8AFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Scanner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isCameraInitialized ? Colors.white : Colors.white24,
              size: 22,
            ),
            onPressed: () async {
              if (_cameraController != null && _isCameraInitialized) {
                setState(() => _isFlashOn = !_isFlashOn);
                await _cameraController!.setFlashMode(
                  _isFlashOn ? FlashMode.torch : FlashMode.off,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cameraswitch_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _toggleCamera,
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Preview Box
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 180,
            child: Container(
              color: const Color(0xFF111111),
              child: Center(child: _buildCameraPreview()),
            ),
          ),

          // 2. White Corners Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 180,
            child: IgnorePointer(
              child: CustomPaint(painter: ScannerOverlayPainter()),
            ),
          ),

          // 3. Scanning Line Animation
          if (_isCameraInitialized && _cameraError == null && !_isProcessing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 180,
              child: IgnorePointer(child: _buildScannerAnimation()),
            ),

          // 4. Instructions Text (kept as a design choice, but hidden or styled appropriately)
          Positioned(
            left: 0,
            right: 0,
            bottom: 150,
            child: Text(
              'Căn chỉnh hóa đơn vào giữa khung hình',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.0),
                fontSize: 14,
              ), // Hidden according to screenshot, but code physically kept
            ),
          ),

          // 5. Bottom Controls (Gallery, Capture, Help)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBottomButton(
                  icon: Icons.image_outlined,
                  label: 'Thư viện',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildCaptureButton(),
                _buildBottomButton(
                  icon: Icons.help_outline_rounded,
                  label: 'Hướng dẫn',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text(
                          'Hướng dẫn quét',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          '1. Đặt hóa đơn trên mặt phẳng đủ sáng.\n2. Căn chỉnh hóa đơn vừa vặn trong khung hình.\n3. Nhấn nút chụp hoặc chọn ảnh từ thư viện.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(color: Color(0xFFEC5B13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 6. Processing Indicator Loader
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00D1FF)),
                    const SizedBox(height: 20),
                    const Text(
                      'Đang phân tích...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trí tuệ nhân tạo đang xử lý...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
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
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double l = 20.0; // corner length (thin lines)

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), paint);

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - l, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
