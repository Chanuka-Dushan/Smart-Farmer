import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────
//  Palette & constants
// ─────────────────────────────────────────────
const _kGreen900 = Color(0xFF1B4332);
const _kGreen700 = Color(0xFF2D6A4F);
const _kGreen500 = Color(0xFF52B788);
const _kGreen100 = Color(0xFFD8F3DC);
const _kAmber    = Color(0xFFFB8500);
const _kAmberBg  = Color(0xFFFFF3E0);
const _kSurface  = Color(0xFFF7F9F8);
const _kCard     = Colors.white;

class TyreTextChatScreen extends StatefulWidget {
  final Map<String, dynamic> damageInfo;

  const TyreTextChatScreen({
    super.key,
    required this.damageInfo,
  });

  @override
  State<TyreTextChatScreen> createState() => _TyreTextChatScreenState();
}

class _TyreTextChatScreenState extends State<TyreTextChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  bool _isConnected    = false;
  bool _isComplete     = false;
  bool _isConnecting   = false;
  String? _errorMessage;
  Map<String, dynamic>? _finalResult;

  late AnimationController _pulseCtrl;
  late AnimationController _inputCtrl;
  late Animation<double> _inputScale;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _inputCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _inputScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _inputCtrl, curve: Curves.easeInOut),
    );

    _connectToTextChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  // ─── Networking ───────────────────────────

  Future<void> _connectToTextChat() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
      final wsUrl = baseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('https', 'wss');

      final uri = Uri.parse('$wsUrl/ws/tyre/text-chat').replace(
        queryParameters: {
          'damage_type':        widget.damageInfo['damage_type'].toString(),
          'confidence':         widget.damageInfo['confidence'].toString(),
          'severity':           widget.damageInfo['severity'].toString(),
          'lifespan_reduction': widget.damageInfo['lifespan_reduction'].toString(),
        },
      );

      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) => setState(() {
          _errorMessage = 'Connection error. Please try again.';
          _isConnected  = false;
        }),
        onDone: () => setState(() => _isConnected = false),
      );

      setState(() {
        _isConnected  = true;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect. Please check your connection.';
        _isConnecting = false;
      });
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      final type = data['type'] as String;

      if (type == 'message' && data['role'] == 'assistant') {
        setState(() => _messages.add(ChatMessage(
          text:      data['content'] as String,
          isUser:    false,
          timestamp: DateTime.now(),
        )));
        _scrollToBottom();
      } else if (type == 'error') {
        _showError(data['content'] as String);
      } else if (type == 'result') {
        setState(() {
          _messages.add(ChatMessage(
            text:      data['content'] as String,
            isUser:    false,
            timestamp: DateTime.now(),
          ));
          _isComplete  = true;
          _finalResult = data as Map<String, dynamic>;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || !_isConnected || _isComplete) return;
    final msg = text.trim();

    setState(() => _messages.add(ChatMessage(
      text:      msg,
      isUser:    true,
      timestamp: DateTime.now(),
    )));
    _messageController.clear();
    _scrollToBottom();

    try {
      _channel!.sink.add(json.encode({'type': 'message', 'content': msg}));
    } catch (_) {
      _showError('Failed to send message');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _kAmber,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── Build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _DamageInfoBanner(damageInfo: widget.damageInfo),
          if (!_isConnected && !_isConnecting) _buildReconnectBanner(),
          Expanded(child: _buildBody()),
          if (_isComplete && _finalResult != null) _buildCompleteBanner(),
          if (!_isComplete && _isConnected) _buildInputArea(),
          if (_isComplete) _buildCloseButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _kGreen900,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kGreen500.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tire_repair_rounded, size: 20, color: _kGreen100),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'මුකුත කථාවක්',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected
                            ? Color.lerp(_kGreen500, Colors.white, _pulseCtrl.value * 0.4)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isConnecting ? 'සම්බන්ධ වෙමින්...' :
                      _isConnected  ? 'සබැඳිව' : 'විසන්ධි',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('සම්බන්ධතාවය අහිමි විය',
                style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: _connectToTextChat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('නැවත සම්බන්ධ',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isConnecting) return _buildLoadingState();
    if (_messages.isEmpty) return _buildEmptyState();
    return _buildMessageList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(_kGreen100, _kGreen500.withOpacity(0.2), _pulseCtrl.value),
              ),
              child: const Icon(Icons.tire_repair_rounded, size: 36, color: _kGreen700),
            ),
          ),
          const SizedBox(height: 24),
          const Text('සම්බන්ධ වෙමින්...',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _kGreen900,
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Text('AI සහායකයා සකස් කෙරේ',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 32),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: _kGreen100,
              color: _kGreen500,
              borderRadius: BorderRadius.circular(10),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_kGreen100, _kGreen500.withOpacity(0.15)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.forum_rounded, size: 40, color: _kGreen700),
          ),
          const SizedBox(height: 20),
          const Text('කථාව ආරම්භ වෙමින්...',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: _kGreen900)),
          const SizedBox(height: 8),
          Text('AI සහායකයා ඔබ සමඟ කතා කරනු ඇත',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final showAvatar = prevMsg == null || prevMsg.isUser != msg.isUser;
        return _buildMessageBubble(msg, showAvatar);
      },
    );
  }

  Widget _buildCompleteBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen900, _kGreen700],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _kGreen900.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kGreen500.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('තක්සේරුව සම්පූර්ණයි',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                Text('ආයු කාලය: ${_finalResult!['lifespan_months']} මාස',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _kGreen500.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(fontSize: 15, color: _kGreen900, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'සංඛ්‍යාවක් ඇතුළත් කරන්න...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ScaleTransition(
              scale: _inputScale,
              child: GestureDetector(
                onTapDown: (_) => _inputCtrl.forward(),
                onTapUp: (_) {
                  _inputCtrl.reverse();
                  _sendMessage(_messageController.text);
                },
                onTapCancel: () => _inputCtrl.reverse(),
                child: Container(
                  width: 50, height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_kGreen500, _kGreen700],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x4052B788), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: const Text('හරි', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Message bubble ───────────────────────

  Widget _buildMessageBubble(ChatMessage message, bool showAvatar) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        top: showAvatar ? 10 : 2,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showAvatar
                  ? Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_kGreen700, _kGreen900],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
                    )
                  : const SizedBox(width: 34),
            ),

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [_kGreen700, _kGreen900],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : _kCard,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(20),
                  topRight:    const Radius.circular(20),
                  bottomLeft:  Radius.circular(isUser ? 20 : (showAvatar ? 4 : 20)),
                  bottomRight: Radius.circular(isUser ? (showAvatar ? 4 : 20) : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _kGreen900.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : _kGreen900,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: showAvatar
                  ? Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kGreen100,
                        border: Border.all(color: _kGreen500.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, size: 18, color: _kGreen700),
                    )
                  : const SizedBox(width: 34),
            ),
        ],
      ),
    );
  }

  String _formatDamageType(String type) {
    final f = type.replaceAll('_', ' ');
    return f[0].toUpperCase() + f.substring(1);
  }
}

// ─────────────────────────────────────────────
//  Damage Info Banner (extracted widget)
// ─────────────────────────────────────────────

class _DamageInfoBanner extends StatelessWidget {
  final Map<String, dynamic> damageInfo;
  const _DamageInfoBanner({required this.damageInfo});

  String _formatDamageType(String type) {
    final f = type.replaceAll('_', ' ');
    return f[0].toUpperCase() + f.substring(1);
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':   return Colors.red;
      case 'medium': return _kAmber;
      default:       return _kGreen500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = ((damageInfo['confidence'] as num) * 100).toStringAsFixed(1);
    final severity   = damageInfo['severity'] as String? ?? 'low';
    final sevColor   = _severityColor(severity);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAmber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _kAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.warning_amber_rounded, color: _kAmber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDamageType(damageInfo['damage_type'] as String),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kGreen900),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Text('$confidence% විශ්වාසය',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(severity.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sevColor)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}