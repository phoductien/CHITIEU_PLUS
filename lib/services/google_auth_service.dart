import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Initialize the service with the correct configuration for each platform.
  Future<void> init() async {
    if (_isInitialized) return;

    // Configuration for Google Sign-In
    const String webClientId = '971401377167-81nlemscod3kmnksrh4v6q7goag4aoku.apps.googleusercontent.com';
    
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : null,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'openid',
      ],
    );

    _isInitialized = true;
    debugPrint('[GoogleAuthService] Initialized for platform: ${kIsWeb ? "Web" : "Mobile"}');
  }

  /// Interactive sign-in process.
  Future<GoogleSignInResult?> signIn() async {
    await init();

    try {
      debugPrint('[GoogleAuthService] Starting interactive sign-in...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        debugPrint('[GoogleAuthService] Sign-in cancelled by user.');
        return null;
      }

      debugPrint('[GoogleAuthService] User authenticated: ${googleUser.email}');
      
      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      final String? serverAuthCode = googleUser.serverAuthCode;

      debugPrint('[GoogleAuthService] Tokens retrieved successfully.');
      debugPrint('[GoogleAuthService] ID Token: ${idToken != null ? "Yes" : "No"}');
      debugPrint('[GoogleAuthService] Access Token: ${accessToken != null ? "Yes" : "No"}');
      debugPrint('[GoogleAuthService] Server Auth Code: ${serverAuthCode != null ? "Yes" : "No"}');

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
    try {
      await _googleSignIn?.signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint('[GoogleAuthService] Signed out successfully.');
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-out error: $e');
    }
  }

  /// Disconnects the current user (revokes tokens).
  Future<void> disconnect() async {
    await init();
    try {
      await _googleSignIn?.disconnect();
      debugPrint('[GoogleAuthService] Disconnected successfully.');
    } catch (e) {
      debugPrint('[GoogleAuthService] Disconnection error: $e');
    }
  }
}
