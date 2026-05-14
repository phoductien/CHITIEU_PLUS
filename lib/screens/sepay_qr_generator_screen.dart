import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'bank_transfer_screen.dart';

class SepayQrGeneratorScreen extends StatefulWidget {
  final double? initialAmount;
  const SepayQrGeneratorScreen({super.key, this.initialAmount});

  @override
  State<SepayQrGeneratorScreen> createState() => _SepayQrGeneratorScreenState();
}

class _SepayQrGeneratorScreenState extends State<SepayQrGeneratorScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  String? _selectedAccount;
  String _qrUrl = '';
  bool _isSharing = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    if (userProvider.bankAccounts.isNotEmpty) {
      _selectedAccount = userProvider.bankAccounts.first;
    }
    
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = _currencyFormat
          .format(widget.initialAmount)
          .replaceAll(',', '.');
    }
    
    _amountController.addListener(_updateQrCode);
    
    _updateQrCode();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateQrCode() {
    if (_selectedAccount == null) return;

    final parts = _selectedAccount!.split(' - ');
    if (parts.length < 2) return;

    final bank = parts[0].trim();
    final acc = parts[1].trim();
    
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final amount = amountText.isNotEmpty ? double.tryParse(amountText)?.toInt().toString() ?? '' : '';
    
    setState(() {
      _qrUrl = 'https://qr.sepay.vn/img?bank=$bank&acc=$acc&template=compact&amount=$amount';
    });
  }

  Future<void> _downloadQrCode() async {
    if (_qrUrl.isEmpty) return;
    
    setState(() => _isDownloading = true);
    
    try {
      final response = await http.get(Uri.parse(_qrUrl));
      if (response.statusCode == 200) {
        if (kIsWeb) {
          // Web approach: download the QR image directly to user device
          final blob = html.Blob([response.bodyBytes], 'image/png');
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          html.AnchorElement(href: url)
            ..setAttribute("download", "sepay_qr_payment.png")
            ..click();
            
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã tải mã QR xuống thiết bị thành công!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Native mobile/desktop approach: Save to temporary and trigger Share sheet for direct save options
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/sepay_qr_payment.png').create();
          await file.writeAsBytes(response.bodyBytes);
          
          final xFile = XFile(file.path);
          await Share.shareXFiles([xFile], subject: 'Tải xuống mã QR thanh toán');
        }
      } else {
        throw Exception('Không thể tải ảnh QR');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải xuống: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrUrl.isEmpty) return;
    
    setState(() => _isSharing = true);
    
    try {
      final response = await http.get(Uri.parse(_qrUrl));
      if (response.statusCode == 200) {
        if (kIsWeb) {
          // Web approach: attempt standard file share, fall back to URL/text share
          try {
            final tempFile = XFile.fromData(
              response.bodyBytes,
              mimeType: 'image/png',
              name: 'sepay_qr_payment.png',
            );
            await Share.shareXFiles(
              [tempFile],
              text: 'Quét mã VietQR này để thực hiện chuyển khoản thanh toán!',
            );
          } catch (webShareErr) {
            // Fallback if browser restricts Web Share API files
            await Share.share(
              'Quét mã QR này để chuyển khoản: $_qrUrl',
              subject: 'Chia sẻ mã thanh toán QR VietQR',
            );
          }
        } else {
          // Native mobile/desktop approach
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/sepay_qr_payment.png').create();
          await file.writeAsBytes(response.bodyBytes);
          
          final xFile = XFile(file.path);
          await Share.shareXFiles([xFile], text: 'Thanh toán qua mã QR VietQR - SePay');
        }
      } else {
        throw Exception('Không thể tải ảnh QR để chia sẻ');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chia sẻ: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Container(
      decoration: themeProvider.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeProvider.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Tạo Mã QR SePay',
            style: TextStyle(
              color: themeProvider.foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: userProvider.bankAccounts.isEmpty
              ? _buildEmptyState(themeProvider)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dropdown Tài khoản nhận
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: _buildDropdownCard(themeProvider, userProvider),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nhập Số Tiền
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: _buildInputCard(
                          controller: _amountController,
                          title: 'Số tiền cần nhận (Tùy chọn)',
                          hintText: '0',
                          icon: Icons.payments_rounded,
                          accentColor: Colors.greenAccent,
                          themeProvider: themeProvider,
                          keyboardType: TextInputType.number,
                          isCurrency: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const SizedBox(height: 24),

                      // QR Code Display Card
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: _buildQrDisplayCard(themeProvider),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    label: _isDownloading ? 'Đang tải...' : 'Tải xuống',
                                    icon: Icons.download_rounded,
                                    color: const Color(0xFF334155), // Premium Slate color
                                    isLoading: _isDownloading,
                                    onTap: _downloadQrCode,
                                    themeProvider: themeProvider,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    label: _isSharing ? 'Đang gửi...' : 'Chia sẻ',
                                    icon: Icons.share_rounded,
                                    color: const Color(0xFFEC5B13), // Premium SePay Orange
                                    isLoading: _isSharing,
                                    onTap: _shareQrCode,
                                    themeProvider: themeProvider,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: _buildActionButton(
                                label: 'Quay lại',
                                icon: Icons.close_rounded,
                                color: Colors.blueGrey.withOpacity(0.4),
                                onTap: () => Navigator.pop(context),
                                themeProvider: themeProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: themeProvider.borderColor),
                ),
                child: Icon(
                  Icons.qr_code_rounded,
                  size: 80,
                  color: themeProvider.foregroundColor.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Không tìm thấy tài khoản!',
                style: TextStyle(
                  color: themeProvider.foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn cần liên kết ít nhất một tài khoản ngân hàng để có thể tạo mã QR thanh toán động.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeProvider.foregroundColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC5B13),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BankTransferScreen()),
                  );
                },
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Liên Kết Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCard(ThemeProvider themeProvider, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAccount,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: themeProvider.foregroundColor),
          onChanged: (value) {
            setState(() {
              _selectedAccount = value;
            });
            _updateQrCode();
          },
          items: userProvider.bankAccounts.map((account) {
            return DropdownMenuItem<String>(
              value: account,
              child: Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      account,
                      style: TextStyle(
                        color: themeProvider.foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String title,
    required String hintText,
    required IconData icon,
    required Color accentColor,
    required ThemeProvider themeProvider,
    TextInputType keyboardType = TextInputType.text,
    bool isCurrency = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.secondaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeProvider.foregroundColor.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                color: themeProvider.foregroundColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: accentColor),
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: themeProvider.foregroundColor.withOpacity(0.3)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixText: isCurrency ? 'VNĐ' : null,
                suffixStyle: isCurrency ? TextStyle(color: accentColor, fontWeight: FontWeight.bold) : null,
              ),
              onChanged: (value) {
                if (!isCurrency || value.isEmpty) return;
                String cleanText = value.replaceAll('.', '').replaceAll(',', '');
                double? val = double.tryParse(cleanText);
                if (val != null) {
                  final formatted = _currencyFormat.format(val).replaceAll(',', '.');
                  if (value != formatted) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrDisplayCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // White background so QR scans easily
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image.network
          AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(
              _qrUrl,
              key: ValueKey(_qrUrl),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFEC5B13),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.broken_image_rounded, color: Colors.red, size: 48),
                    SizedBox(height: 12),
                    Text('Không tải được mã QR', style: TextStyle(color: Colors.black54)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Quét để thanh toán an toàn qua VietQR',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    bool isLoading = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
