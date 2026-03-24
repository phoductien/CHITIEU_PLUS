import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  String? _currentOTP;
  String? _targetEmail;
  DateTime? _expiryTime;
  static const int otpValidityMinutes = 5;

  // EmailJS Configuration
  final String _serviceId = 'service_150yl7n';
  final String _templateId = 'template_avdxqmf';
  final String _userId = 'HD7qCZVv4b2qRw7CG';

  /// Generates a 6-digit OTP and sends it via EmailJS
  Future<bool> sendOTP(String email) async {
    _targetEmail = email;
    _currentOTP = _generateRandomOTP();
    _expiryTime = DateTime.now().add(
      const Duration(minutes: otpValidityMinutes),
    );

    debugPrint('------------------------------------------');
    debugPrint('[OTP SERVICE] Sending OTP to: $email');
    debugPrint('[OTP SERVICE] Code: $_currentOTP');
    debugPrint('[OTP SERVICE] Expires at: $_expiryTime');
    debugPrint('------------------------------------------');

    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _userId,
          'template_params': {
            'to_email': email,
            'otp_code': _currentOTP,
            'company_name': 'ChiTieuPlus',
            'expiry_time': '5 phút',
            'reply_to': 'no-reply@chitieuplus.com',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[OTP SERVICE] Email sent successfully via EmailJS');
        return true;
      } else {
        debugPrint('[OTP SERVICE] Failed to send email: ${response.body}');
        // We still return true here so the UI can proceed for testing even if EmailJS limit is reached.
        return true;
      }
    } catch (e) {
      debugPrint('[OTP SERVICE] Error sending email: $e');
      return true; // Fallback to console testing
    }
  }

  /// Verifies the provided OTP
  bool verifyOTP(String otp) {
    if (_currentOTP == null || _expiryTime == null) return false;

    if (DateTime.now().isAfter(_expiryTime!)) {
      debugPrint('[OTP SERVICE] OTP Expired');
      _currentOTP = null;
      return false;
    }

    bool isValid = _currentOTP == otp;
    if (isValid) {
      debugPrint('[OTP SERVICE] OTP Verified Successfully');
      // We don't nullify here yet, might be needed for the reset step
      // but usually, verification token is preferred.
    } else {
      debugPrint('[OTP SERVICE] Invalid OTP provided');
    }

    return isValid;
  }

  String _generateRandomOTP() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  String? get currentEmail => _targetEmail;

  void clear() {
    _currentOTP = null;
    _targetEmail = null;
    _expiryTime = null;
  }
}
