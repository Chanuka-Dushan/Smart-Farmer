import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class QRVerifyScreen extends StatefulWidget {
  const QRVerifyScreen({super.key});

  @override
  State<QRVerifyScreen> createState() => _QRVerifyScreenState();
}

class _QRVerifyScreenState extends State<QRVerifyScreen> {
  final ApiService _apiService = ApiService();

  bool scanned = false;
  bool _isVerifying = false;

  Future<void> verify(String token) async {
    setState(() => _isVerifying = true);

    try {
      final response = await _apiService.post(
        ApiConfig.verifyQr,
        body: {"qr_token": token},
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => _VerificationDialog(response: response),
      );
    } catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Verification Failed"),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          scanned = false;
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),

      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (scanned || _isVerifying || capture.barcodes.isEmpty) return;

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null) {
                scanned = true;
                verify(code);
              }
            },
          ),
          if (_isVerifying)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _VerificationDialog extends StatelessWidget {
  const _VerificationDialog({required this.response});

  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    final status = _text(response['status']);
    final metadata = _map(response['metadata']);
    final blockchainData = _map(response['blockchainData']);
    final history = _historyItems(response, blockchainData);

    return AlertDialog(
      title: const Text('Verification'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusBox(status, _text(response['message'])),
              const SizedBox(height: 12),
              if (metadata.isNotEmpty) ...[
                _sectionTitle('Part Metadata'),
                _detailRows(metadata),
                const SizedBox(height: 12),
              ],
              if (history.isNotEmpty) ...[
                _sectionTitle('Ownership History'),
                ...history.map(_historyCard),
                const SizedBox(height: 12),
              ],
              if (blockchainData.isNotEmpty) ...[
                _sectionTitle('Blockchain Data'),
                _detailRows(blockchainData),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _statusBox(String status, String message) {
    final isAuthentic = status.toUpperCase() == 'AUTHENTIC';
    final color = isAuthentic ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAuthentic ? Icons.verified_outlined : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.isEmpty ? 'UNKNOWN' : status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[const SizedBox(height: 6), Text(message)],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _detailRows(Map<String, dynamic> data) {
    final visibleEntries = data.entries.where((entry) {
      return entry.value is! Map && entry.value is! List;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          visibleEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      _label(entry.key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Text(_text(entry.value))),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _historyCard(dynamic item) {
    final data = _map(item);
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(_text(item)),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _detailRows(data),
    );
  }

  static List<dynamic> _historyItems(
    Map<String, dynamic> response,
    Map<String, dynamic> blockchainData,
  ) {
    for (final source in [response, blockchainData]) {
      for (final key in [
        'history',
        'ownershipHistory',
        'ownership_history',
        'transferHistory',
        'transfer_history',
        'transactions',
      ]) {
        final value = source[key];
        if (value is List && value.isNotEmpty) return value;
      }
    }
    return const [];
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _text(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  static String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^|\s)([a-z])'),
          (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
        );
  }
}
