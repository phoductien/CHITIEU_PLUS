import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io'; // Added for Platform check
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Added for device info
import 'dart:async';
import '../models/device_session_model.dart'; // Added model

/// UserProvider: Quản lý toàn bộ thông tin người dùng, ngân hàng, thiết bị và ngân sách.
/// Tích hợp đồng bộ hóa thời gian thực với Firebase (Firestore & RTDB).
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

  double _totalBudget = 5000000;
  double _totalBalance = 0;
  Map<String, double> _categoryBudgets = {};
  List<String> _bankAccounts = [];
  List<DeviceSessionModel> _deviceSessions = [];
  String? _currentDeviceId;

  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<QuerySnapshot>? _sessionsSubscription;

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
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  double get totalBudget => _totalBudget;
  double get totalBalance => _totalBalance;
  Map<String, double> get categoryBudgets => _categoryBudgets;
  List<String> get bankAccounts => _bankAccounts;
  List<DeviceSessionModel> get deviceSessions => _deviceSessions;
  String? get currentDeviceId => _currentDeviceId;

  /// Tải dữ liệu từ bộ nhớ cục bộ (SharedPreferences) khi khởi động ứng dụng
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

    _totalBudget = prefs.getDouble('user_total_budget') ?? 5000000;
    _totalBalance = prefs.getDouble('user_total_balance') ?? 0;
    _bankAccounts = prefs.getStringList('user_bank_accounts') ?? [];
    _currentDeviceId = prefs.getString('device_session_id');

    final catBudgetsJson = prefs.getString('user_category_budgets');
    if (catBudgetsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(catBudgetsJson);
        _categoryBudgets = decoded.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
      } catch (e) {
        debugPrint('[UserProvider] Error decoding category budgets: $e');
      }
    }

    // Proactively start Firebase listener if a user is already authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      fetchFromFirebase();
    }

    notifyListeners();
  }

  /// Thiết lập trạng thái tài khoản Khách (Guest mode)
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

  /// Tải thông tin người dùng từ Firebase Firestore (Khi đã đăng nhập)
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
      _startUserDocumentListener(docId);
      await updateCurrentDeviceSession(
        docId,
      ); // Ensure session is registered first
      _startSessionsListener(docId); // Then start monitoring

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
        if (_photoUrl.isEmpty) {
          _photoUrl = data['photoUrl'] ?? '';
        }
        _currency = data['currency'] ?? 'VND';
        _phone = data['phone'] ?? _phone;
        _dob = data['dob'] ?? _dob;
        _gender = data['gender'] ?? _gender;

        _totalBudget =
            (data['totalBudget'] as num?)?.toDouble() ?? _totalBudget;
        _totalBalance =
            (data['totalBalance'] as num?)?.toDouble() ?? _totalBalance;
        _bankAccounts = List<String>.from(
          data['bankAccounts'] ?? _bankAccounts,
        );
        if (data['categoryBudgets'] != null) {
          _categoryBudgets = (data['categoryBudgets'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
        }

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
        await prefs.setDouble('user_total_budget', _totalBudget);
        await prefs.setDouble('user_total_balance', _totalBalance);
        await prefs.setStringList('user_bank_accounts', _bankAccounts);
        await prefs.setString(
          'user_category_budgets',
          jsonEncode(_categoryBudgets),
        );

        notifyListeners();
      } else {
        debugPrint(
          '[UserProvider] User document DOES NOT exist in Firestore (initial fetch). Auto-creating profile...',
        );
        await syncToFirebase();
      }
    }
  }

  /// Đồng bộ hóa toàn bộ dữ liệu Provider lên Firebase (Firestore và Realtime Database)
  Future<void> syncToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    String targetEmail = '';
    String docId = '';

    if (user != null) {
      targetEmail = user.email ?? '';
      docId = user.uid;
      _isGuest = user.isAnonymous;

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
      _startUserDocumentListener(docId);
      _startSessionsListener(docId);

      final data = {
        'name': _name,
        'email': _isGuest ? 'guest@chitieuplus.internal' : targetEmail,
        'photoUrl': _photoUrl,
        'currency': _currency,
        'phone': _phone,
        'dob': _dob,
        'gender': _gender,
        'isGuest': _isGuest,
        'totalBudget': _totalBudget,
        'totalBalance': _totalBalance,
        'categoryBudgets': _categoryBudgets,
        'bankAccounts': _bankAccounts,
      };

      try {
        final firestoreData = Map<String, dynamic>.from(data)
          ..addAll({
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .set(firestoreData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[UserProvider] Error saving to Firestore: $e');
      }

      try {
        final rtdbData = Map<String, dynamic>.from(data)
          ..addAll({
            'lastLogin': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        await FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://chitieuplus-app-default-rtdb.firebaseio.com',
        ).ref().child('users/$docId').update(rtdbData);
      } catch (e) {
        debugPrint('[UserProvider] Error saving to Realtime Database: $e');
      }
    }
  }

  Future<void> setTotalBalance(double value) async {
    _totalBalance = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_total_balance', value);
    await syncToFirebase();
  }

  Future<void> setTotalBudget(double value) async {
    _totalBudget = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_total_budget', value);
    await syncToFirebase();
  }

  Future<void> setCategoryBudgets(Map<String, double> values) async {
    _categoryBudgets = values;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_category_budgets', jsonEncode(values));
    await syncToFirebase();
  }

  Future<void> addBankAccount(String name) async {
    if (!_bankAccounts.contains(name)) {
      _bankAccounts.add(name);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_bank_accounts', _bankAccounts);
      await syncToFirebase();
    }
  }

  Future<void> removeBankAccount(String name) async {
    if (_bankAccounts.contains(name)) {
      _bankAccounts.remove(name);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_bank_accounts', _bankAccounts);
      await syncToFirebase();
    }
  }

  // --- Quản lý Phiên Đăng nhập & Thiết bị ---

  /// Cập nhật thông tin phiên làm việc hiện tại của thiết bị lên Firestore
  Future<void> updateCurrentDeviceSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('device_session_id');

    // Generate a simple unique ID if not exists
    if (sessionId == null) {
      sessionId =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          (1000 + (DateTime.now().microsecond % 9000)).toString();
      await prefs.setString('device_session_id', sessionId);
    }
    _currentDeviceId = sessionId;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Thiết bị không xác định';
    String deviceType = 'Unknown';
    String osVersion = '';

    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      final browserName = webInfo.browserName
          .toString()
          .split('.')
          .last
          .toUpperCase();
      deviceName = 'Trình duyệt $browserName';
      deviceType = 'Web';
      osVersion = webInfo.platform ?? 'Web';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      deviceType = 'Android';
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      deviceType = 'iOS';
      osVersion = iosInfo.systemVersion;
    } else if (Platform.isWindows) {
      final winInfo = await deviceInfo.windowsInfo;
      deviceName = winInfo.computerName;
      deviceType = 'Windows';
      osVersion = winInfo.releaseId;
    }

    final session = DeviceSessionModel(
      id: sessionId,
      deviceName: deviceName,
      deviceType: deviceType,
      osVersion: osVersion,
      lastActive: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId)
          .set(session.toMap());
    } catch (e) {
      debugPrint('[UserProvider] Error updating device session: $e');
    }
  }

  /// Bắt đầu lắng nghe thay đổi danh sách thiết bị từ Firestore (Hỗ trợ logout từ xa)
  void _startSessionsListener(String uid) {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _deviceSessions = snapshot.docs.map((doc) {
              return DeviceSessionModel.fromMap(
                doc.data(),
                doc.id,
                currentDeviceId: _currentDeviceId,
              );
            }).toList();
            notifyListeners();

            // Logic: If current session is missing from Firestore, it means it was revoked
            // Only sign out if we have some sessions and the current one is not among them
            if (_currentDeviceId != null &&
                _deviceSessions.isNotEmpty &&
                !isCleaningUpGuest && // Avoid race conditions during explicit logout
                !_deviceSessions.any((s) => s.id == _currentDeviceId)) {
              debugPrint(
                '[UserProvider] Current session revoked. Logging out...',
              );
              FirebaseAuth.instance.signOut();
            }
          },
          onError: (error) {
            debugPrint('[UserProvider] Error in sessions listener: $error');
          },
        );
  }

  static bool isCleaningUpGuest = false;

  /// Dọn dẹp tài khoản Khách: xóa dữ liệu trên Firebase và xóa User Auth nếu là khách

  Future<void> removeDeviceSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      debugPrint('[UserProvider] Successfully removed session: $sessionId');
    } catch (e) {
      debugPrint('[UserProvider] Error removing session: $e');
    }
  }

  static Future<void> cleanupGuestIfAny([User? currentUser]) async {
    isCleaningUpGuest = true;
    try {
      final user = currentUser ?? FirebaseAuth.instance.currentUser;
      if (user != null && user.isAnonymous) {
        final uid = user.uid;

        // 1. Xóa trên Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .delete();
        } catch (e) {
          debugPrint('[UserProvider] Không thể xóa Firestore Khách: $e');
        }

        // 2. Xóa trên Realtime Database (gồm cả profile và transactions)
        try {
          await FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: 'https://chitieuplus-app-default-rtdb.firebaseio.com',
          ).ref().child('users/$uid').remove();
        } catch (e) {
          debugPrint('[UserProvider] Không thể xóa RTDB Khách: $e');
        }

        // 3. Xóa Authenticated User
        try {
          await user.delete();
        } catch (e) {
          debugPrint(
            '[UserProvider] Error deleting guest user (token may have expired): $e',
          );
          await FirebaseAuth.instance.signOut();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
    } catch (e) {
      debugPrint('[UserProvider] Lỗi chung khi dọn dẹp tài khoản Khách: $e');
    } finally {
      isCleaningUpGuest = false;
    }
  }

  void _startUserDocumentListener(String uid) {
    if (_userDocSubscription != null) return; // Already listening

    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              debugPrint(
                '[UserProvider] User document DOES NOT exist or was DELETED from Firestore. Ensuring it exists...',
              );
              syncToFirebase();
            }
          },
          onError: (error) {
            debugPrint(
              '[UserProvider] Error in user document listener: $error',
            );
          },
        );
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}
