import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class WebUpdateChecker extends WidgetsBindingObserver {
  static final WebUpdateChecker instance = WebUpdateChecker._internal();
  
  WebUpdateChecker._internal();

  String? _currentHash;
  Timer? _timer;
  bool _hasUpdate = false;
  bool _initialized = false;

  final ValueNotifier<bool> updateAvailableNotifier = ValueNotifier<bool>(false);

  void init() {
    if (!kIsWeb || _initialized) return;
    _initialized = true;
    
    // Add observer to detect lifecycle changes (tab focused / resumed)
    WidgetsBinding.instance.addObserver(this);
    
    // Perform initial fetch to record the current hash of the running app
    _fetchCurrentHash().then((hash) {
      if (hash != null) {
        _currentHash = hash;
        debugPrint('[WebUpdateChecker] Initialized. Current build hash: $_currentHash');
        
        // Start periodic timer every 60 seconds
        _startTimer();
      } else {
        debugPrint('[WebUpdateChecker] Failed to get initial build hash.');
      }
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the tab gains focus/resumes, do an immediate check for updates
    if (state == AppLifecycleState.resumed && kIsWeb && _initialized && !_hasUpdate) {
      debugPrint('[WebUpdateChecker] App resumed, checking for updates...');
      checkForUpdates();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      checkForUpdates();
    });
  }

  Future<void> checkForUpdates() async {
    if (!kIsWeb || _hasUpdate || _currentHash == null) return;

    final newHash = await _fetchCurrentHash();
    if (newHash != null && newHash != _currentHash) {
      debugPrint('[WebUpdateChecker] New version detected! (Old: $_currentHash, New: $newHash)');
      _hasUpdate = true;
      updateAvailableNotifier.value = true;
      _timer?.cancel(); // No need to keep checking
    }
  }

  Future<String?> _fetchCurrentHash() async {
    try {
      // Force cache busting using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('/flutter_bootstrap.js?cb=$timestamp');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Regex to extract serviceWorkerVersion from the code: serviceWorkerVersion: "12345"
        final regex = RegExp(r"""serviceWorkerVersion\s*:\s*["']([^"']+)["']""");
        final match = regex.firstMatch(response.body);
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
      }
    } catch (e) {
      debugPrint('[WebUpdateChecker] Error fetching build hash: $e');
    }
    return null;
  }

  void reloadApp() {
    if (kIsWeb) {
      debugPrint('[WebUpdateChecker] Reloading page to apply updates.');
      html.window.location.reload();
    }
  }
}
