import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:chitieu_plus/services/ai_service.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/screens/ocr_scan_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialOcrResult;
  const AddTransactionScreen({super.key, this.initialOcrResult});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Ăn uống';
  final ImagePicker _picker = ImagePicker();
  bool _isAiProcessing = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Ăn uống', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFF97316)},
    {'name': 'Mua sắm', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Di chuyển', 'icon': Icons.directions_car_rounded, 'color': Color(0xFFA855F7)},
    {'name': 'Hóa đơn', 'icon': Icons.description_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Giải trí', 'icon': Icons.videogame_asset_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Sức khỏe', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Giáo dục', 'icon': Icons.school_rounded, 'color': Color(0xFFFACC15)},
    {'name': 'Thêm', 'icon': Icons.add_circle_outline_rounded, 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.initialOcrResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseAiResult(widget.initialOcrResult!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFEC5B13),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() => _isAiProcessing = true);
        try {
          final bytes = await image.readAsBytes();
          final aiService = AiService();
          
          final prompt = '''
          Hãy đóng vai một chuyên gia kế toán. Tôi sẽ gửi cho bạn một ảnh hóa đơn hoặc đoạn văn bản hóa đơn. 
          Nhiệm vụ của bạn là trích xuất các thông tin sau dưới dạng JSON:
          - title: Tên cửa hàng hoặc nội dung chính của hóa đơn (Ví dụ: "Phở Lý Quốc Sư", "Siêu thị Winmart").
          - amount: Tổng số tiền thanh toán (chỉ lấy số nguyên, ví dụ: 20000).
          - category: Phân loại vào một trong các mục: Ăn uống, Mua sắm, Di chuyển, Hóa đơn, Giải trí, Sức khỏe, Giáo dục, Khác.
          - date: Ngày trên hóa đơn (định dạng YYYY-MM-DD). Nếu không thấy hãy để ngày hiện tại.
          - note: Ghi chú chi tiết về các món đồ hoặc nội dung thanh toán (Ví dụ: "Mua 2 bát phở, 1 coca").

          Chỉ trả về JSON, không giải thích gì thêm.
          ''';

          final responseText = await aiService.sendMessage(
            prompt,
            attachments: [
              {'bytes': bytes, 'mimeType': 'image/jpeg'}
            ],
          );

          final jsonStart = responseText.indexOf('{');
          final jsonEnd = responseText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
            _parseAiResult(jsonStr);
          } else {
            throw Exception("Không thể nhận diện được hóa đơn trong ảnh.");
          }
        } catch (e) {
          if (mounted) {
            context.read<NotificationProvider>().addNotification(
              title: 'Lỗi AI Import',
              body: e.toString(),
              type: NotificationType.system,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isAiProcessing = false);
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền truy cập thư viện ảnh')),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để lưu giao dịch')),
        );
      }
      return;
    }

    // Determine type based on category
    final type = _selectedCategory == 'Lương' ? TransactionType.income : TransactionType.expense;

    final transaction = TransactionModel(
      id: '', // Firestore will generate this
      userId: user.uid,
      title: _noteController.text.isNotEmpty ? _noteController.text : _selectedCategory,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      type: type,
      note: _noteController.text,
      wallet: 'main',
    );

    try {
      await context.read<TransactionProvider>().addTransaction(transaction);
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Giao dịch thành công',
          body: 'Đã lưu ${NumberFormat('#,###').format(amount)}đ vào Ví chính',
          type: NotificationType.transaction,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu giao dịch thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Lỗi giao dịch',
          body: e.toString(),
          type: NotificationType.system,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu giao dịch: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startOcrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const OcrScanScreen()),
    );

    if (result != null) {
      _parseAiResult(result);
    }
  }

  void _parseAiResult(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      setState(() {
        _noteController.text = data['title'] ?? data['note'] ?? ''; 
        
        // Format amount with dots for display if possible
        if (data['amount'] != null) {
          final amount = data['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          _amountController.text = amount;
        }
        
        final String catName = data['category'] ?? 'Khác';
        final int catIndex = _categories.indexWhere((c) => c['name'] == catName);
        if (catIndex != -1) {
          _selectedCategory = catName;
        }

        if (data['date'] != null) {
          try {
            _selectedDate = DateTime.parse(data['date']);
          } catch (_) {}
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã trích xuất thông tin từ hóa đơn'), backgroundColor: Color(0xFFEC5B13)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xử lý dữ liệu AI: $e')),
      );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm giao dịch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isAiProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFEC5B13)),
                    const SizedBox(height: 20),
                    const Text('Đang phân tích ảnh...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF334155),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Thủ công'),
                Tab(text: 'Tự động (AI)'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildManualTab(),
              _buildAutoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Text('Số tiền giao dịch', style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(border: InputBorder.none),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('đ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DANH MỤC', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['name']),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEC5B13) : const Color(0xFF334155),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat['icon'], color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text('NGÀY GIAO DỊCH', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, d MMMM, y', 'vi').format(_selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text('GHI CHÚ', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Nhập ghi chú tại đây...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAutoTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Quét hóa đơn (AI Scan)',
                  Icons.document_scanner_rounded,
                  const Color(0xFFEC5B13),
                  onTap: _startOcrScanner,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Nhập từ ảnh',
                  Icons.image_rounded,
                  const Color(0xFF334155),
                  onTap: _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(child: _buildManualTab()), // Reuse fields for review
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC5B13),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: const Color(0xFFEC5B13).withValues(alpha: 0.5),
        ),
        child: const Text('Lưu giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

}
