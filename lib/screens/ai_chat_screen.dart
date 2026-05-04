import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chitieu_plus/services/ai_service.dart';

import 'package:chitieu_plus/models/transaction_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:chitieu_plus/providers/notification_provider.dart';
import 'package:chitieu_plus/models/notification_model.dart';
import 'package:chitieu_plus/providers/transaction_provider.dart';
import 'package:chitieu_plus/providers/language_provider.dart';
import 'package:chitieu_plus/providers/theme_provider.dart';
import 'package:chitieu_plus/providers/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:chitieu_plus/providers/app_session_provider.dart';

class ChatSession {
  final String id;
  String title;
  String category;
  final List<Map<String, dynamic>> messages;
  final DateTime createdAt;
  bool isPinned;

  ChatSession({
    required this.id,
    required this.title,
    this.category = 'Khác',
    required this.messages,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'messages': messages,
    'createdAt': createdAt.toIso8601String(),
    'isPinned': isPinned,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    category: json['category'] ?? 'Khác',
    messages: List<Map<String, dynamic>>.from(json['messages']),
    createdAt: DateTime.parse(json['createdAt']),
    isPinned: json['isPinned'] ?? false,
  );
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  static const String _prefsKey = 'chat_sessions_v2';

  // Multi-modal & Voice
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final List<Map<String, dynamic>> _selectedAttachments = [];

  // Connectivity & Limit
  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  DateTime? _lockoutTime;
  Timer? _limitTimer;

  final List<String> _allPromptPool = [
    "Báo cáo chi tiêu tuần này",
    "Thống kê chi tiêu tháng qua",
    "Tổng chi phí ăn uống tháng này là bao nhiêu?",
    "Hôm nay mình đã tiêu những gì?",
    "Phân tích thói quen tiêu dùng của mình",
    "Mẹo tiết kiệm tiền hiệu quả",
    "Ghi chép: Cà phê sáng 30k",
    "Vừa nhận lương 15 triệu",
    "Nạp tiền từ ví dùng thử 500k",
    "So sánh chi tiêu tuần này và tuần trước",
    "Danh mục nào mình tiêu nhiều nhất?",
    "Dự báo chi tiêu tháng tới",
    "Lập kế hoạch tiết kiệm mua iPhone",
    "Cách quản lý tài chính cá nhân",
  ];
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    context.read<AppSessionProvider>().setLastRoute('ai_chat');
    AiService().init();
    _loadSessions();
    _initSpeech();
    _randomizePrompts();
    _initConnectivity();
    _checkAiLimit();
  }

  void _checkAiLimit() async {
    final lockout = await AiService().getLockoutTime();
    setState(() {
      _lockoutTime = lockout;
    });

    if (_lockoutTime != null) {
      _startLimitTimer();
    } else {
      _limitTimer?.cancel();
    }
  }

  void _startLimitTimer() {
    _limitTimer?.cancel();
    _limitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutTime == null) {
        timer.cancel();
        return;
      }

      if (DateTime.now().isAfter(_lockoutTime!)) {
        setState(() {
          _lockoutTime = null;
        });
        timer.cancel();
      } else {
        setState(() {}); // Re-build for countdown
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _limitTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }

