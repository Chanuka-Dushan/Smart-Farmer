import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TyreTextChatScreen extends StatefulWidget {
  final Map<String, dynamic> damageInfo;

  const TyreTextChatScreen({
    super.key,
    required this.damageInfo,
  });

  @override
  State<TyreTextChatScreen> createState() => _TyreTextChatScreenState();
}

class _TyreTextChatScreenState extends State<TyreTextChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isComplete = false;
  bool _isConnecting = false;
  String? _errorMessage;
  Map<String, dynamic>? _finalResult;

  @override
  void initState() {
    super.initState();
    _connectToTextChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _connectToTextChat() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Get backend URL from environment
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
      
      final uri = Uri.parse('$wsUrl/ws/tyre/text-chat').replace(
        queryParameters: {
          'damage_type': widget.damageInfo['damage_type'].toString(),
          'confidence': widget.damageInfo['confidence'].toString(),
          'severity': widget.damageInfo['severity'].toString(),
          'lifespan_reduction': widget.damageInfo['lifespan_reduction'].toString(),
        },
      );

      print('📱 Connecting to text chat: $uri');

      _channel = WebSocketChannel.connect(uri);

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('❌ WebSocket error: $error');
          setState(() {
            _errorMessage = 'Connection error. Please try again.';
            _isConnected = false;
          });
        },
        onDone: () {
          print('🔌 WebSocket closed');
          setState(() {
            _isConnected = false;
          });
        },
      );

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      print('✅ Connected to text chat');
    } catch (e) {
      print('❌ Connection failed: $e');
      setState(() {
        _errorMessage = 'Failed to connect. Please check your connection.';
        _isConnecting = false;
      });
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];

      print('📨 Received message: $type');

      if (type == 'message' && data['role'] == 'assistant') {
        // Add assistant's question
        setState(() {
          _messages.add(ChatMessage(
            text: data['content'],
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      } else if (type == 'error') {
        // Show validation error
        _showError(data['content']);
      } else if (type == 'result') {
        // Final result with lifespan calculation
        setState(() {
          _messages.add(ChatMessage(
            text: data['content'],
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isComplete = true;
          _finalResult = data;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || !_isConnected || _isComplete) return;

    final message = text.trim();

    // Add user message to UI
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _messageController.clear();
    _scrollToBottom();

    // Send to server
    try {
      _channel!.sink.add(json.encode({
        'type': 'message',
        'content': message,
      }));
    } catch (e) {
      print('❌ Error sending message: $e');
      _showError('Failed to send message');
    }
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('මුකුත කථාවක්'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Damage info banner
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border(
                bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'හඳුනාගත් හානිය: ${_formatDamageType(widget.damageInfo['damage_type'] as String)} (${((widget.damageInfo['confidence'] as num) * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Connection status banner
          if (!_isConnected && !_isConnecting)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'සම්බන්ධතාවය අහිමි විය',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _connectToTextChat,
                    child: const Text('නැවත සම්බන්ධ කරන්න'),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isConnecting)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 20),
                    Text('සම්බන්ධ වෙමින්...'),
                  ],
                ),
              ),
            )
          else
            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            'කථාව ආරම්භ වෙමින්...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),

          // Complete status banner
          if (_isComplete && _finalResult != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(
                  top: BorderSide(color: Colors.green.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'තක්සේරුව සම්පූර්ණයි: ${_finalResult!['lifespan_months']} මාස',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          if (!_isComplete && _isConnected)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'සංඛ්‍යාවක් ඇතුළත් කරන්න...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),

          // Close button when complete
          if (_isComplete)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('හරි'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDamageType(String type) {
    final formatted = type.replaceAll('_', ' ');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
