import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chitieu_plus/widgets/app_logo.dart';
import 'package:chitieu_plus/widgets/app_loading_indicator.dart';
import 'package:chitieu_plus/services/otp_service.dart';
import 'package:chitieu_plus/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/widgets/auth_footer_terms.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _canResend = false;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 300;
    _isError = false;
    _errorMessage = '';
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _isError = true;
          _errorMessage = 'Mã OTP đã hết hiệu lực. Vui lòng gửi lại.';
          _timer?.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    await OTPService().sendOTP(widget.email);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _startTimer();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi lại mã OTP mới')));
    }
  }

  void _onOTPChanged(String value, int index) {
    setState(() {
      _isError = false;
      _errorMessage = '';
    });

    if (value.length > 1) {
      // Xử lý paste
      String pastedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (pastedValue.isNotEmpty) {
        for (int i = 0; i < 6; i++) {
          if (i < pastedValue.length) {
            _controllers[i].text = pastedValue[i];
          } else {
            _controllers[i].clear();
          }
        }
        if (pastedValue.length >= 6) {
          _focusNodes[5].unfocus();
          _verifyOTP(); // Tự động check khi paste đủ 6 số
        } else {
          _focusNodes[pastedValue.length].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else if (index == 5) {
        _focusNodes[index].unfocus();
        _verifyOTP(); // tự động check mã
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_secondsRemaining <= 0) {
      setState(() {
        _isError = true;
        _errorMessage = 'Mã OTP đã hết hiệu lực sau 5 phút. Vui lòng gửi lại.';
      });
      _showErrorSnackBar(_errorMessage);
      return;
    }

    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) {
      setState(() {
        _isError = true;
        _errorMessage = 'Vui lòng nhập đầy đủ 6 chữ số';
      });
      _showErrorSnackBar('Vui lòng nhập đầy đủ 6 chữ số');
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 500));

    bool isValid = OTPService().verifyOTP(otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (isValid) {
        if (mounted) {
          context.read<NotificationProvider>().addNotification(
            title: 'Xác thực thành công',
            body: 'Mã OTP của bạn đã được chấp nhận.',
            type: NotificationType.security,
          );
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordScreen(email: widget.email, otp: otp),
          ),
        );
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Mã OTP không đúng';
        });
        _showErrorSnackBar(_errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
            colors: [Color(0xFF022C4F), Color(0xFF02467D), Color(0xFF0174D7)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
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
                    'ChiTieuPlus',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Verification Shield Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Color(0xFFF05D15),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Xác thực OTP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mã xác thực đã được gửi đến email của bạn.\nVui lòng nhập mã 6 số.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // OTP Input Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOTPBox(index)),
                  ),
                  if (_isError && _errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Timer and Resend
                  Text(
                    'Bạn chưa nhận được mã?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _canResend ? _resendOTP : null,
                    child: Text(
                      'Gửi lại mã (${_formatTime(_secondsRemaining)})',
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFFF05D15)
                            : const Color(0xFFF05D15).withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF05D15),
                      disabledBackgroundColor: const Color(
                        0xFFF05D15,
                      ).withValues(alpha: 0.5),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const AppLoadingIndicator(
                            size: 24,
                            color: Colors.white,
                          )
                        : const Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  const AuthFooterTerms(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 45,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B66).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isError
              ? Colors.redAccent
              : (_focusNodes[index].hasFocus
                    ? const Color(0xFFF05D15)
                    : Colors.white.withValues(alpha: 0.2)),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) => _onOTPChanged(value, index),
      ),
    );
  }
}
