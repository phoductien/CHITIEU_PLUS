import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String _name = '';
  String _email = '';
  String _photoUrl = '';
  String _currency = 'VND';
  String _googleAccessToken = '';

  String _googleServerAuthCode = '';
  bool _isGuest = false;

  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get currency => _currency;
  String get googleAccessToken => _googleAccessToken;
  String get googleServerAuthCode => _googleServerAuthCode;
  bool get isGuest => _isGuest;

  /// 1. Tải dữ liệu từ Local Storage (SharedPreferences) lúc khởi động App
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? '';
    _email = prefs.getString('user_email') ?? '';
    _photoUrl = prefs.getString('user_photo_url') ?? '';
    _currency = prefs.getString('user_currency') ?? 'VND';
    _googleAccessToken = prefs.getString('google_access_token') ?? '';
    _googleServerAuthCode = prefs.getString('google_server_auth_code') ?? '';
    _isGuest = prefs.getBool('is_guest') ?? false;
    notifyListeners();
  }

  /// 2. Đặt trạng thái Khách
  Future<void> setGuestStatus(bool status) async {
    _isGuest = status;
    if (status) {
      _name = 'Khách';
      _email = 'guest@chitieuplus.internal';
      _photoUrl = '';
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', status);
    if (status) {
      await prefs.setString('user_name', _name);
      await prefs.setString('user_email', _email);
      await prefs.setString('user_photo_url', _photoUrl);
    }
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

  /// 4. Lưu Photo URL vào Provider và Local Storage
  Future<void> setPhotoUrl(String photoUrl) async {
    _photoUrl = photoUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo_url', photoUrl);
  }

  /// 5. Lưu Tiền tệ vào Provider (State Management) và Local Storage
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
      _isGuest = user.isAnonymous;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('is_guest') ?? false;
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
      if (!_isGuest) {
        _email = targetEmail;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] ?? _name;
        // Chỉ ghi đè photoUrl nếu local đang trống hoặc data từ Firestore mới hơn (nếu có logic versioning)
        // Tuy nhiên, tốt nhất là ưu tiên ảnh từ Google Auth nếu vừa đăng nhập
        if (_photoUrl.isEmpty) {
          _photoUrl = data['photoUrl'] ?? '';
        }
        _currency = data['currency'] ?? 'VND';
        
        // Cập nhật SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _name);
        await prefs.setString('user_email', _email);
        await prefs.setString('user_photo_url', _photoUrl);
        await prefs.setString('user_currency', _currency);
        await prefs.setBool('is_guest', _isGuest);
        
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
      _isGuest = user.isAnonymous;
      
      // Always update local state if Firebase Auth user has newer info
      bool changed = false;
      if (user.photoURL != null && user.photoURL != _photoUrl) {
        _photoUrl = user.photoURL!;
        changed = true;
      }
      if (user.displayName != null && user.displayName != _name) {
        _name = user.displayName!;
        changed = true;
      }
      if (changed) {
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_photo_url', _photoUrl);
        await prefs.setString('user_name', _name);
        await prefs.setBool('is_guest', _isGuest);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('is_guest') ?? false;
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
        'email': _isGuest ? 'guest@chitieuplus.internal' : targetEmail,
        'photoUrl': _photoUrl,
        'currency': _currency,
        'isGuest': _isGuest,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
