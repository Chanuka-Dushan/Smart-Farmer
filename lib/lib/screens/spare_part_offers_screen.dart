import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
import '../config/app_config.dart';
import 'spare_part_map_screen.dart';

class SparePartOffersScreen extends StatefulWidget {
  final int requestId;
  final String requestTitle;

  const SparePartOffersScreen({super.key, required this.requestId, required this.requestTitle});

  @override
  State<SparePartOffersScreen> createState() => _SparePartOffersScreenState();
}

class _SparePartOffersScreenState extends State<SparePartOffersScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      final offers = await ApiService().getOffersForRequest(widget.requestId);
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int offerId, String status) async {
    try {
      // If accepting, show payment dialog FIRST, then accept after payment
      if (status == 'accepted') {
        if (!mounted) return;
        final offer = _offers.firstWhere((o) => o['id'] == offerId);
        final depositAmount = (offer['price'] as num) * 0.05;
        
        final shouldPay = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.payment, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text('Payment Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To complete your order, please pay a 5% deposit:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Order: LKR ${offer['price'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deposit (5%): LKR ${depositAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        
        if (shouldPay != true || !mounted) {
          // User cancelled payment
          return;
        }
        
        // Navigate to payment screen and wait for result
        final paymentResult = await Navigator.pushNamed(
          context,
          '/payment',
          arguments: {'offer_id': offerId, 'amount': depositAmount, 'total_amount': offer['price']},
        );
        
        // Payment confirmation already accepts the offer in the backend
        // Just refresh the offers list
        if (paymentResult == true && mounted) {
          _fetchOffers(); // Refresh to show updated status
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment completed and offer accepted!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Payment failed or cancelled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled. Offer not accepted.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // For reject, just update status
        await ApiService().updateOfferStatus(offerId, status);
        _fetchOffers(); // Refresh
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer $status')),
        );
      }
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.requestTitle),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_offers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SparePartMapScreen(offers: _offers)),
                );
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _offers.isEmpty 
          ? Center(child: Text(context.tr('no_offers_yet')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                final status = offer['status'] ?? 'pending';
                final seller = offer['seller'] as Map<String, dynamic>?;
                
                // Extract seller information from the offer data
                final sellerName = seller != null 
                    ? (seller['business_name'] ?? '${seller['owner_firstname'] ?? ''} ${seller['owner_lastname'] ?? ''}'.trim())
                    : 'Seller #${offer['seller_id'] ?? "Unknown"}';
                final sellerAddress = seller != null 
                    ? (seller['business_address'] ?? seller['shop_location_name'] ?? 'Contact for details')
                    : 'Contact for details';
                final sellerLogoUrl = seller != null ? seller['logo_url'] : null;
                
                return Card(
                   elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: sellerLogoUrl != null && sellerLogoUrl.toString().isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(AppConfig.getFullImageUrl(sellerLogoUrl)),
                                onBackgroundImageError: (_, __) {},
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: const Icon(Icons.store, color: Colors.green),
                              ),
                        title: Text(
                          sellerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(sellerAddress),
                        trailing: Text(
                          'LKR ${offer['price'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(offer['description'] ?? '', style: const TextStyle(fontSize: 14)),
                      ),
                      if (status == 'pending')
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateStatus(offer['id'], 'rejected'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(offer['id'], 'accepted'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Chip(
                            backgroundColor: status == 'approved' ? Colors.green[100] : Colors.red[100],
                            label: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: status == 'approved' ? Colors.green[900] : Colors.red[900]),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
