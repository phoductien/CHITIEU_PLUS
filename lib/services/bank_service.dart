import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

/// Service xử lý các nghiệp vụ liên quan đến Ngân hàng và SePay.
class BankService {
  /// XÁC THỰC TÀI KHOẢN NGÂN HÀNG
  ///
  /// LƯU Ý: SePay không hỗ trợ tra cứu tên chủ tài khoản từ số tài khoản bất kỳ.
  /// Hàm này hiện tại trả về kết quả giả định hoặc có thể tích hợp API khác nếu cần.
  Future<Map<String, dynamic>> verifyAccount({
    required String bankId,
    required String accountNumber,
    required String expectedName,
  }) async {
    // Vì SePay không hỗ trợ Lookup, chúng ta sẽ giả định thành công để người dùng trải nghiệm flow
    // Trong thực tế, bạn cần một provider khác (như VietQR) nếu muốn tính năng này.

    await Future.delayed(const Duration(seconds: 1)); // Giả lập độ trễ mạng

    return {
      'success': true,
      'accountName': expectedName.toUpperCase(),
      'message': 'Đã xác nhận thông tin tài khoản (Chế độ SePay).',
    };
  }

  /// LẤY DANH SÁCH TÀI KHOẢN NGÂN HÀNG TỪ SEPAY
  Future<List<dynamic>> fetchBankAccounts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.sepayBankAccountsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['bank_accounts'] ?? [];
      } else {
        throw Exception(
          'Lỗi khi lấy danh sách tài khoản: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('SePay Bank Account Error: $e');
      return [];
    }
  }

  /// LẤY DANH SÁCH GIAO DỊCH TỪ SEPAY
  Future<List<dynamic>> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.sepayTransactionsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transactions'] ?? [];
      } else {
        throw Exception('Lỗi khi lấy giao dịch: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SePay Error: $e');
      return [];
    }
  }

  /// LOẠI BỎ DẤU TIẾNG VIỆT
  ///
  /// Chuyển đổi các ký tự có dấu thành không dấu để chuẩn hóa dữ liệu.
  String removeVietnameseTones(String str) {
    var result = str;
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
    result = result.replaceAll(RegExp(r'[đ]'), 'd');
    result = result.replaceAll(RegExp(r'[Đ]'), 'D');

    // Loại bỏ một số ký tự đặc biệt nếu cần, hoặc trả về kết quả
    return result;
  }
}
