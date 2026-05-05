import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';

class BlockchainPartsScreen extends StatefulWidget {
  const BlockchainPartsScreen({super.key});

  @override
  State<BlockchainPartsScreen> createState() => _BlockchainPartsScreenState();
}

class _BlockchainPartsScreenState extends State<BlockchainPartsScreen> {
  List<Map<String, dynamic>> _parts = [];
  final Set<String> _registeringSerials = {};
  bool _isLoading = true;
  String? _error;

  String get _baseUrl =>
      AppConfig.apiBaseUrl.endsWith('/')
          ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
          : AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.getParts}/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load parts (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected parts response from server');
      }

      setState(() {
        _parts =
            decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerOnBlockchain(Map<String, dynamic> part) async {
    final serial = _text(part['serial_number']);

    if (serial.isEmpty) {
      _showSnack('Cannot register part without serial number');
      return;
    }

    setState(() {
      _registeringSerials.add(serial);
      _error = null;
    });

    final payload = {
      'serialNumber': serial,
      'partID': _text(part['part_id']),
      'blockchainID': 'BC-$serial',
      'manufacturer': _text(part['manufacturer']),
      'country': _text(part['country']),
      'owner': _text(part['current_owner']),
      'mintedAt': DateTime.now().toUtc().toIso8601String(),
      'refurbished': false,
      'txHash': 'INITIAL_REGISTRATION',
    };

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.blockchainRegister}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Blockchain registration failed (${response.statusCode})',
        );
      }

      if (!mounted) return;

      await _showQrDialog(serial, response.bodyBytes);
      await _loadParts();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _registeringSerials.remove(serial));
      }
    }
  }

  Future<void> _showQrDialog(String serial, Uint8List qrBytes) {
    return showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Registered in Blockchain'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Serial: $serial'),
                const SizedBox(height: 12),
                Image.memory(qrBytes, height: 220),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () => _downloadQr(serial, qrBytes),
                icon: const Icon(Icons.download),
                label: const Text('Download QR'),
              ),
            ],
          ),
    );
  }

  Future<void> _downloadQr(String serial, Uint8List qrBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName =
          '${serial.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}_qr.png';
      final file = XFile.fromData(
        qrBytes,
        name: fileName,
        mimeType: 'image/png',
      );

      final savedPath = '${directory.path}/$fileName';
      await file.saveTo(savedPath);

      await Share.shareXFiles([
        XFile(savedPath, mimeType: 'image/png', name: fileName),
      ], text: 'Blockchain QR for $serial');
    } catch (e) {
      _showSnack('Could not prepare QR download');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _text(dynamic value) => value?.toString() ?? '';

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Parts'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadParts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadParts, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_messageBox(_error!, Colors.red, Icons.error_outline)],
      );
    }

    if (_parts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'No metadata parts found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _parts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _partCard(_parts[index]),
    );
  }

  Widget _partCard(Map<String, dynamic> part) {
    final serial = _text(part['serial_number']);
    final partName =
        _text(part['part_name']).isEmpty
            ? 'Unnamed part'
            : _text(part['part_name']);
    final isBlockchainRegistered = _boolValue(part['blockchain_registered']);
    final isRegistering = _registeringSerials.contains(serial);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    partName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Serial', serial),
            _detailRow('Part ID', _text(part['part_id'])),
            _detailRow('Owner', _text(part['current_owner'])),
            _detailRow('Manufacturer', _text(part['manufacturer'])),
            if (_text(part['country']).isNotEmpty)
              _detailRow('Country', _text(part['country'])),
            const SizedBox(height: 12),
            if (isBlockchainRegistered)
              _messageBox(
                'Registered in Blockchain',
                Colors.green,
                Icons.verified_outlined,
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isRegistering ? null : () => _registerOnBlockchain(part),
                  icon:
                      isRegistering
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.add_link),
                  label: Text(
                    isRegistering
                        ? 'Registering on blockchain...'
                        : 'Register on Blockchain',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  Widget _messageBox(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
