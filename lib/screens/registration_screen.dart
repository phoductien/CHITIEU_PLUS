import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chitieu_plus/services/google_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/screens/login_screen.dart';
import 'package:chitieu_plus/widgets/app_logo.dart';
import 'package:chitieu_plus/widgets/app_loading_indicator.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/widgets/auth_footer_terms.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Register Form Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06294D), // Dark inner box
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Label
                            const Text(
                              'Họ và tên',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Name Input
                            _buildInputField(
                              controller: _nameController,
                              hintText: 'Nguyễn Văn A',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            
                            // Email Label
                            const Text(
                              'Email',
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
                              hintText: 'example@email.com',
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Label
                            const Text(
                              'Mật khẩu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Password Input
                            _buildInputField(
                              controller: _passwordController,
                              hintText: '••••••••',
                              icon: Icons.lock,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
    
                            // Confirm Password Label
                            const Text(
                              'Xác nhận mật khẩu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Confirm Password Input
                            _buildInputField(
                              controller: _confirmPasswordController,
                              hintText: '••••••••',
                              icon: Icons.restore,
                              isPassword: true,
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            
                            // Register Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF05D15),
                                disabledBackgroundColor: const Color(0xFFF05D15).withValues(alpha: 0.5),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const AppLoadingIndicator(size: 24, color: Colors.white)
                                : const Text(
                                'ĐĂNG KÝ NGAY',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // OR Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'HOẶC',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Google Register Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF031A33),
                                disabledBackgroundColor: const Color(0xFF031A33).withValues(alpha: 0.5),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/compress/5/53/Google_%22G%22_Logo.svg/1024px-Google_%22G%22_Logo.svg.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.g_mobiledata, color: Colors.white, size: 30);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Đăng ký với Google',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đã có tài khoản? ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                   onTap: () {
                                     Navigator.pop(context); // Trở về Login
                                   },
                                   child: const Text(
                                     'Đăng nhập ngay',
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
          
          // Full screen loading overlay with blur effect
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.6),
                  BlendMode.darken,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: AppLoadingIndicator(size: 48, color: Colors.white),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withValues(alpha: 0.6),
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

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create user in Firebase Auth
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save Name immediately to Provider (which also caches locally)
      if (mounted) {
        await context.read<UserProvider>().setName(name);

        if (mounted) {
          await context.read<UserProvider>().syncToFirebase();
        }

        // Add Notification
        if (mounted) {
          context.read<NotificationProvider>().addNotification(
            title: 'Đăng ký thành công',
            body: 'Chào mừng $name! Tài khoản của bạn đã được khởi tạo.',
            type: NotificationType.system,
          );
        }

        // 3. Sign out so user must log in explicitly
        await FirebaseAuth.instance.signOut();

        // 4. Navigate back to Login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      String errorMessage = 'Đã có lỗi xảy ra';
      if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu quá yếu.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email đã được sử dụng.';
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
    // during the navigation/redirect logic in success cases.
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
    debugPrint('Registration Google Sign-In result: ${result?.credential != null ? "Success" : "Cancelled"}');
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
      debugPrint('[DEBUG] Google Register: Authenticating with Firebase...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15), onTimeout: () {
            debugPrint('[DEBUG] Google Register: Auth TIMEOUT');
            throw 'Hết thời gian xác thực Google. Vui lòng thử lại.';
          });

      if (userCredential.user != null) {
        debugPrint('[DEBUG] Google Register: Auth Success for ${userCredential.user?.email}');
        
        // 2. Schedule Background Sync (Non-blocking)
        unawaited(Future(() async {
          try {
            // Capture and store Google Tokens for future API calls
            if (result.accessToken != null) {
              await userProvider.setGoogleTokens(
                accessToken: result.accessToken!,
                serverAuthCode: result.serverAuthCode,
              );
            }

            await userProvider.fetchFromFirebase().timeout(const Duration(seconds: 15));
            String displayName = userCredential.user?.displayName ?? 'Người dùng Google';
            await userProvider.setName(displayName);
            if (userCredential.user?.email != null) {
              await userProvider.setEmail(userCredential.user!.email!);
            }
            await userProvider.syncToFirebase().timeout(const Duration(seconds: 15));
            debugPrint('[DEBUG] Google Register: Background sync finished.');
          } catch (e) {
            debugPrint('[DEBUG] Google Register: Background sync error (recovered): $e');
          }
        }));

        // 3. Navigation is now handled GLOBALLY in main.dart by the authStateChanges listener.
        debugPrint('[DEBUG] Google Register: Waiting for global listener to handle navigation...');
      } else {
        debugPrint('[DEBUG] Google Register: Received null user from UserCredential.');
      }
    } catch (e) {
      debugPrint('[DEBUG] Google Register: CRITICAL ERROR: $e');
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
    // Set loading immediately to show the dark overlay BEFORE the Google popup appears
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await GoogleAuthService().signIn();
      await _handleGoogleSignInResult(result);
    } catch (e) {
      debugPrint('[DEBUG] Google Register: Sign In error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Đã hủy hoặc có lỗi khi đăng nhập Google.');
      }
    }
  }
}
