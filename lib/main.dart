import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chitieu_plus/firebase_options.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/services/google_auth_service.dart';
import 'package:chitieu_plus/widgets/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chitieu_plus/screens/home_screen.dart';
import 'package:chitieu_plus/screens/add_transaction_screen.dart';
import 'package:chitieu_plus/screens/ocr_scan_screen.dart';
import 'package:chitieu_plus/screens/ai_chat_screen.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/utils/session_helper.dart'
    if (dart.library.html) 'package:chitieu_plus/utils/session_helper_web.dart'
    as session_helper;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRestart extends StatefulWidget {
  final Widget child;
  const AppRestart({super.key, required this.child});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartState>()?.restartApp();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Auth Service early
  await GoogleAuthService().init();

  final sessionProvider = AppSessionProvider();
  await sessionProvider.loadSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..loadInitialNotifications(),
        ),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<User?> _authStream;
  bool _isInitialCheck = true;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();

    // Listen to auth state changes to perform global redirects
    _authStream.listen((User? user) {
      if (!mounted) return;
      if (user != null) {
        if (_isInitialCheck && user.isAnonymous) {
          if (kIsWeb && session_helper.checkIsReload()) {
            debugPrint(
              '[DEBUG] main.dart: Web reload detected. Giữ lại tài khoản Khách.',
            );
            // Skip deletion, let the user continue to HomeScreen.
          } else {
            debugPrint(
              '[DEBUG] main.dart: Ký tự khách cũ còn sót lại từ phiên trước. Tiến hành xóa...',
            );
            UserProvider.cleanupGuestIfAny();
            // cleanupGuestIfAny sẽ gọi account.delete() hoặc signOut(),
            // từ đó kích hoạt một sự kiện authStateChanges(null) mới.
            // Ta không điều hướng vòng HomeScreen cho khách ma này.
            _isInitialCheck = false;
            return;
          }
        }

        debugPrint(
          '[DEBUG] main.dart: Auth state changed to LOGGED IN. Checking navigation...',
        );

        final navState = navigatorKey.currentState;
        if (navState != null) {
          debugPrint(
            '[DEBUG] main.dart: Redirecting to HomeScreen via global listener...',
          );

          // Only show "Đăng nhập thành công" if this is NOT the initial app launch check
          final String? welcomeMsg = _isInitialCheck
              ? null
              : 'Đăng nhập thành công!';

          // Only redirect if NOT the initial check.
          // Initial routing is now handled by SplashScreen via AuthWrapper.
          if (!_isInitialCheck) {
            navState.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(welcomeMessage: welcomeMsg),
              ),
              (route) => false,
            );
          }

          // Restore last route if not home
          final session = context.read<AppSessionProvider>();
          if (session.lastRoute != 'home') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (session.lastRoute == 'add_transaction') {
                navState.push(
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              } else if (session.lastRoute == 'ocr_scan') {
                navState.push(
                  MaterialPageRoute(builder: (_) => const OcrScanScreen()),
                );
              } else if (session.lastRoute == 'ai_chat') {
                navState.push(
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              }
            });
          }
        }
      } else {
        debugPrint('[DEBUG] main.dart: Auth state changed to LOGGED OUT.');
        // Only redirect manually if this ISN'T the initial startup check
        if (!_isInitialCheck) {
          final navState = navigatorKey.currentState;
          if (navState != null) {
            debugPrint(
              '[DEBUG] main.dart: Redirecting to AuthWrapper on Logout...',
            );
            navState.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const AuthWrapper(skipSplash: true),
              ),
              (route) => false,
            );
          }
        }
      }

      // After the first event (authenticated or not), it's no longer the initial check
      _isInitialCheck = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AppRestart(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ChiTieuPlus',
        debugShowCheckedModeBanner: false,
        locale: languageProvider.locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi'), Locale('en')],
        themeMode: themeProvider.themeMode,
        theme: ThemeData(
          fontFamily: 'Arial',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF05D15)),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            },
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: WidgetStateProperty.all(false),
            trackVisibility: WidgetStateProperty.all(false),
            interactive: true,
            thickness: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.dragged)) {
                return 8.0;
              }
              return 4.0;
            }),
            radius: const Radius.circular(10),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) {
                return Colors.grey.withValues(alpha: 0.7);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.grey.withValues(alpha: 0.5);
              }
              return Colors.grey.withValues(alpha: 0.3);
            }),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
