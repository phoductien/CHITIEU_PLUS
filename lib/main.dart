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
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chitieu_plus/providers/language_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Google Auth Service early
  await GoogleAuthService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..loadInitialNotifications()),
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
      if (user != null) {
        debugPrint('[DEBUG] main.dart: Auth state changed to LOGGED IN. Checking navigation...');
        
        final navState = navigatorKey.currentState;
        if (navState != null) {
          debugPrint('[DEBUG] main.dart: Redirecting to HomeScreen via global listener...');
          
          // Only show "Đăng nhập thành công" if this is NOT the initial app launch check
          final String? welcomeMsg = _isInitialCheck ? null : 'Đăng nhập thành công!';
          
          navState.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(welcomeMessage: welcomeMsg),
            ),
            (route) => false,
          );
        }
      } else {
        debugPrint('[DEBUG] main.dart: Auth state changed to LOGGED OUT.');
      }
      
      // After the first event (authenticated or not), it's no longer the initial check
      _isInitialCheck = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ChiTieuPlus',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
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
      ),
      home: const AuthWrapper(),
    );
  }
}
