import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../screens/ai_chat_screen.dart'; // To get ChatSession
import '../services/ai_service.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class MiniAiChatWidget extends StatefulWidget {
  final VoidCallback onClose;

  const MiniAiChatWidget({super.key, required this.onClose});

  @override
  State<MiniAiChatWidget> createState() => _MiniAiChatWidgetState();
}

class _MiniAiChatWidgetState extends State<MiniAiChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  ChatSession? _currentSession;
  static const String _prefsKey = 'chat_sessions_v2';
  List<ChatSession> _sessions = [];
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    try {
      final results = await connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Connectivity check err: $e');
    }
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(dynamic result) {
    if (!mounted) return;
    bool isOnline = true;
    if (result is List<ConnectivityResult>) {
      isOnline = !result.contains(ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      isOnline = result != ConnectivityResult.none;
    }
    setState(() {
      _isOnline = isOnline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_prefsKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(encoded);
        _sessions = decoded.map((e) => ChatSession.fromJson(e)).toList();

        if (_sessions.isNotEmpty) {
          // Create a new session or use the last one?
          // The user specifically wants "Cuộc trò chuyện mới"
          _startNewChat();
        } else {
          _startNewChat();
        }
      } catch (e) {
        _startNewChat();
      }
    } else {
      _startNewChat();
    }
  }

  void _startNewChat() {
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

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _sessions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentSession == null) return;

    final isNewChat = _currentSession!.messages.length <= 1;

    setState(() {
      _currentSession!.messages.add({
        'role': 'user',
        'text': text,
        'hasAttachments': false,
        'attachmentNames': [],
      });
      _isLoading = true;
    });

    _saveSessions();
    _textController.clear();
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    final transactions = Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).transactions;
    final now = DateTime.now();
    final historyContext =
        "Ngày hiện tại: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}\n${transactions.isEmpty ? "Người dùng hiện chưa có giao dịch nào được ghi lại." : "Lịch sử giao dịch gần đây:\n${transactions.take(30).map((t) => "- ${DateFormat('dd/MM/yyyy').format(t.date)}: ${t.type == TransactionType.expense ? 'Chi' : 'Thu'} ${NumberFormat("#,###").format(t.amount)}đ cho ${t.title} (${t.category})").join("\n")}"}";

    final response = await AiService().sendMessage(
      text,
      attachments: [],
      contextStrings: [historyContext],
    );

    if (mounted) {
      String displayMessage = response;
      Map<String, dynamic>? transactionData;

      try {
        final decoded = json.decode(response);
        displayMessage = decoded['message'] ?? response;

        displayMessage = displayMessage
            .replaceAll('**', '')
            .replaceAll('* ', '• ')
            .replaceAll('*', '');

        if (decoded['transaction'] != null) {
          transactionData = decoded['transaction'];
          transactionData!['isConfirmed'] = false;
        }
      } catch (e) {
        debugPrint('[MiniAiChat] Error parsing JSON: $e');
      }

      setState(() {
        if (response == "LIMIT_EXCEEDED") {
          _currentSession!.messages.add({
            'role': 'ai',
            'text': 'Giới hạn API đã đạt cho Model này. Vui lòng chờ.',
            'isAnimating': true,
          });
        } else {
          _currentSession!.messages.add({
            'role': 'ai',
            'text': displayMessage,
            'transaction': transactionData,
            'isAnimating': true,
          });
        }
        _isLoading = false;
      });

      if (isNewChat) {
        final results = await Future.wait([
          AiService().generateTitle(text),
          AiService().generateCategory(text),
        ]);
        setState(() {
          _currentSession!.title = results[0];
          _currentSession!.category = results[1];
        });
      }

      _saveSessions();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _saveTransaction(Map<String, dynamic> data, int messageIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final transaction = TransactionModel(
        id: '',
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

      await context.read<TransactionProvider>().addTransaction(transaction);

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
      });
      _saveSessions();
    } catch (e) {
      debugPrint("Lỗi khi lưu transaction từ mini widget: $e");
    }
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> data,
    int messageIndex,
    Color accentColor,
  ) {
    final bool isConfirmed = data['isConfirmed'] ?? false;
    final String title = data['title'] ?? '';
    final double amount = (data['amount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.receipt_long_rounded,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'vi_VN').format(amount)}đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isConfirmed) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => _saveTransaction(data, messageIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC5B13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Lưu GD',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final messages = _currentSession?.messages ?? [];

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.9, 350),
      height: math.min(MediaQuery.of(context).size.height * 0.65, 500),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEC5B13),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trợ lý AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Đang hoạt động' : 'Offline',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFEC5B13),
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEC5B13),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Đang suy nghĩ...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                final text = msg['text'] ?? '';
                final transaction = msg['transaction'];
                final isAnimating = msg['isAnimating'] == true;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8, bottom: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC5B13),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width *
                                (isUser ? 0.7 : 0.65),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFEC5B13)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isUser ? 12 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isAnimating && !isUser)
                                _TypewriterText(
                                  text: text,
                                  onFinished: () {
                                    if (mounted) {
                                      setState(() {
                                        msg['isAnimating'] = false;
                                      });
                                    }
                                  },
                                )
                              else
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              if (transaction != null && !isAnimating)
                                _buildTransactionCard(
                                  transaction,
                                  index,
                                  themeProvider.secondaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFFEC5B13),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final VoidCallback onFinished;

  const _TypewriterText({required this.text, required this.onFinished});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  List<String> _words = [];
  double _staggerMs = 30.0;
  final double _fadeDurationMs = 300.0;

  @override
  void initState() {
    super.initState();
    final matches = RegExp(r'(\s+|[^\s]+)').allMatches(widget.text);
    _words = matches.map((m) => m.group(0)!).toList();

    if (_words.length > 1) {
      double maxStaggerMs = (4000.0 - _fadeDurationMs) / (_words.length - 1);
      if (_staggerMs > maxStaggerMs) {
        _staggerMs = math.max(maxStaggerMs, 5.0);
      }
    }

    double totalMs =
        _staggerMs * math.max(_words.length - 1, 0) + _fadeDurationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs.toInt()),
    );

    _animation =
        Tween<double>(
            begin: 0.0,
            end: totalMs,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onFinished();
            }
          });

    if (_words.isNotEmpty) {
      _controller.forward();
    } else {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) return const SizedBox();

    double val = _animation.value;

    List<InlineSpan> spans = [];
    StringBuffer visibleBuffer = StringBuffer();

    for (int i = 0; i < _words.length; i++) {
      double start = i * _staggerMs;
      if (val < start) {
        break;
      }

      double opacity = (val - start) / _fadeDurationMs;
      if (opacity >= 1.0) {
        visibleBuffer.write(_words[i]);
      } else {
        if (visibleBuffer.isNotEmpty) {
          spans.add(TextSpan(text: visibleBuffer.toString()));
          visibleBuffer.clear();
        }
        spans.add(
          TextSpan(
            text: _words[i],
            style: TextStyle(color: Colors.white.withValues(alpha: opacity)),
          ),
        );
      }
    }

    if (visibleBuffer.isNotEmpty) {
      spans.add(TextSpan(text: visibleBuffer.toString()));
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
        children: spans,
      ),
    );
  }
}
