import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

/// Service for managing real-time voice chat with OpenAI Realtime API via WebSocket
class VoiceChatService {
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  String? _sessionId;
  bool _isConnected = false;
  bool _isRecording = false;
  bool _isSpeaking = false;
  
  final _transcriptController = StreamController<VoiceTranscript>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast();
  final _statusController = StreamController<VoiceStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Audio buffer for streaming
  final List<Uint8List> _audioBuffer = [];
  bool _isPlaying = false;
  
  Stream<VoiceTranscript> get transcriptStream => _transcriptController.stream;
  Stream<VoiceStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  bool get isSpeaking => _isSpeaking;
  String? get sessionId => _sessionId;
  
  /// Connect to voice chat WebSocket
  Future<bool> connect({
    required String damageType,
    required double confidence,
    required String severity,
    required double lifespanReduction,
    String language = 'si',
  }) async {
    try {
      // Get backend URL from environment
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
      
      final uri = Uri.parse('$wsUrl/ws/tyre/voice-chat').replace(
        queryParameters: {
          'damage_type': damageType,
          'confidence': confidence.toString(),
          'severity': severity,
          'lifespan_reduction': lifespanReduction.toString(),
          'language': language,
        },
      );
      
      debugPrint('🎤 Connecting to voice chat: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          _errorController.add('Connection error: $error');
          _isConnected = false;
          _statusController.add(VoiceStatus.disconnected);
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed');
          _isConnected = false;
          _statusController.add(VoiceStatus.disconnected);
        },
      );
      
      // Wait for connection (check if we receive session.ready)
      await Future.delayed(const Duration(seconds: 2));
      
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      _errorController.add('Failed to connect: $e');
      return false;
    }
  }
  
  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;
      
      debugPrint('📡 Received: $type');
      
      switch (type) {
        case 'session.ready':
          _sessionId = data['session_id'] as String?;
          _isConnected = true;
          _statusController.add(VoiceStatus.ready);
          debugPrint('✅ Session ready: $_sessionId');
          break;
          
        case 'audio':
          // AI speaking audio
          final audioBase64 = data['audio'] as String?;
          if (audioBase64 != null) {
            final audioBytes = base64Decode(audioBase64);
            _playAudioChunk(audioBytes);
          }
          break;
          
        case 'audio.done':
          // AI finished speaking
          _isSpeaking = false;
          _statusController.add(VoiceStatus.listening);
          debugPrint('🔊 AI finished speaking');
          break;
          
        case 'transcript':
          // Transcript (for display)
          final text = data['text'] as String?;
          final role = data['role'] as String?;
          if (text != null && role != null) {
            _transcriptController.add(VoiceTranscript(
              text: text,
              isUser: role == 'user',
              timestamp: DateTime.now(),
            ));
            debugPrint('📝 Transcript ($role): $text');
          }
          break;
          
        case 'response.done':
          // Complete response finished
          _statusController.add(VoiceStatus.listening);
          break;
          
        case 'error':
          final errorMsg = data['message'] as String? ?? 'Unknown error';
          _errorController.add(errorMsg);
          debugPrint('❌ Server error: $errorMsg');
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling message: $e');
    }
  }
  
  /// Start recording user voice
  Future<bool> startRecording() async {
    if (!_isConnected || _isRecording) return false;
    
    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        _errorController.add('Microphone permission denied');
        return false;
      }
      
      // Generate temporary file path
      final tempDir = Directory.systemTemp;
      final recordPath = path.join(
        tempDir.path,
        'voice_recording_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      
      // Start recording to file
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 24000,
          numChannels: 1,
        ),
        path: recordPath,
      );
      
      _isRecording = true;
      _statusController.add(VoiceStatus.speaking);
      debugPrint('🎤 Started recording');
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      _errorController.add('Failed to start recording: $e');
      return false;
    }
  }
  
  /// Stop recording and commit audio
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null && _channel != null) {
        // Read recorded audio and send to server
        final audioFile = File(path);
        if (await audioFile.exists()) {
          final audioBytes = await audioFile.readAsBytes();
          
          // Check if we have enough audio (WAV header is 44 bytes, need at least 100ms of audio)
          // At 24kHz, 16-bit mono: 24000 samples/sec * 2 bytes = 48000 bytes/sec
          // 100ms = 4800 bytes of audio data, + 44 bytes header = 4844 bytes minimum
          if (audioBytes.length < 4844) {
            debugPrint('⚠️ Audio too short (${audioBytes.length} bytes), not sending');
            _statusController.add(VoiceStatus.ready);
            return;
          }
          
          // Convert WAV to base64 and send
          final audioBase64 = base64Encode(audioBytes);
          _channel!.sink.add(jsonEncode({
            'type': 'audio',
            'audio': audioBase64,
          }));
          
          debugPrint('📤 Sent ${audioBytes.length} bytes of audio');
          
          // Signal end of speech
          _channel!.sink.add(jsonEncode({'type': 'audio_commit'}));
          
          // Delete temporary file
          await audioFile.delete();
        }
      }
      
      _statusController.add(VoiceStatus.processing);
      debugPrint('🎤 Stopped recording');
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
    }
  }
  
  /// Play audio chunk from AI
  void _playAudioChunk(Uint8List audioBytes) {
    _audioBuffer.add(audioBytes);
    
    if (!_isPlaying && !_isSpeaking) {
      _isSpeaking = true;
      _statusController.add(VoiceStatus.aiSpeaking);
      _processAudioBuffer();
    }
  }
  
  /// Process buffered audio chunks
  Future<void> _processAudioBuffer() async {
    _isPlaying = true;
    
    while (_audioBuffer.isNotEmpty) {
      final chunk = _audioBuffer.removeAt(0);
      
      // Convert PCM16 to playable format
      // Note: audioplayers doesn't support raw PCM directly
      // You may need to use a different player or convert to WAV
      // For now, we'll use a workaround with audio processing
      
      try {
        // Create temporary WAV file from PCM16
        final wavBytes = _convertPcmToWav(chunk);
        
        // Play the audio
        await _player.play(BytesSource(wavBytes));
        
        // Wait for playback to complete
        await Future.delayed(Duration(milliseconds: chunk.length ~/ 48)); // Rough estimate
      } catch (e) {
        debugPrint('❌ Audio playback error: $e');
      }
    }
    
    _isPlaying = false;
  }
  
  /// Convert PCM16 to WAV format
  Uint8List _convertPcmToWav(Uint8List pcm16Data) {
    // WAV file header for PCM16 at 24kHz mono
    final int sampleRate = 24000;
    final int numChannels = 1;
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcm16Data.length;
    final int fileSize = 44 + dataSize;
    
    final header = ByteData(44);
    
    // RIFF chunk
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, fileSize - 8, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    
    // fmt chunk
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // Chunk size
    header.setUint16(20, 1, Endian.little); // Audio format (PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    
    // data chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataSize, Endian.little);
    
    // Combine header and PCM data
    final wavBuffer = Uint8List(fileSize);
    wavBuffer.setRange(0, 44, header.buffer.asUint8List());
    wavBuffer.setRange(44, fileSize, pcm16Data);
    
    return wavBuffer;
  }
  
  /// Send text message (fallback)
  void sendTextMessage(String text) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'type': 'text',
      'text': text,
    }));
    
    _transcriptController.add(VoiceTranscript(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Disconnect and cleanup
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting voice chat');
    
    if (_isRecording) {
      await stopRecording();
    }
    
    await _player.stop();
    await _recorder.dispose();
    
    _channel?.sink.close();
    _channel = null;
    
    _isConnected = false;
    _sessionId = null;
    
    _statusController.add(VoiceStatus.disconnected);
  }
  
  /// Dispose all resources
  void dispose() {
    disconnect();
    _transcriptController.close();
    _audioController.close();
    _statusController.close();
    _errorController.close();
  }
}

/// Voice transcript model
class VoiceTranscript {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  VoiceTranscript({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Voice chat status
enum VoiceStatus {
  disconnected,
  connecting,
  ready,
  listening,
  speaking,
  processing,
  aiSpeaking,
  error,
}
