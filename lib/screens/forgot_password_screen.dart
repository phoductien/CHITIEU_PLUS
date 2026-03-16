import 'package:flutter/material.dart';
import 'package:chitieu_plus/widgets/app_logo.dart';
import 'package:chitieu_plus/widgets/app_loading_indicator.dart';
import 'package:chitieu_plus/services/otp_service.dart';
import 'package:chitieu_plus/screens/otp_verification_screen.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập email');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorSnackBar('Email không hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real production app, we would verify account existence via a cloud function 
      // or similar to avoid enumeration, but here we proceed to send OTP.
      await OTPService().sendOTP(email);
      
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Yêu cầu OTP',
          body: 'Mã xác thực OTP đã được gửi đến email $email',
          type: NotificationType.security,
        );
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(email: email),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF022C4F),
              Color(0xFF02467D),
              Color(0xFF0174D7),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const AppLogo(size: 72),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'CHITIEUPLUS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Form Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06294D).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Quên mật khẩu',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nhập email của bạn để nhận mã xác thực OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Email Field
                        _buildLabel('Email'),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'example@email.com',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF05D15),
                            disabledBackgroundColor: const Color(0xFFF05D15).withValues(alpha: 0.5),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFF05D15).withValues(alpha: 0.4),
                          ),
                          child: _isLoading
                              ? const AppLoadingIndicator(size: 24, color: Colors.white)
                              : const Text(
                                  'Gửi mã xác thực',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Back to Login Link
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white.withValues(alpha: 0.7), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Quay lại đăng nhập',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  Text(
                    '© 2024 ChiTieuPlus. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B66).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
