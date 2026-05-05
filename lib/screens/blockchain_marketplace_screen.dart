import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class BlockchainMarketplaceScreen extends StatefulWidget {
  const BlockchainMarketplaceScreen({super.key});

  @override
  State<BlockchainMarketplaceScreen> createState() =>
      _BlockchainMarketplaceScreenState();
}

class _BlockchainMarketplaceScreenState
    extends State<BlockchainMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _requestingSerials = {};
  List<Map<String, dynamic>> _parts = [];
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
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/parts/blockchain-registered'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load blockchain parts (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected parts response from server');
      }

      if (!mounted) return;
      setState(() {
        _parts =
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

  List<Map<String, dynamic>> get _filteredParts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _parts;

    return _parts.where((part) {
      return _text(part['serial_number']).toLowerCase().contains(query) ||
          _text(part['part_name']).toLowerCase().contains(query) ||
          _text(part['part_id']).toLowerCase().contains(query) ||
          _text(part['manufacturer']).toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _requestOwnership(Map<String, dynamic> part) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final buyerEmail = auth.user?.email.trim().toLowerCase() ?? '';
    final serial = _text(part['serial_number']);

    if (buyerEmail.isEmpty) {
      _showSnack('Login as a buyer before requesting ownership');
      return;
    }

    if (serial.isEmpty) {
      _showSnack('Cannot request ownership without serial number');
      return;
    }

    setState(() {
      _requestingSerials.add(serial);
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transfer/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'serialNumber': serial, 'buyer': buyerEmail}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final decoded = _tryDecodeMap(response.body);
        throw Exception(
          decoded['detail']?.toString() ??
              'Transfer request failed (${response.statusCode})',
        );
      }

      final decoded = _tryDecodeMap(response.body);
      if (!mounted) return;
      _showSnack(decoded['message']?.toString() ?? 'Transfer request sent');
      await _loadParts();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _requestingSerials.remove(serial));
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

  String _normalized(String value) => value.trim().toLowerCase();

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final buyerEmail = auth.user?.email.trim().toLowerCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ownership'),
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
      body: RefreshIndicator(
        onRefresh: _loadParts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search blockchain-registered parts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (buyerEmail.isNotEmpty)
              _messageBox(
                'Buyer: $buyerEmail',
                Colors.blue,
                Icons.person_outline,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _messageBox(_error!, Colors.red, Icons.error_outline),
            ],
            const SizedBox(height: 12),
            ..._buildPartList(buyerEmail),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPartList(String buyerEmail) {
    if (_isLoading) {
      return [
        const SizedBox(height: 120),
        const Center(child: CircularProgressIndicator()),
      ];
    }

    final parts = _filteredParts;
    if (parts.isEmpty) {
      return [
        const SizedBox(height: 80),
        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(child: Text('No blockchain-registered parts found')),
      ];
    }

    return [
      for (final part in parts) ...[
        _partCard(part, buyerEmail),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _partCard(Map<String, dynamic> part, String buyerEmail) {
    final serial = _text(part['serial_number']);
    final owner = _normalized(_text(part['current_owner']));
    final requestedBuyer = _normalized(_text(part['requested_new_owner']));
    final transferStatus = _text(part['transfer_status']);
    final isMine = buyerEmail.isNotEmpty && owner == buyerEmail;
    final alreadyRequested =
        transferStatus == 'PENDING' && requestedBuyer == buyerEmail;
    final isRequesting = _requestingSerials.contains(serial);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(part['part_name']).isEmpty
                  ? 'Unnamed part'
                  : _text(part['part_name']),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _detailRow('Serial', serial),
            _detailRow('Part ID', _text(part['part_id'])),
            _detailRow('Owner', owner),
            _detailRow('Manufacturer', _text(part['manufacturer'])),
            if (_text(part['country']).isNotEmpty)
              _detailRow('Country', _text(part['country'])),
            const SizedBox(height: 12),
            if (isMine)
              _messageBox(
                'You are the current owner',
                Colors.green,
                Icons.verified_user_outlined,
              )
            else if (alreadyRequested)
              _messageBox(
                'Ownership request already pending',
                Colors.orange,
                Icons.hourglass_top,
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isRequesting ? null : () => _requestOwnership(part),
                  icon:
                      isRequesting
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.swap_horiz),
                  label: Text(
                    isRequesting ? 'Sending request...' : 'Request Ownership',
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
