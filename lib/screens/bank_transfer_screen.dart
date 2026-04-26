import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/bank_service.dart'; // Import service ngân hàng mới
import 'ocr_scan_screen.dart';

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Map<String, dynamic>? _selectedBank;
  bool _isFormMode = false;

  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();

  bool _isVerifying = false; // Trạng thái đang kiểm tra tài khoản
  final BankService _bankService = BankService(); // Khởi tạo service ngân hàng

  // Danh sách các ngân hàng phổ biến được hiển thị ưu tiên.
  // Logo sử dụng assets địa phương nếu có, ngược lại dùng fallback mặc định.
  final List<Map<String, dynamic>> _popularBanks = [
    {
      'name': 'Vietcombank',
      'bin': '970436',
      'color': const Color(0xFF006A33),
      'shortName': 'VCB',
      'logo': 'assets/icons/banks/Icon-Vietcombank.png',
    },
    {
      'name': 'MB Bank',
      'bin': '970422',
      'color': const Color(0xFF0054A6),
      'shortName': 'MB',
      'logo': 'assets/icons/banks/Icon-MB-Bank-MBB.png',
    },
    {
      'name': 'BIDV',
      'bin': '970418',
      'color': const Color(0xFF005B91),
      'shortName': 'BIDV',
      'logo': 'assets/icons/banks/bidv-logo-_7_.png',
    },
    {
      'name': 'ACB',
      'bin': '970416',
      'color': const Color(0xFF0078BC),
      'shortName': 'ACB',
      'logo': 'assets/icons/banks/Logo-ACB-Ori.png',
    },
    {
      'name': 'Vietinbank',
      'bin': '970415',
      'color': const Color(0xFF00A1E4),
      'shortName': 'CTG',
      'logo': 'assets/icons/banks/Logo-VietinBank-CTG-Ori.png',
    },
    {
      'name': 'Agribank',
      'bin': '970405',
      'color': const Color(0xFF8C281F),
      'shortName': 'VBA',
      'logo': 'assets/icons/banks/Icon-Agribank.png',
    },
    {
      'name': 'Sacombank',
      'bin': '970403',
      'color': const Color(0xFF0054A6),
      'shortName': 'STB',
      'logo': 'assets/icons/banks/logo-sacombank-vector.png',
    },
  ];

  // Danh sách tất cả các ngân hàng để tìm kiếm
  final List<Map<String, dynamic>> _allBanks = [
    {
      'name': 'Vietcombank',
      'bin': '970436',
      'shortName': 'VCB',
      'color': const Color(0xFF006A33),
      'logo': 'assets/icons/banks/Icon-Vietcombank.png',
    },
    {
      'name': 'MB Bank',
      'bin': '970422',
      'shortName': 'MB',
      'color': const Color(0xFF0054A6),
      'logo': 'assets/icons/banks/Icon-MB-Bank-MBB.png',
    },
    {
      'name': 'BIDV',
      'bin': '970418',
      'shortName': 'BIDV',
      'color': const Color(0xFF005B91),
      'logo': 'assets/icons/banks/bidv-logo-_7_.png',
    },
    {
      'name': 'ACB',
      'bin': '970416',
      'shortName': 'ACB',
      'color': const Color(0xFF0078BC),
      'logo': 'assets/icons/banks/Logo-ACB-Ori.png',
    },
    {
      'name': 'Vietinbank',
      'bin': '970415',
      'shortName': 'CTG',
      'color': const Color(0xFF00A1E4),
      'logo': 'assets/icons/banks/Logo-VietinBank-CTG-Ori.png',
    },
    {
      'name': 'Agribank',
      'bin': '970405',
      'shortName': 'VBA',
      'color': const Color(0xFF8C281F),
      'logo': 'assets/icons/banks/Icon-Agribank.png',
    },
    {
      'name': 'Sacombank',
      'bin': '970403',
      'shortName': 'STB',
      'color': const Color(0xFF0054A6),
      'logo': 'assets/icons/banks/logo-sacombank-vector.png',
    },
    {
      'name': 'Techcombank',
      'bin': '970407',
      'shortName': 'TCB',
      'color': const Color(0xFFE31837),
      'logo': '970407',
    },
    {
      'name': 'VPBank',
      'bin': '970432',
      'shortName': 'VPB',
      'color': const Color(0xFF009C41),
      'logo': '970432',
    },
    {
      'name': 'TPBank',
      'bin': '970423',
      'shortName': 'TPB',
      'color': const Color(0xFF532281),
      'logo': '970423',
    },
    {
      'name': 'HDBank',
      'bin': '970437',
      'shortName': 'HDB',
      'color': const Color(0xFFE31837),
      'logo': '970437',
    },
    {
      'name': 'VIB',
      'bin': '970441',
      'shortName': 'VIB',
      'color': const Color(0xFF0054A6),
      'logo': '970441',
    },
    {
      'name': 'SeABank',
      'bin': '970440',
      'shortName': 'SEA',
      'color': const Color(0xFFE31837),
      'logo': '970440',
    },
    {
      'name': 'OCB',
      'bin': '970448',
      'shortName': 'OCB',
      'color': const Color(0xFF008D41),
      'logo': '970448',
    },
    {
      'name': 'MSB',
      'bin': '970426',
      'shortName': 'MSB',
      'color': const Color(0xFFE31837),
      'logo': '970426',
    },
    {
      'name': 'SHB',
      'bin': '970443',
      'shortName': 'SHB',
      'color': const Color(0xFF0054A6),
      'logo': '970443',
    },
    {
      'name': 'Eximbank',
      'bin': '970431',
      'shortName': 'EIB',
      'color': const Color(0xFF0054A6),
      'logo': '970431',
    },
    {
      'name': 'LPBank',
      'bin': '970449',
      'shortName': 'LPB',
      'color': const Color(0xFFE31837),
      'logo': '970449',
    },
    {
      'name': 'Nam A Bank',
      'bin': '970428',
      'shortName': 'NAB',
      'color': const Color(0xFFE31837),
      'logo': '970428',
    },
    {
      'name': 'Bac A Bank',
      'bin': '970409',
      'shortName': 'BAB',
      'color': const Color(0xFFE31837),
      'logo': '970409',
    },
    {
      'name': 'ABBank',
      'bin': '970425',
      'shortName': 'ABB',
      'color': const Color(0xFF0054A6),
      'logo': '970425',
    },
    {
      'name': 'PVcomBank',
      'bin': '970412',
      'shortName': 'PVC',
      'color': const Color(0xFF0054A6),
      'logo': '970412',
    },
    {
      'name': 'VietCapital Bank',
      'bin': '970454',
      'shortName': 'VCC',
      'color': const Color(0xFF0054A6),
      'logo': '970454',
    },
    {
      'name': 'Kienlongbank',
      'bin': '970452',
      'shortName': 'KLB',
      'color': const Color(0xFF0054A6),
      'logo': '970452',
    },
    {
      'name': 'PG Bank',
      'bin': '970430',
      'shortName': 'PGB',
      'color': const Color(0xFF0054A6),
      'logo': '970430',
    },
    {
      'name': 'VietBank',
      'bin': '970433',
      'shortName': 'VBT',
      'color': const Color(0xFF0054A6),
      'logo': '970433',
    },
    {
      'name': 'DongA Bank',
      'bin': '970406',
      'shortName': 'DAB',
      'color': const Color(0xFF0054A6),
      'logo': '970406',
    },
    {
      'name': 'BaoViet Bank',
      'bin': '970438',
      'shortName': 'BVB',
      'color': const Color(0xFF0054A6),
      'logo': '970438',
    },
    {
      'name': 'OceanBank',
      'bin': '970414',
      'shortName': 'OJB',
      'color': const Color(0xFF0054A6),
      'logo': '970414',
    },
    {
      'name': 'GPBank',
      'bin': '970408',
      'shortName': 'GPB',
      'color': const Color(0xFF0054A6),
      'logo': '970408',
    },
    {
      'name': 'CB Bank',
      'bin': '970444',
      'shortName': 'CBB',
      'color': const Color(0xFF0054A6),
      'logo': '970444',
    },
  ];

  final List<Map<String, String>> _recentRecipients = [
    {'name': 'NGUYEN VAN A', 'bank': 'Vietcombank', 'account': '1023456789'},
    {'name': 'TRAN THI B', 'bank': 'MB Bank', 'account': '999988887777'},
  ];

  final List<Map<String, String>> _savedRecipients = [
    {'name': 'ME YEU', 'bank': 'BIDV', 'account': '5611000123456'},
    {'name': 'TIEN NHA', 'bank': 'ACB', 'account': '12345678'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _searchController.text = data!.text!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã dán từ clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showAllBanks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllBanksBottomSheet(
        allBanks: _allBanks,
        onSelect: (bank) {
          setState(() {
            _selectedBank = bank;
          });
        },
      ),
    );
  }

  void _onRecipientTap(Map<String, String> recipient) {
    setState(() {
      _searchController.text = recipient['account']!;
      _selectedBank = _allBanks.firstWhere(
        (b) => b['name'] == recipient['bank'],
        orElse: () => _allBanks.first,
      );
    });
  }

  Future<void> _handleOcr() async {
    const customPrompt = '''
      Hãy đóng vai một chuyên gia ngân hàng. Tôi sẽ gửi cho bạn một hình ảnh (có thể là thẻ ngân hàng, mã QR, hoặc ảnh chụp màn hình thông tin chuyển khoản).
      Nhiệm vụ của bạn là trích xuất các thông tin sau dưới dạng JSON:
      - bankName: Tên ngân hàng (ví dụ: Vietcombank, MB Bank, BIDV...).
      - bankShortName: Tên viết tắt ngân hàng (ví dụ: VCB, MB, BIDV...).
      - accountNumber: Số tài khoản ngân hàng (chỉ lấy số).
      - accountName: Tên chủ tài khoản (nếu có).

      Chỉ trả về JSON, không giải thích gì thêm.
      ''';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OcrScanScreen(customPrompt: customPrompt),
      ),
    );

    if (result != null && result is String) {
      try {
        final Map<String, dynamic> data = jsonDecode(result);
        setState(() {
          if (data['accountNumber'] != null) {
            _searchController.text = data['accountNumber'].toString();
          }
          if (data['bankShortName'] != null) {
            final bank = _allBanks.firstWhere(
              (b) =>
                  b['shortName'].toLowerCase() ==
                  data['bankShortName'].toString().toLowerCase(),
              orElse: () => _allBanks.firstWhere(
                (b) => b['name'].toLowerCase().contains(
                  data['bankName'].toString().toLowerCase(),
                ),
                orElse: () => {},
              ),
            );
            if (bank.isNotEmpty) {
              _selectedBank = bank;
            }
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã nhận diện thông tin ngân hàng')),
          );
        }
      } catch (e) {
        debugPrint('OCR Parse error: $e');
      }
    }
  }

  Future<void> _handleCccdOcr() async {
    const customPrompt = '''
      Hãy đóng vai một chuyên gia định danh. Tôi sẽ gửi cho bạn ảnh chụp mặt trước của thẻ Căn cước công dân (CCCD).
      Nhiệm vụ của bạn là trích xuất các thông tin sau dưới dạng JSON:
      - idNumber: Số căn cước công dân (12 chữ số).
      - fullName: Họ và tên (viết hoa, có dấu).
      - birthDate: Ngày tháng năm sinh.

      Chỉ trả về JSON, không giải thích gì thêm.
      ''';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OcrScanScreen(customPrompt: customPrompt),
      ),
    );

    if (result != null && result is String) {
      try {
        final Map<String, dynamic> data = jsonDecode(result);
        setState(() {
          if (data['idNumber'] != null) {
            _idCardController.text = data['idNumber'].toString();
          }
          if (data['fullName'] != null) {
            // Chuẩn hóa tên cho ngân hàng (viết hoa không dấu)
            _accountHolderController.text = _bankService.removeVietnameseTones(data['fullName'].toString()).toUpperCase();
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã nhận diện thông tin CCCD')),
          );
        }
      } catch (e) {
        debugPrint('CCCD OCR Parse error: $e');
      }
    }
  }

  void _handleContinue() {
    setState(() {
      _isFormMode = true;
    });
  }

  /// XỬ LÝ XÁC NHẬN LIÊN KẾT
  /// Hàm này được gọi khi người dùng nhấn nút "Xác nhận liên kết" ở bước cuối.
  Future<void> _handleConfirmLinking() async {
    // BƯỚC 1: Kiểm tra tính đầy đủ của dữ liệu đầu vào trên UI
    if (_accountNumberController.text.isEmpty ||
        _accountHolderController.text.isEmpty ||
        _idCardController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin tài khoản'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // BƯỚC 2: Bật trạng thái Loading để người dùng chờ 
    setState(() {
      _isVerifying = true;
    });

    try {
      // BƯỚC 3: GỌI DỊCH VỤ XÁC THỰC (Kết nối với BankService)
      // Tại đây, Service sẽ thực hiện đối soát với dữ liệu Ngân hàng.
      final result = await _bankService.verifyAccount(
        bankId: _selectedBank!['bin'],
        accountNumber: _accountNumberController.text,
        expectedName: _accountHolderController.text,
      );

      if (mounted) {
        // BƯỚC 4: Tắt trạng thái Loading sau khi có kết quả
        setState(() {
          _isVerifying = false;
        });

        if (result['success']) {
          // BƯỚC 5A: XÁC THỰC THÀNH CÔNG
          
          // Cập nhật thông tin vào UserProvider để hiển thị lên ví chính
          final bankName = _selectedBank!['shortName'] ?? _selectedBank!['name'];
          final displayInfo = '$bankName - ${_accountNumberController.text}';
          
          if (mounted) {
            await context.read<UserProvider>().addBankAccount(displayInfo);
            
            // Hiển thị Dialog thông báo và tên chủ tài khoản đã được chuẩn hóa từ Ngân hàng.
            _showSuccessDialog(result['accountName'], displayInfo);
          }
        } else {
          // BƯỚC 5B: XÁC THỰC THẤT BẠI
          // Hiển thị lỗi từ Ngân hàng trả về (ví dụ: Sai số TK, Sai tên chủ TK...)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // XỬ LÝ LỖI HỆ THỐNG (Mất mạng, Server lỗi...)
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra trong quá trình kết nối. Vui lòng thử lại sau.')),
        );
      }
    }
  }


  void _showSuccessDialog(String accountName, String bankInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('Thành công', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã xác thực tài khoản:',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              accountName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              'Thông tin ngân hàng:',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              bankInfo,
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            const Text(
              'Liên kết ngân hàng thành công! Tài khoản này đã được đặt làm ví chính của bạn.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay lại màn hình chính
            },
            child: const Text('Tuyệt vời', style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.foregroundColor,
          ),
          onPressed: () {
            if (_isFormMode) {
              setState(() => _isFormMode = false);
            } else if (_selectedBank != null) {
              setState(() => _selectedBank = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _selectedBank == null
              ? 'Chuyển tiền ngân hàng'
              : (_isFormMode ? 'Thông tin ngân hàng' : 'Liên kết ngân hàng'),
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _selectedBank == null
            ? _buildSelectionView(themeProvider)
            : (_isFormMode
                ? _buildLinkingFormView(themeProvider)
                : _buildLinkingView(themeProvider)),
      ),
    );
  }

  Widget _buildSelectionView(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      key: const ValueKey('selection_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Paste Button Row
          FadeInRight(
            duration: const Duration(milliseconds: 500),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _handlePaste,
                icon: const Icon(
                  Icons.content_paste_rounded,
                  size: 18,
                  color: Color(0xFFFF6D00),
                ),
                label: const Text(
                  'Dán',
                  style: TextStyle(
                    color: Color(0xFFFF6D00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Search Bar + Image Icon
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: themeProvider.secondaryColor.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm ngân hàng...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _handleOcr,
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2DD4BF,
                          ).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('Ngân hàng phổ biến', themeProvider),
          const SizedBox(height: 16),

          // Popular Banks Grid
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount:
                  _popularBanks
                      .where(
                        (b) =>
                            b['name'].toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            b['shortName'].toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .length +
                  1,
              itemBuilder: (context, index) {
                final filteredBanks = _popularBanks
                    .where(
                      (b) =>
                          b['name'].toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          b['shortName'].toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
                if (index == filteredBanks.length) {
                  return _buildSeeAllCard(themeProvider);
                }
                return _buildBankCard(filteredBanks[index], themeProvider);
              },
            ),
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('Người nhận gần đây', themeProvider),
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildRecipientList(_recentRecipients, themeProvider),
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('Người nhận đã lưu', themeProvider),
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            child: _buildRecipientList(_savedRecipients, themeProvider),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLinkingView(ThemeProvider themeProvider) {
    final logoPath = _selectedBank!['logo'] as String;
    final isLocal = logoPath.startsWith('assets/');
    final isSacombank = _selectedBank!['name'] == 'Sacombank';

    return SingleChildScrollView(
      key: const ValueKey('linking_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Bank Logo & Name
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: isSacombank ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isSacombank ? null : BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedBank!['color'] as Color).withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isSacombank ? 50 : 12),
                    child: isLocal
                        ? Image.asset(logoPath, fit: BoxFit.contain)
                        : Image.network(
                          'https://img.vietqr.io/image/bank_logo_$logoPath.png',
                          fit: BoxFit.contain,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedBank!['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngân hàng liên kết tài khoản',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Conditions List
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều kiện liên kết',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildConditionItem(
                    'Số điện thoại đăng ký ví phải trùng với số điện thoại đăng ký tại ngân hàng.',
                  ),
                  _buildConditionItem(
                    'Thông tin Họ tên, CCCD phải trùng với thông tin đăng ký tại ngân hàng.',
                  ),
                  _buildConditionItem(
                    'Tài khoản này không liên kết với ví ChiTieuPlus khác.',
                  ),
                  const SizedBox(height: 10),
                  // Suggestion
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gợi ý: Nếu không nhớ số tài khoản, có thể tra cứu bằng tin nhắn SMS của ngân hàng gửi về số điện thoại của mình.',
                            style: TextStyle(
                              color: Colors.blueAccent.withOpacity(0.8),
                              fontSize: 12,
                              height: 1.4,
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

          const SizedBox(height: 40),

          // Action Button
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFF6D00).withOpacity(0.4),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLinkingFormView(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      key: const ValueKey('linking_form_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Form Card
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFFFFCC80),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Liên kết tài khoản',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildFormInput(
                    'SỐ TÀI KHOẢN',
                    'Nhập số tài khoản của bạn',
                    _accountNumberController,
                  ),
                  const SizedBox(height: 20),
                  _buildFormInput(
                    'CHỦ TÀI KHOẢN',
                    'Họ và tên không dấu',
                    _accountHolderController,
                  ),
                  const SizedBox(height: 20),
                  _buildFormInput(
                    'SỐ CCCD',
                    'Nhập 12 số CCCD',
                    _idCardController,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2DD4BF)),
                      onPressed: _handleCccdOcr,
                      tooltip: 'Quét CCCD',
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Note Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF6D00).withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFF6D00),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Lưu ý: Các thông tin được nhập phải là thông tin đã đăng ký tại ngân hàng khi mở tài khoản/thẻ.',
                            style: TextStyle(
                              color: Color(0xFFFFCC80),
                              fontSize: 13,
                              height: 1.4,
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

          const SizedBox(height: 30),

          // Conditions Section
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Điều kiện liên kết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormConditionItem(
                  'Đã đăng ký SMS Banking',
                  'Số điện thoại đăng ký ví phải trùng với số điện thoại đăng ký tại ngân hàng.',
                ),
                _buildFormConditionItem(
                  'Số dư tối thiểu',
                  'Tài khoản ngân hàng cần có ít nhất 50,000đ để thực hiện xác thực ban đầu.',
                ),
                _buildFormConditionItem(
                  'Xác thực danh tính',
                  'Thông tin CCCD phải khớp hoàn toàn với hồ sơ định danh tại ngân hàng.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Security Badge
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 24),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Bảo mật chuẩn quốc tế PCI DSS level 1 - Cấp độ cao nhất toàn cầu.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm Button
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF6D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleConfirmLinking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Xác nhận liên kết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormInput(
    String label,
    String hint,
    TextEditingController controller, {
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormConditionItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2DD4BF),
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFF2DD4BF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (title == 'Ngân hàng phổ biến')
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            if (title == 'Người nhận gần đây')
              const Icon(
                Icons.history_rounded,
                color: Colors.blueAccent,
                size: 20,
              ),
            if (title == 'Người nhận đã lưu')
              const Icon(
                Icons.bookmark_rounded,
                color: Colors.pinkAccent,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankCard(
    Map<String, dynamic> bank,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _selectedBank?['name'] == bank['name'];

    // Kiểm tra nếu là Sacombank để áp dụng bo tròn (circular crop) theo yêu cầu
    final isSacombank = bank['name'] == 'Sacombank';
    final logoPath = bank['logo'] as String;
    final isLocal = logoPath.startsWith('assets/');

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFF6D00).withOpacity(0.15)
            : themeProvider.secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFF6D00).withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedBank = bank;
            });
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: isSacombank ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isSacombank
                        ? null
                        : BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: bank['color'].withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isSacombank ? 21 : 6),
                    child: isLocal
                        ? Image.asset(
                            logoPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildLogoPlaceholder(bank),
                          )
                        : Image.network(
                            'https://img.vietqr.io/image/bank_logo_$logoPath.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildLogoPlaceholder(bank),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bank['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(Map<String, dynamic> bank) {
    return Center(
      child: Text(
        bank['name'].toString().substring(0, 1),
        style: TextStyle(
          color: bank['color'],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSeeAllCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.secondaryColor.withOpacity(0.3),
            themeProvider.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAllBanks,
          splashColor: Colors.transparent,
          highlightColor: Colors.cyanAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.cyanAccent),
              SizedBox(height: 8),
              Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientList(
    List<Map<String, String>> recipients,
    ThemeProvider themeProvider,
  ) {
    final filteredRecipients = recipients
        .where(
          (r) =>
              r['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r['account']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              r['bank']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (filteredRecipients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Không tìm thấy người nhận',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: filteredRecipients.map((recipient) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF6D00).withOpacity(0.1),
              child: Text(
                recipient['name']![0],
                style: const TextStyle(
                  color: Color(0xFFFF6D00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              recipient['name']!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${recipient['bank']} • ${recipient['account']}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
            onTap: () => _onRecipientTap(recipient),
            splashColor: Colors.transparent,
          ),
        );
      }).toList(),
    );
  }
}

class _AllBanksBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> allBanks;
  final Function(Map<String, dynamic>) onSelect;
  const _AllBanksBottomSheet({required this.allBanks, required this.onSelect});

  @override
  State<_AllBanksBottomSheet> createState() => _AllBanksBottomSheetState();
}

class _AllBanksBottomSheetState extends State<_AllBanksBottomSheet> {
  final TextEditingController _sheetSearchController = TextEditingController();
  String _sheetSearchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void _filterBanks(String query) {
    setState(() {
      _sheetSearchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final filteredBanks = widget.allBanks
        .where(
          (bank) =>
              bank['name'].toLowerCase().contains(
                _sheetSearchQuery.toLowerCase(),
              ) ||
              bank['shortName'].toLowerCase().contains(
                _sheetSearchQuery.toLowerCase(),
              ),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ngân hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _sheetSearchController,
                onChanged: _filterBanks,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tìm nhanh tên ngân hàng...',
                  hintStyle: TextStyle(color: Colors.white24),
                  icon: Icon(Icons.search_rounded, color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredBanks.length,
              itemBuilder: (context, index) {
                final bank = filteredBanks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: bank['name'] == 'Sacombank'
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: bank['name'] == 'Sacombank'
                            ? null
                            : BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          bank['name'] == 'Sacombank' ? 25 : 8,
                        ),
                        child: (bank['logo'] as String).startsWith('assets/')
                            ? Image.asset(
                                bank['logo'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildSheetPlaceholder(bank),
                              )
                            : Image.network(
                                'https://img.vietqr.io/image/bank_logo_${bank['logo']}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildSheetPlaceholder(bank),
                              ),
                      ),
                    ),
                    title: Text(
                      bank['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                    ),
                    onTap: () {
                      widget.onSelect(bank);
                      Navigator.pop(context);
                    },
                    splashColor: Colors.transparent,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.secondaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ngân hàng được liên kết tự động qua hệ thống NAPAS.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetPlaceholder(Map<String, dynamic> bank) {
    return Text(
      bank['name'].toString().substring(0, 1),
      style: TextStyle(
        color: bank['color'],
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}

