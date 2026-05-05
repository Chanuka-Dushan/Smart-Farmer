import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class SellerPendingTransfersScreen extends StatefulWidget {
  const SellerPendingTransfersScreen({super.key});

  @override
  State<SellerPendingTransfersScreen> createState() =>
      _SellerPendingTransfersScreenState();
}

class _SellerPendingTransfersScreenState
    extends State<SellerPendingTransfersScreen> {
  final Set<String> _approvingSerials = {};
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  String get _baseUrl =>
      AppConfig.apiBaseUrl.endsWith('/')
          ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
          : AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  String _sellerEmail() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.seller?.email.trim().toLowerCase() ?? '';
  }

  Future<void> _loadPending() async {
    final sellerEmail = _sellerEmail();

    if (sellerEmail.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Login as a seller to view pending transfers';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final encodedSeller = Uri.encodeComponent(sellerEmail);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transfer/pending/$encodedSeller'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load pending transfers (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected pending transfers response');
      }

      if (!mounted) return;
      setState(() {
        _requests =
            decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    final serial = _text(request['serial_number']);
    final buyer = _text(request['requested_new_owner']).trim().toLowerCase();

    if (serial.isEmpty || buyer.isEmpty) {
      _showSnack('Missing serial number or buyer email');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve transfer?'),
            content: Text('Transfer $serial to $buyer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approve'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _approvingSerials.add(serial);
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/transfer/approve'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'serialNumber': serial, 'buyer': buyer}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final decoded = _tryDecodeMap(response.body);
        throw Exception(
          decoded['detail']?.toString() ??
              'Transfer approval failed (${response.statusCode})',
        );
      }

      final decoded = _tryDecodeMap(response.body);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Ownership transferred'),
              content: SelectableText(
                '${decoded['message'] ?? 'Ownership transferred successfully'}\n\n'
                'Serial: ${decoded['serialNumber'] ?? serial}\n'
                'New owner: ${decoded['newOwner'] ?? buyer}\n'
                'Tx hash: ${decoded['txHash'] ?? '-'}',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
      );

      await _loadPending();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _approvingSerials.remove(serial));
      }
    }
  }

  Map<String, dynamic> _tryDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String _text(dynamic value) => value?.toString() ?? '';

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sellerEmail =
        Provider.of<AuthProvider>(context).seller?.email.trim().toLowerCase() ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transfers'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPending,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPending,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (sellerEmail.isNotEmpty)
              _messageBox(
                'Seller: $sellerEmail',
                Colors.blue,
                Icons.storefront_outlined,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _messageBox(_error!, Colors.red, Icons.error_outline),
            ],
            const SizedBox(height: 12),
            ..._buildRequestList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRequestList() {
    if (_isLoading) {
      return [
        const SizedBox(height: 120),
        const Center(child: CircularProgressIndicator()),
      ];
    }

    if (_requests.isEmpty) {
      return [
        const SizedBox(height: 80),
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(child: Text('No pending transfer requests')),
      ];
    }

    return [
      for (final request in _requests) ...[
        _requestCard(request),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final serial = _text(request['serial_number']);
    final isApproving = _approvingSerials.contains(serial);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(request['part_name']).isEmpty
                  ? 'Unnamed part'
                  : _text(request['part_name']),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _detailRow('Serial', serial),
            _detailRow('Part ID', _text(request['part_id'])),
            _detailRow('Buyer', _text(request['requested_new_owner'])),
            _detailRow('Owner', _text(request['current_owner'])),
            _detailRow('Status', _text(request['transfer_status'])),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isApproving ? null : () => _approve(request),
                icon:
                    isApproving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_circle_outline),
                label: Text(
                  isApproving ? 'Approving on blockchain...' : 'Approve',
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
