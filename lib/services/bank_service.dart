import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Service xử lý các nghiệp vụ liên quan đến Ngân hàng.
/// Chức năng chính: Kiểm tra tính hợp lệ của số tài khoản và đối soát tên chủ tài khoản.
class BankService {
  
  /// XÁC THỰC TÀI KHOẢN NGÂN HÀNG (API THẬT)
  /// 
  /// Sử dụng API của VietQR để lấy tên chủ tài khoản từ hệ thống NAPAS.
  Future<Map<String, dynamic>> verifyAccount({
    required String bankId,
    required String accountNumber,
    required String expectedName,
  }) async {
    try {
      // BƯỚC 1: Gọi API VietQR Lookup
      final response = await http.post(
        Uri.parse(ApiConstants.vietQrLookupUrl),
        headers: {
          'x-client-id': ApiConstants.vietQrClientId,
          'x-api-key': ApiConstants.vietQrApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bin': bankId,
          'accountNumber': accountNumber,
        }),
      ).timeout(const Duration(seconds: 15)); // Timeout sau 15s

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // BƯỚC 2: Kiểm tra mã trả về từ VietQR (Mã '00' là thành công)
        if (data['code'] == '00') {
          String realAccountName = data['data']['accountName'] ?? '';
          
          // BƯỚC 3: Đối soát tên chủ tài khoản
          bool isNameMatch = _compareNames(expectedName, realAccountName);

          if (isNameMatch) {
            return {
              'success': true,
              'accountName': realAccountName,
              'message': 'Xác thực tài khoản thành công.',
            };
          } else {
            return {
              'success': false,
              'message': 'Tên chủ tài khoản không khớp. Ngân hàng trả về: $realAccountName',
            };
          }
        } else {
          // Xử lý các mã lỗi từ API (Ví dụ: Số tài khoản không tồn tại)
          return {
            'success': false,
            'message': data['desc'] ?? 'Thông tin tài khoản không chính xác hoặc không tồn tại.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối Server ngân hàng (Status: ${response.statusCode}).',
        };
      }
    } catch (e) {
      // Xử lý lỗi ngoại lệ (Mất mạng, Timeout...)
      return {
        'success': false,
        'message': 'Không thể kết nối tới hệ thống xác thực. Vui lòng thử lại sau.',
      };
    }
  }

  /// HÀM SO SÁNH TÊN THÔNG MINH
  bool _compareNames(String name1, String name2) {
    String n1 = _normalize(removeVietnameseTones(name1));
    String n2 = _normalize(removeVietnameseTones(name2));
    
    // So sánh khớp hoàn toàn hoặc chứa nhau
    return n1 == n2 || n1.contains(n2) || n2.contains(n1);
  }

  /// Chuẩn hóa chuỗi: Chuyển hoa, xóa khoảng trắng thừa.
  String _normalize(String input) {
    return input.trim().toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' '); 
  }

  /// HÀM LOẠI BỎ DẤU TIẾNG VIỆT
  String removeVietnameseTones(String str) {
    var result = str;
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll(RegExp(r'[đ]'), 'd');
    result = result.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
    result = result.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
    result = result.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
    result = result.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
    result = result.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
    result = result.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
    result = result.replaceAll(RegExp(r'[Đ]'), 'D');
    return result;
  }
}


