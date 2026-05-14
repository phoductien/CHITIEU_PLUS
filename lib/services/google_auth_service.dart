import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';

class GoogleSignInResult {
  final String? idToken;
  final String? accessToken;
  final String? serverAuthCode;
  final dynamic user;

  GoogleSignInResult({
    this.idToken,
    this.accessToken,
    this.serverAuthCode,
    this.user,
  });

  AuthCredential? get credential {
    if (idToken == null && accessToken == null) return null;
    return GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  // === COMMON GOOGLE AUTH CONFIGURATION ===
  // Standard Web Client ID from Google Cloud / Firebase Console
  static const String _webClientId =
      '971401377167-fk3p4q28u9ev8clu50ejf437ip183ckb.apps.googleusercontent.com';

  // Redirect URI matching your Firebase Authorized domains
  static const String _firebaseRedirectUri =
      'https://chitieuplus-app.firebaseapp.com/__/auth/handler';

  /// Initialize the service with the correct configuration for each platform.
  Future<void> init() async {
    if (_isInitialized) return;

    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    if (isWindows) {
      // desktop_webview_auth does not require manual initialization
      _isInitialized = true;
      debugPrint('[GoogleAuthService] Initialized for platform: Windows (WebView)');
      return;
    }

    // Configuration for Google Sign-In (Mobile and Web)
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'openid',
      ],
    );

    _isInitialized = true;
    debugPrint(
      '[GoogleAuthService] Initialized for platform: ${kIsWeb ? "Web" : "Mobile"}',
    );
  }

  /// Interactive sign-in process.
  Future<GoogleSignInResult?> signIn() async {
    await init();

    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    if (isWindows) {
      try {
        debugPrint('[GoogleAuthService] Starting Windows interactive Webview sign-in...');
        
        final result = await DesktopWebviewAuth.signIn(
          GoogleSignInArgs(
            clientId: _webClientId,
            redirectUri: _firebaseRedirectUri,
            scope: 'email profile openid',
          ),
        );
        
        if (result == null) {
          debugPrint('[GoogleAuthService] Windows Sign-in was cancelled or returned null.');
          return null;
        }

        debugPrint('[GoogleAuthService] Windows Webview tokens retrieved successfully.');
        debugPrint('[GoogleAuthService] ID Token: ${result.idToken != null ? "Yes" : "No"}');
        debugPrint('[GoogleAuthService] Access Token: ${result.accessToken != null ? "Yes" : "No"}');

        return GoogleSignInResult(
          idToken: result.idToken,
          accessToken: result.accessToken,
          serverAuthCode: null,
          user: null,
        );
      } catch (e) {
        debugPrint('[GoogleAuthService] Windows Webview Sign-in error: $e');
        return null;
      }
    }

    try {
      debugPrint('[GoogleAuthService] Starting interactive sign-in...');

      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        debugPrint('[GoogleAuthService] Sign-in cancelled by user.');
        return null;
      }

      debugPrint('[GoogleAuthService] User authenticated: ${googleUser.email}');

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      final String? serverAuthCode = googleUser.serverAuthCode;

      debugPrint('[GoogleAuthService] Tokens retrieved successfully.');
      debugPrint(
        '[GoogleAuthService] ID Token: ${idToken != null ? "Yes" : "No"}',
      );
      debugPrint(
        '[GoogleAuthService] Access Token: ${accessToken != null ? "Yes" : "No"}',
      );
      debugPrint(
        '[GoogleAuthService] Server Auth Code: ${serverAuthCode != null ? "Yes" : "No"}',
      );

      return GoogleSignInResult(
        idToken: idToken,
        accessToken: accessToken,
        serverAuthCode: serverAuthCode,
        user: googleUser,
      );
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-in error: $e');
      return null;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await init();
    
    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    try {
      if (!isWindows) {
        await _googleSignIn?.signOut();
      }
      await FirebaseAuth.instance.signOut();
      debugPrint('[GoogleAuthService] Signed out successfully.');
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-out error: $e');
    }
  }

  /// Disconnects the current user (revokes tokens).
  Future<void> disconnect() async {
    await init();
    
    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    try {
      if (!isWindows) {
        await _googleSignIn?.disconnect();
      }
      debugPrint('[GoogleAuthService] Disconnected successfully.');
    } catch (e) {
      debugPrint('[GoogleAuthService] Disconnection error: $e');
    }
  }
}

