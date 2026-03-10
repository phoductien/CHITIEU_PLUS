import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String _name = '';
  String _email = '';
  String _currency = 'VND';
  String _googleAccessToken = '';

  String _googleServerAuthCode = '';

  String get name => _name;
  String get email => _email;
  String get currency => _currency;
  String get googleAccessToken => _googleAccessToken;
  String get googleServerAuthCode => _googleServerAuthCode;

  /// 1. Tải dữ liệu từ Local Storage (SharedPreferences) lúc khởi động App
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? '';
    _email = prefs.getString('user_email') ?? '';
    _currency = prefs.getString('user_currency') ?? 'VND';
    _googleAccessToken = prefs.getString('google_access_token') ?? '';
    _googleServerAuthCode = prefs.getString('google_server_auth_code') ?? '';
    notifyListeners();
  }

  /// 2. Lưu Tên vào Provider (State Management) và Local Storage
  Future<void> setName(String name) async {
    _name = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  /// 3. Lưu Email vào Provider và Local Storage
  Future<void> setEmail(String email) async {
    _email = email;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// 4. Lưu Tiền tệ vào Provider (State Management) và Local Storage
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_currency', currency);
  }

  /// 5. Lưu Google Tokens vào Provider và Local Storage
  Future<void> setGoogleTokens({required String accessToken, String? serverAuthCode}) async {
    _googleAccessToken = accessToken;
    _googleServerAuthCode = serverAuthCode ?? '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_access_token', accessToken);
    await prefs.setString('google_server_auth_code', _googleServerAuthCode);
  }

  /// 5. Tải dữ liệu từ Firebase Firestore (Khi người dùng đăng nhập)
  Future<void> fetchFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    String targetEmail = '';
    String docId = '';

    if (user != null) {
      targetEmail = user.email ?? '';
      docId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_bypassed_auth') == true) {
        targetEmail = prefs.getString('bypassed_email') ?? '';
        if (targetEmail.isNotEmpty) {
           final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: targetEmail)
              .limit(1)
              .get();
           if (snapshot.docs.isNotEmpty) {
             docId = snapshot.docs.first.id;
           }
        }
      }
    }

    if (docId.isNotEmpty) {
      _email = targetEmail;
      final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] ?? '';
        _currency = data['currency'] ?? 'VND';
        
        // Cập nhật SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _name);
        await prefs.setString('user_email', _email);
        await prefs.setString('user_currency', _currency);
        
        notifyListeners();
      }
    }
  }

  /// 6. Lưu Toàn bộ dữ liệu lên Firebase Database (Sau khi có tài khoản Auth)
  Future<void> syncToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    String targetEmail = '';
    String docId = '';

    if (user != null) {
      targetEmail = user.email ?? '';
      docId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_bypassed_auth') == true) {
        targetEmail = prefs.getString('bypassed_email') ?? '';
        if (targetEmail.isNotEmpty) {
           final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: targetEmail)
              .limit(1)
              .get();
           if (snapshot.docs.isNotEmpty) {
             docId = snapshot.docs.first.id;
           }
        }
      }
    }

    if (docId.isNotEmpty) {
      // Đẩy thông tin của người dùng này lên Firestore
      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'name': _name,
        'email': targetEmail,
        'currency': _currency,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