  void _initSpeech() async {
    try {
      await _speech.initialize();
      setState(() {});
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  void _randomizePrompts() {
    final pool = List<String>.from(_allPromptPool)..shuffle();
    setState(() {
      _currentSuggestions = pool.take(3).toList();
    });
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString(_prefsKey);

    if (sessionsJson != null) {
      final List<dynamic> decoded = jsonDecode(sessionsJson);
      setState(() {
        _sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
        _sortSessions();
        if (_sessions.isNotEmpty) {
          _currentSession = _sessions.first;
        } else {
          _startNewChat();
        }
      });
      _scrollToBottom();
    } else {
      _startNewChat();
    }
  }

  void _startNewChat() {
    context.read<LanguageProvider>();
    setState(() {
      final newSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Cuộc trò chuyện mới',
        category: 'Khác',
        messages: [
          {
            'role': 'ai',
            'text':
                'Chào bạn, tôi là trợ lý ảo ChiTieuPlus. Tôi có thể giúp gì cho bạn hôm nay?',
          },
        ],
        createdAt: DateTime.now(),
      );
      _sessions.insert(0, newSession);
      _currentSession = newSession;
    });
    _saveSessions();
  }

  void _switchSession(ChatSession session) {
    setState(() {
      _currentSession = session;
    });
    Navigator.pop(context); // Close drawer
    _scrollToBottom();
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _sessions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> _deleteSession(ChatSession session) async {
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
      if (_currentSession?.id == session.id) {
        _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
        if (_currentSession == null) _startNewChat();
      }
    });
    _saveSessions();
  }

  void _togglePin(ChatSession session) {
    setState(() {
      session.isPinned = !session.isPinned;
      _sortSessions();
    });
    _saveSessions();
  }

