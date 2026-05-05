import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
import '../config/app_config.dart';

class MyOfferingsScreen extends StatefulWidget {
  const MyOfferingsScreen({super.key});

  @override
  State<MyOfferingsScreen> createState() => _MyOfferingsScreenState();
}

class _MyOfferingsScreenState extends State<MyOfferingsScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      final offers = await ApiService().getMyOffers();
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load offers: ${e.toString()}')),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offerings'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? const Center(child: Text('No offerings found'))
              : RefreshIndicator(
                  onRefresh: _fetchOffers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      final request = offer['request'];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Request image if available
                            if (request != null &&
                                request['image_url'] != null &&
                                request['image_url'].toString().isNotEmpty &&
                                !request['image_url'].toString().contains('placeholder'))
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                                child: Image.network(
                                  AppConfig.getFullImageUrl(request['image_url']),
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Request title
                                  if (request != null)
                                    Text(
                                      request['title'] ?? 'Untitled Request',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // Request description
                                  if (request != null && request['description'] != null)
                                    Text(
                                      request['description'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),

                                  const SizedBox(height: 12),

                                  // Offer details
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Offered: LKR ${offer['price']?.toString() ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Offer description
                                  if (offer['description'] != null && offer['description'].toString().isNotEmpty)
                                    Text(
                                      'Description: ${offer['description']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),

                                  const SizedBox(height: 12),

                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(offer['status'] ?? 'unknown').withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(offer['status'] ?? 'unknown'),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusText(offer['status'] ?? 'unknown'),
                                      style: TextStyle(
                                        color: _getStatusColor(offer['status'] ?? 'unknown'),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Date
                                  Text(
                                    'Offered on: ${_formatDate(offer['created_at'])}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
