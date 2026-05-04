import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitieu_plus/services/google_auth_service.dart';
import 'package:chitieu_plus/screens/forgot_password_screen.dart';
import 'package:chitieu_plus/screens/registration_screen.dart';
import 'package:chitieu_plus/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/widgets/app_logo.dart';
import 'package:chitieu_plus/widgets/app_loading_indicator.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/widgets/auth_footer_terms.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF022C4F),
                  Color(0xFF02467D),
                  Color(0xFF0174D7),
                ],
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const AppLogo(size: 72),
                      const SizedBox(height: 16),

                      // App Name
                      const Text(
                        'ChiTieuPlus',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Quản lý tài chính thông minh',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Form Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06294D), // Dark inner box
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Label
                            const Text(
                              'Email hoặc tên đăng nhập',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Email Input
                            _buildInputField(
                              controller: _emailController,
                              hintText: 'Nhập email của bạn',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 24),

                            // Password Label Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mật khẩu',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF05D15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Password Input
                            _buildInputField(
                              controller: _passwordController,
                              hintText: 'Nhập mật khẩu',
                              icon: Icons.lock,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF05D15),
                                disabledBackgroundColor: const Color(
                                  0xFFF05D15,
                                ).withOpacity(0.5),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isLoading
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // OR Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'HOẶC',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Google Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                disabledBackgroundColor: Colors.white
                                    .withOpacity(0.5),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Use a higher quality logo from a reliable source
                                  Image.network(
                                    'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.account_circle,
                                        color: Color(0xFF4285F4),
                                        size: 24,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Tiếp tục với Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Guest Login Button
                            OutlinedButton(
                              onPressed: _isLoading ? null : _loginAsGuest,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Tiếp tục với tư cách Khách',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Chưa có tài khoản? ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegistrationScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Đăng ký ngay',
                                    style: TextStyle(
                                      color: Color(0xFFF05D15),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer Security info
                      const AuthFooterTerms(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Full screen loading overlay with blur effect and boxed spinner
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const AppLoadingIndicator(
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      // 1. Authenticate with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch and Sync User Data

      // We wrap the profile fetching in a timeout/error handler to prevent blocking navigation indefinitely
      try {
        await userProvider.fetchFromFirebase().timeout(
          const Duration(seconds: 5),
        );
        await userProvider.syncToFirebase().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Post-login background tasks error: $e');
      }

      // Add Notification
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Đăng nhập thành công',
          body: 'Chào mừng trở lại! Bạn đã đăng nhập bằng email.',
          type: NotificationType.system,
        );
      }

      // 3. Navigation and Success notification are now handled GLOBALLY in main.dart
      debugPrint(
        '[DEBUG] Email Login: Success. Global listener will handle redirect.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users_passwords')
              .doc(email)
              .get();
          if (doc.exists && doc.data()?['password'] == password) {
            debugPrint(
              '[DEBUG] Email Login: BYPASSED with Firestore override.',
            );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_bypassed_auth', true);
            await prefs.setString('bypassed_email', email);

            if (mounted) {
              final userProvider = context.read<UserProvider>();
              await userProvider.fetchFromFirebase().timeout(
                const Duration(seconds: 5),
              );

              if (!mounted) return;

              // Global auth listener won't fire for bypassed users, so we navigate manually
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
            return;
          }
        } catch (overrideError) {
          debugPrint('Error checking bypass password: $overrideError');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      String errorMessage = 'Đã có lỗi xảy ra';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'Sai email hoặc mật khẩu.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Sai mật khẩu.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email không hợp lệ.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showErrorSnackBar('Lỗi không xác định: $e');
    }
    // We REMOVED the finally block here because we want _isLoading to persist
    // during the global redirect logic in success cases.
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleGoogleSignInResult(GoogleSignInResult? result) async {
    debugPrint(
      'Google Sign-In result received: ${result?.credential != null ? "Success" : "Cancelled"}',
    );
    if (result == null || result.credential == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final credential = result.credential!;

    // Use global navigatorKey for more robust navigation on Web/Callbacks
    final userProvider = context.read<UserProvider>();

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 1. Authenticate with Firebase
      debugPrint('[DEBUG] Google Login: Authenticating with Firebase...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('[DEBUG] Google Login: Auth TIMEOUT');
              throw 'Hết thời gian xác thực tài khoản Google. Vui lòng thử lại.';
            },
          );

      if (userCredential.user != null) {
        debugPrint(
          '[DEBUG] Google Login: Auth Success for ${userCredential.user?.email}',
        );

        // 2. Schedule Background Sync (Non-blocking)
        unawaited(
          Future(() async {
            try {
              // Capture and store Google Tokens for future API calls
              if (result.accessToken != null) {
                await userProvider.setGoogleTokens(
                  accessToken: result.accessToken!,
                  serverAuthCode: result.serverAuthCode,
                );
              }

              // Update local provider state immediately if possible
              if (userCredential.user?.displayName != null) {
                await userProvider.setName(userCredential.user!.displayName!);
              }
              if (userCredential.user?.email != null) {
                await userProvider.setEmail(userCredential.user!.email!);
              }
              if (userCredential.user?.photoURL != null) {
                await userProvider.setPhotoUrl(userCredential.user!.photoURL!);
              }

              // Background Firestore tasks
              await userProvider.fetchFromFirebase().timeout(
                const Duration(seconds: 15),
              );
              await userProvider.syncToFirebase().timeout(
                const Duration(seconds: 15),
              );
              debugPrint('[DEBUG] Google Login: Background sync finished.');

              // Add Notification (Google)
              if (mounted) {
                context.read<NotificationProvider>().addNotification(
                  title: 'Đăng nhập Google',
                  body: 'Tài khoản Google của bạn đã được liên kết thành công.',
                  type: NotificationType.security,
                );
              }
            } catch (e) {
              debugPrint(
                '[DEBUG] Google Login: Background sync error (recovered): $e',
              );
            }
          }),
        );

        // 3. Navigation is now handled GLOBALLY in main.dart by the authStateChanges listener.
        // This ensures the transition happens reliably as soon as Firebase confirms the user.
        debugPrint(
          '[DEBUG] Google Login: Waiting for global listener to handle navigation...',
        );
      } else {
        debugPrint(
          '[DEBUG] Google Login: Received null user from UserCredential.',
        );
      }
    } catch (e) {
      debugPrint('[DEBUG] Google Login: CRITICAL ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Lỗi đăng nhập Google: $e');
      }
    }
    // Note: No finally block here to keep _isLoading = true during successful redirect
  }

  Future<void> _signInWithGoogle() async {
    // Set loading immediately to show the dark overlay BEFORE the Google popup appears (best for Windows/Mobile)
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await GoogleAuthService().signIn();
      await _handleGoogleSignInResult(result);
    } catch (e) {
      debugPrint('[DEBUG] Google Login: Sign In error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Đã hủy hoặc có lỗi khi đăng nhập Google.');
      }
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();

      // 1. Firebase Anonymous Sign In
      final userCredential = await FirebaseAuth.instance.signInAnonymously();

      if (userCredential.user != null) {
        // 2. Set Guest Status in Provider (Syncs with SharedPreferences)
        await userProvider.setGuestStatus(true);

        // 3. Explicitly Sync Initial Guest Profile to Firebase
        try {
          await userProvider.syncToFirebase().timeout(
            const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint(
            '[DEBUG] Guest Login: Error syncing initial profile to Firebase: $e',
          );
        }

        // Add Notification
        if (mounted) {
          context.read<NotificationProvider>().addNotification(
            title: 'Chế độ Khách',
            body:
                'Bạn đang sử dụng ứng dụng với tư cách Khách. Một số tính năng sẽ bị hạn chế.',
            type: NotificationType.system,
          );
        }

        debugPrint(
          '[DEBUG] Guest Login: Success. Global listener will handle redirect.',
        );
      }
    } catch (e) {
      debugPrint('[DEBUG] Guest Login: Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Lỗi khi đăng nhập khách: $e');
      }
    }
  }
}
