import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for Firebase.app()
import 'package:chitieu_plus/services/realtime_db_service.dart';

class UserProvider with ChangeNotifier {
  String _name = '';
  String _email = '';
  String _photoUrl = '';
  String _currency = 'VND';
  String _phone = '';
  String _dob = '';
  String _gender = 'Nam';
  String _googleAccessToken = '';

  String _googleServerAuthCode = '';
  bool _isGuest = false;

  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get currency => _currency;
  String get phone => _phone;
  String get dob => _dob;
  String get gender => _gender;
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
    _phone = prefs.getString('user_phone') ?? '';
    _dob = prefs.getString('user_dob') ?? '';
    _gender = prefs.getString('user_gender') ?? 'Nam';
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
      _phone = '';
      _dob = '';
      _gender = 'Nam';
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

  /// Khai báo setter mới cho Phone, DOB, Gender
  Future<void> setPhone(String phone) async {
    _phone = phone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
  }

  Future<void> setDob(String dob) async {
    _dob = dob;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_dob', dob);
  }

  Future<void> setGender(String gender) async {
    _gender = gender;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_gender', gender);
  }

  /// 5. Lưu Google Tokens vào Provider và Local Storage
  Future<void> setGoogleTokens({
    required String accessToken,
    String? serverAuthCode,
  }) async {
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] ?? _name;
        // Chỉ ghi đè photoUrl nếu local đang trống hoặc data từ Firestore mới hơn (nếu có logic versioning)
        // Tuy nhiên, tốt nhất là ưu tiên ảnh từ Google Auth nếu vừa đăng nhập
        if (_photoUrl.isEmpty) {
          _photoUrl = data['photoUrl'] ?? '';
        }
        _currency = data['currency'] ?? 'VND';
        _phone = data['phone'] ?? _phone;
        _dob = data['dob'] ?? _dob;
        _gender = data['gender'] ?? _gender;

        // Cập nhật SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _name);
        await prefs.setString('user_email', _email);
        await prefs.setString('user_photo_url', _photoUrl);
        await prefs.setString('user_currency', _currency);
        await prefs.setString('user_phone', _phone);
        await prefs.setString('user_dob', _dob);
        await prefs.setString('user_gender', _gender);
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
      final data = {
        'name': _name,
        'email': _isGuest ? 'guest@chitieuplus.internal' : targetEmail,
        'photoUrl': _photoUrl,
        'currency': _currency,
        'phone': _phone,
        'dob': _dob,
        'gender': _gender,
        'isGuest': _isGuest,
      };

      // 1. Đẩy thông tin của người dùng này lên Firestore
      try {
        final firestoreData = Map<String, dynamic>.from(data)
          ..addAll({
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .set(firestoreData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[UserProvider] Error saving to Firestore: $e');
      }

      // 2. Đẩy thông tin lên Realtime Database luôn để đảm bảo đồng bộ
      try {
        final rtdbData = Map<String, dynamic>.from(data)
          ..addAll({
            'lastLogin': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        await FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://chitieuplus-app-default-rtdb.firebaseio.com',
            )
            .ref()
            .child('users/$docId')
            .update(rtdbData)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[UserProvider] Error saving to Realtime Database: $e');
      }
    }
  }

  /// 7. Gọi hàm này khi khởi động app hoặc khi đăng xuất để xóa sạch dữ liệu Khách (xóa User Auth + Data Firebase)
  static Future<void> cleanupGuestIfAny() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.isAnonymous) {
        final uid = user.uid;

        // 1. Xóa trên Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .delete()
            .timeout(const Duration(seconds: 5));

        // 2. Xóa trên Realtime Database (gồm cả profile và transactions)
        await FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://chitieuplus-app-default-rtdb.firebaseio.com',
            )
            .ref()
            .child('users/$uid')
            .remove()
            .timeout(const Duration(seconds: 5));

        // 3. Xóa Authenticated User
        await user.delete().timeout(const Duration(seconds: 5));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
    } catch (e) {
      debugPrint('[UserProvider] Lỗi khi dọn dẹp tài khoản Khách: $e');
    }
  }
}