  void _sortSessions() {
    _sessions.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _renameSession(ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Đổi tên cuộc trò chuyện',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEC5B13)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  session.title = controller.text.trim();
                });
                _saveSessions();
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Lưu',
              style: TextStyle(color: Color(0xFFEC5B13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    setState(() {
      _sessions.clear();
      _startNewChat();
    });
    _saveSessions();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedAttachments.isEmpty) return;
    if (_currentSession == null) return;

    final isNewChat = _currentSession!.messages.length <= 1;
    final sentAttachments = List<Map<String, dynamic>>.from(
      _selectedAttachments,
    );

    setState(() {
      _currentSession!.messages.add({
        'role': 'user',
        'text': text,
        'hasAttachments': sentAttachments.isNotEmpty,
        'attachmentNames': sentAttachments.map((a) => a['name']).toList(),
      });
      _isLoading = true;
      _selectedAttachments.clear();
    });

    _saveSessions();
    _textController.clear();
    _scrollToBottom();

    // Lấy lịch sử giao dịch để làm ngữ cảnh
    final transactions = Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).transactions;
    final now = DateTime.now();
    final historyContext =
        "Ngày hiện tại: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}\n${transactions.isEmpty ? "Người dùng hiện chưa có giao dịch nào recorded." : "Lịch sử giao dịch gần đây:\n${transactions.take(30).map((t) => "- ${DateFormat('dd/MM/yyyy').format(t.date)}: ${t.type == TransactionType.expense ? 'Chi' : 'Thu'} ${NumberFormat("#,###").format(t.amount)}đ cho ${t.title} (${t.category})").join("\n")}"}";

    final response = await AiService().sendMessage(
      text.isEmpty && sentAttachments.isNotEmpty
          ? "Hãy phân tích những nội dung này giúp tôi."
          : text,
      attachments: sentAttachments.where((a) => a['bytes'] != null).toList(),
      contextStrings: [
        historyContext,
        ...sentAttachments
            .where((a) => a['isUrl'] == true)
            .map((a) => "Nội dung từ URL (${a['url']}):\n${a['content']}"),
      ],
    );

    if (mounted) {
      String displayMessage = response;
      Map<String, dynamic>? transactionData;

      try {
        final decoded = json.decode(response);
        displayMessage = decoded['message'] ?? response;

        // Remove markdown asterisks
        displayMessage = displayMessage
            .replaceAll('**', '')
            .replaceAll('* ', '• ')
            .replaceAll('*', '');

        if (decoded['transaction'] != null) {
          transactionData = decoded['transaction'];
          transactionData!['isConfirmed'] = false; // Initial state
        }
      } catch (e) {
        debugPrint('[AiChatScreen] Error parsing AI JSON: $e');
      }

      setState(() {
        if (response == "LIMIT_EXCEEDED") {
          _checkAiLimit();
          _currentSession!.messages.add({
            'role': 'ai',
            'text':
                'Giới hạn API đã đạt cho Model này. Vui lòng chờ hoặc đổi sang Model khác.',
          });
        } else {
          _currentSession!.messages.add({
            'role': 'ai',
            'text': displayMessage,
            'transaction': transactionData,
          });
        }
        _isLoading = false;
      });

      if (isNewChat) {
        final results = await Future.wait([
          AiService().generateTitle(
            text.isNotEmpty ? text : "Phân tích nội dung",
          ),
          AiService().generateCategory(
            text.isNotEmpty ? text : "Phân tích nội dung",
          ),
        ]);
        setState(() {
          _currentSession!.title = results[0];
          _currentSession!.category = results[1];
        });
      }

      _saveSessions();
      _scrollToBottom();
    }
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedAttachments.add({
          'name': image.name,
          'bytes': bytes,
          'mimeType': 'image/jpeg', // Standard for gallery images
          'isImage': true,
        });
      });
    }
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      setState(() {
        _selectedAttachments.add({
          'name': file.name,
          'bytes': file.bytes,
          'mimeType': _getMimeType(file.extension),
          'isImage': false,
        });
      });
    }
  }

  String _getMimeType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể truy cập Micro. Vui lòng cấp quyền.'),
            ),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép vào bộ nhớ tạm'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1E293B),
          ),
        );
      }
    });
  }

  Widget _buildModelDropdown() {
    final aiService = AiService();
    final currentVer = aiService.currentVersion;
    final currentTier = aiService.currentTier;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Chọn phiên bản AI',
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        offset: const Offset(0, -200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Gemini $currentVer ($currentTier)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_less_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
        itemBuilder: (context) {
          final List<PopupMenuEntry<String>> items = [];
          final models = {
            '2.5': ['Nhanh', 'Tư duy', 'Pro'],
            '3.0': ['Nhanh', 'Tư duy', 'Pro'],
          };

          models.forEach((ver, tiers) {
            for (var tier in tiers) {
              final value = '${ver}_$tier';
              final isSelected = ver == currentVer && tier == currentTier;
              items.add(
                PopupMenuItem<String>(
                  value: value,
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        'Gemini $ver ($tier)',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFEC5B13)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFEC5B13),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            if (ver != '3.0') items.add(const PopupMenuDivider());
          });
          return items;
        },
        onSelected: (value) async {
          final parts = value.split('_');
          setState(() => _isLoading = true);
          await AiService().updateConfig(version: parts[0], tier: parts[1]);
          _checkAiLimit();
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.secondaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _currentSession?.title ?? 'Trợ lý AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!_isOnline)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text(
                    'Ngoại tuyến',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _startNewChat,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: themeProvider.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (_currentSession == null) return;
              switch (value) {
                case 'pin':
                  _togglePin(_currentSession!);
                  break;
                case 'rename':
                  _renameSession(_currentSession!);
                  break;

                case 'delete':
                  _deleteSession(_currentSession!);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      _currentSession?.isPinned == true
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentSession?.isPinned == true
                          ? 'Bỏ ghim'
                          : 'Ghim cuộc trò chuyện',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Đổi tên',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),

              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Xóa hội thoại này',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SelectionArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  itemCount:
                      (_currentSession?.messages.length ?? 0) +
                      1, // +1 for the top header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildChatHeader();
                    }

                    final message = _currentSession!.messages[index - 1];
                    final isUser = message['role'] == 'user';
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1E293B),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.tealAccent.shade400,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            Flexible(
                              child: Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFFEC5B13)
                                          : const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(
                                          isUser ? 16 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          isUser ? 4 : 16,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (message['hasAttachments'] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Wrap(
                                              spacing: 8,
                                              children: (message['attachmentNames'] as List).map((
                                                name,
                                              ) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white12,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .attach_file_rounded,
                                                        color: Colors.white70,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        name.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        Text(
                                          message['text'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (!isUser && message['text'] != null)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: IconButton(
                                              onPressed: () => _copyToClipboard(
                                                message['text'],
                                              ),
                                              icon: const Icon(
                                                Icons.copy_rounded,
                                                color: Colors.white38,
                                                size: 16,
                                              ),
                                              tooltip: 'Sao chép',
                                            ),
                                          ),
                                        if (message['transaction'] != null)
                                          _buildTransactionCard(
                                            message['transaction'],
                                            index - 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bây giờ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isUser) ...[
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEC5B13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI đang soạn câu trả lời...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Area
              Container(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Column(
                  children: [
                    // Attachment Preview
                    if (_selectedAttachments.isNotEmpty)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedAttachments.length,
                          itemBuilder: (context, index) {
                            final att = _selectedAttachments[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFEC5B13,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    att['isUrl'] == true
                                        ? (att['isYouTube'] == true
                                              ? Icons.play_circle_fill_rounded
                                              : Icons.link_rounded)
                                        : (att['isImage']
                                              ? Icons.image_rounded
                                              : Icons
                                                    .insert_drive_file_rounded),
                                    color: att['isYouTube'] == true
                                        ? Colors.red
                                        : const Color(0xFFEC5B13),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      att['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _selectedAttachments.removeAt(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    if (_lockoutTime != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Giới hạn model đã đạt. Vui lòng chờ:',
                              style: TextStyle(
                                color: Colors.orangeAccent.shade100,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDuration(
                                _lockoutTime!.difference(DateTime.now()),
                              ),
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_isOnline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Đã mất kết nối mạng. AI đang ngoại tuyến.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Model Selection
                    if (_isOnline) _buildModelDropdown(),

                    // Suggested Prompts
                    if (_isOnline)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _currentSuggestions
                              .map((prompt) => _buildSuggestedPrompt(prompt))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Text Input
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white.withValues(
                              alpha: _isOnline ? 0.5 : 0.2,
                            ),
                          ),
                          onPressed: _isOnline ? _pickFile : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: Colors.white.withValues(
                              alpha: _isOnline ? 0.5 : 0.2,
                            ),
                          ),
                          onPressed: _isOnline ? _pickImage : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    enabled: _isOnline && _lockoutTime == null,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: !_isOnline
                                          ? 'Vui lòng kiểm tra kết nối...'
                                          : (_lockoutTime != null
                                                ? 'AI đang bị giới hạn...'
                                                : (_isListening
                                                      ? 'Đang nghe...'
                                                      : 'Hỏi tôi bất cứ điều gì...')),
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 14,
                                          ),
                                    ),
                                    onSubmitted: (_) =>
                                        (_isOnline && _lockoutTime == null)
                                        ? _sendMessage()
                                        : null,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isListening
                                        ? Icons.mic_rounded
                                        : Icons.mic_none_rounded,
                                    color: (!_isOnline || _lockoutTime != null)
                                        ? Colors.grey
                                        : (_isListening
                                              ? const Color(0xFFEC5B13)
                                              : Colors.white.withValues(
                                                  alpha: 0.4,
                                                )),
                                  ),
                                  onPressed: (_isOnline && _lockoutTime == null)
                                      ? _toggleListening
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Send Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (_isOnline && _lockoutTime == null)
                                ? const Color(0xFFEC5B13)
                                : Colors.grey.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: (_isOnline && _lockoutTime == null)
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFEC5B13,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _isOnline ? _sendMessage : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSessions() {
    final Map<String, List<ChatSession>> grouped = {};

    // Ghép các session theo category
    for (var session in _sessions) {
      final cat = session.category;
      if (!grouped.containsKey(cat)) {
        grouped[cat] = [];
      }
      grouped[cat]!.add(session);
    }

    final List<Widget> items = [];

    // Tạo danh sách widget grouped
    grouped.forEach((category, sessions) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            category.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFEC5B13),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

      for (var session in sessions) {
        final isSelected = _currentSession?.id == session.id;
        items.add(
          ListTile(
            dense: true,
            leading: Icon(
              session.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: session.isPinned
                  ? const Color(0xFFEC5B13)
                  : Colors.white38,
              size: 16,
            ),
            title: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? const Color(0xFFEC5B13) : Colors.white70,
                fontWeight: isSelected || session.isPinned
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFEC5B13),
                    size: 14,
                  )
                : null,
            onTap: () => _switchSession(session),
          ),
        );
      }
    });

    return items;
  }

  Widget _buildTransactionCard(Map<String, dynamic> data, int messageIndex) {
    final bool isConfirmed = data['isConfirmed'] ?? false;
    final String type = data['type'] ?? 'expense';
    final double amount = (data['amount'] ?? 0).toDouble();
    final String title = data['title'] ?? 'Giao dịch mới';
    final String category = data['category'] ?? 'Khác';

    final bool isTrialWallet = title.toLowerCase().contains('ví dùng thử');
    final Color accentColor = isTrialWallet
        ? Colors.cyanAccent
        : (isConfirmed ? Colors.greenAccent : const Color(0xFFEC5B13));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTrialWallet
                    ? Icons.account_balance_wallet_rounded
                    : (isConfirmed
                          ? Icons.check_circle_rounded
                          : Icons.receipt_long_rounded),
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isTrialWallet
                    ? 'Nạp tiền từ Ví dùng thử'
                    : (isConfirmed ? 'Đã lưu giao dịch' : 'Xác nhận giao dịch'),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          _buildInfoRow('Nội dung:', title),
          _buildInfoRow(
            'Số tiền:',
            '${amount.toStringAsFixed(0)}đ',
            valueColor: type == 'expense'
                ? Colors.redAccent
                : Colors.greenAccent,
          ),
          _buildInfoRow('Hạng mục:', category),
          if (!isConfirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveTransaction(data, messageIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC5B13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Lưu giao dịch',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _saveTransaction(Map<String, dynamic> data, int messageIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu giao dịch.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = TransactionModel(
        id: '', // Firestore will generate
        userId: user.uid,
        title: data['title'] ?? 'Giao dịch từ AI',
        amount: (data['amount'] ?? 0).toDouble(),
        category: data['category'] ?? 'Khác',
        date: DateTime.now(),
        type: data['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        note: data['note'],
        wallet: data['wallet'] ?? 'main',
      );

      await context.read<TransactionProvider>().addTransaction(
            transaction,
            userProvider: context.read<UserProvider>(),
          );

      // Add Notification
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Giao dịch thành công',
          body:
              'Đã lưu "${transaction.title}" với số tiền ${NumberFormat('#,###', 'vi_VN').format(transaction.amount)}đ',
          type: NotificationType.transaction,
        );
      }

      setState(() {
        _currentSession!.messages[messageIndex]['transaction']['isConfirmed'] =
            true;
        _isLoading = false;
      });
      _saveSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giao dịch đã được lưu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Add Failure Notification
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Giao dịch thất bại',
          body: 'Không thể lưu giao dịch: ${data['title']}. Lỗi: $e',
          type: NotificationType.transaction,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFFEC5B13),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lịch sử trò chuyện',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_comment_rounded,
              color: Color(0xFFEC5B13),
            ),
            title: const Text(
              'Cuộc trò chuyện mới',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _startNewChat();
            },
          ),
          const Divider(color: Colors.white10),
          Expanded(child: ListView(children: _buildGroupedSessions())),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteAllDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xóa tất cả?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hành động này sẽ xóa vĩnh viễn toàn bộ lịch sử trò chuyện.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAll();
            },
            child: const Text(
              'Xóa hết',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFFEC5B13),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentSession?.messages.length == 1
                ? 'Hôm nay tôi có thể giúp gì cho tình hình tài chính của bạn?'
                : 'Tiếp tục cuộc trò chuyện với ${_currentSession?.title.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompt(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
