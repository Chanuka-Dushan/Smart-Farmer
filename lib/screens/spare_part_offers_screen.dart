import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
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
      await ApiService().updateOfferStatus(offerId, status);
      _fetchOffers(); // Refresh
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer $status')),
      );
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
                final seller = offer['seller'] ?? {};
                final status = offer['status'] ?? 'pending';
                
                return Card(
                   elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          backgroundImage: seller['logo_url'] != null 
                            ? NetworkImage('${ApiService().baseUrl}${seller['logo_url']}')
                            : null,
                          child: seller['logo_url'] == null ? const Icon(Icons.store) : null,
                        ),
                        title: Text(seller['business_name'] ?? 'Unknown store', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(seller['business_address'] ?? 'No address provided'),
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
