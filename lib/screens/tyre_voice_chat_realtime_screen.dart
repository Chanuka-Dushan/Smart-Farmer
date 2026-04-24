import 'package:flutter/material.dart';
import 'dart:async';
import '../services/voice_chat_service.dart';
import 'tyre_life_prediction_screen.dart';

class TyreVoiceChatRealtimeScreen extends StatefulWidget {
  final Map<String, dynamic> damageInfo;

  const TyreVoiceChatRealtimeScreen({
    super.key,
    required this.damageInfo,
  });

  @override
  State<TyreVoiceChatRealtimeScreen> createState() => _TyreVoiceChatRealtimeScreenState();
}

class _TyreVoiceChatRealtimeScreenState extends State<TyreVoiceChatRealtimeScreen>
    with SingleTickerProviderStateMixin {
  final VoiceChatService _voiceService = VoiceChatService();
  final List<VoiceTranscript> _transcripts = [];
  final ScrollController _scrollController = ScrollController();
  
  VoiceStatus _status = VoiceStatus.disconnected;
  String _language = 'si'; // Sinhala by default
  bool _isConnecting = false;
  String? _errorMessage;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _transcriptSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for recording indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Connect to voice chat
    _connectToVoiceChat();
  }

  @override
  void dispose() {
    _transcriptSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    _voiceService.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectToVoiceChat() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    // Subscribe to streams
    _transcriptSub = _voiceService.transcriptStream.listen((transcript) {
      setState(() {
        _transcripts.add(transcript);
      });
      _scrollToBottom();
    });
    
    _statusSub = _voiceService.statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });
    
    _errorSub = _voiceService.errorStream.listen((error) {
      setState(() {
        _errorMessage = error;
      });
      _showError(error);
    });

    // Connect to WebSocket
    final connected = await _voiceService.connect(
      damageType: widget.damageInfo['damage_type'] as String,
      confidence: widget.damageInfo['confidence'] as double,
      severity: widget.damageInfo['severity'] as String,
      lifespanReduction: widget.damageInfo['lifespan_reduction'] as double,
      language: _language,
    );

    setState(() {
      _isConnecting = false;
    });

    if (!connected) {
      _showError('Failed to connect to voice chat. Please try again.');
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleRecording() {
    if (_voiceService.isRecording) {
      _voiceService.stopRecording();
    } else {
      _voiceService.startRecording();
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case VoiceStatus.ready:
      case VoiceStatus.listening:
        return Colors.green;
      case VoiceStatus.speaking:
        return Colors.blue;
      case VoiceStatus.processing:
        return Colors.orange;
      case VoiceStatus.aiSpeaking:
        return Colors.purple;
      case VoiceStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case VoiceStatus.disconnected:
        return _language == 'si' ? 'සම්බන්ධ වී නැත' : 'Disconnected';
      case VoiceStatus.connecting:
        return _language == 'si' ? 'සම්බන්ධ වෙමින්...' : 'Connecting...';
      case VoiceStatus.ready:
        return _language == 'si' ? 'සූදානම්' : 'Ready';
      case VoiceStatus.listening:
        return _language == 'si' ? 'සවන් දෙමින්...' : 'Listening...';
      case VoiceStatus.speaking:
        return _language == 'si' ? 'කථා කරමින්...' : 'Speaking...';
      case VoiceStatus.processing:
        return _language == 'si' ? 'සැකසෙමින්...' : 'Processing...';
      case VoiceStatus.aiSpeaking:
        return _language == 'si' ? 'AI කථා කරමින්' : 'AI Speaking';
      case VoiceStatus.error:
        return _language == 'si' ? 'දෝෂයක්' : 'Error';
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case VoiceStatus.ready:
      case VoiceStatus.listening:
        return Icons.check_circle;
      case VoiceStatus.speaking:
        return Icons.mic;
      case VoiceStatus.processing:
        return Icons.hourglass_empty;
      case VoiceStatus.aiSpeaking:
        return Icons.volume_up;
      case VoiceStatus.error:
        return Icons.error;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_language == 'si' ? 'හඬ සංවාදය' : 'Voice Chat'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Language selector
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _language = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'si',
                child: Row(
                  children: [
                    Icon(Icons.language),
                    SizedBox(width: 8),
                    Text('සිංහල (Sinhala)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Icon(Icons.language),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Damage info banner
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_language == 'si' ? 'හඳුනාගත්' : 'Detected'}: ${_formatDamageType(widget.damageInfo['damage_type'] as String)} (${((widget.damageInfo['confidence'] as num) * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                const SizedBox(width: 10),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_status == VoiceStatus.processing ||
                    _status == VoiceStatus.connecting) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                    ),
                  ),
                ],
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
                    CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                    SizedBox(height: 20),
                    Text('Connecting to voice chat...'),
                  ],
                ),
              ),
            )
          else if (_status == VoiceStatus.disconnected && !_isConnecting)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      _language == 'si' ? 'සම්බන්ධතාවය අහිමි විය' : 'Connection lost',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _connectToVoiceChat,
                      icon: const Icon(Icons.refresh),
                      label: Text(_language == 'si' ? 'නැවත සම්බන්ධ කරන්න' : 'Reconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Transcripts list
            Expanded(
              child: _transcripts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            _language == 'si' 
                                ? 'කථා කිරීමට බොත්තම ඔබන්න'
                                : 'Press the button to speak',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(15),
                      itemCount: _transcripts.length,
                      itemBuilder: (context, index) {
                        return _buildTranscriptBubble(_transcripts[index]);
                      },
                    ),
            ),

          // Recording button
          if (_status != VoiceStatus.disconnected && !_isConnecting)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Instructions
                  if (!_voiceService.isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        _language == 'si'
                            ? 'කථා කිරීමට බොත්තම ඔබාගෙන සිටින්න'
                            : 'Hold the button to speak',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  // Recording button
                  GestureDetector(
                    onLongPressStart: (_) => _toggleRecording(),
                    onLongPressEnd: (_) => _toggleRecording(),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _voiceService.isRecording ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _voiceService.isRecording
                                  ? Colors.red
                                  : const Color(0xFF2E7D32),
                              boxShadow: [
                                BoxShadow(
                                  color: (_voiceService.isRecording
                                          ? Colors.red
                                          : const Color(0xFF2E7D32))
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _voiceService.isRecording ? Icons.stop : Icons.mic,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Recording indicator
                  if (_voiceService.isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _language == 'si' ? 'පටිගත කරමින්...' : 'Recording...',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTranscriptBubble(VoiceTranscript transcript) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            transcript.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!transcript.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              radius: 16,
              child: Icon(
                _status == VoiceStatus.aiSpeaking ? Icons.volume_up : Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: transcript.isUser
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(transcript.isUser ? 20 : 5),
                  bottomRight: Radius.circular(transcript.isUser ? 5 : 20),
                ),
              ),
              child: Text(
                transcript.text,
                style: TextStyle(
                  color: transcript.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (transcript.isUser) ...[
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
