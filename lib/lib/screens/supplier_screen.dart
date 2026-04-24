import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/shop_location_model.dart';
import 'shop_map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final ApiService _apiService = ApiService();
  List<ShopLocation> _shops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Fetching shop locations from API...');
      final shops = await _apiService.getShopLocations();
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
        print('📍 Loaded ${shops.length} shops');
        if (shops.isEmpty) {
          print('⚠️ No shops returned from API. Check backend /api/sellers/locations endpoint');
        } else {
          print('✅ Shop names: ${shops.map((s) => s.businessName).join(", ")}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load suppliers: $e';
          _isLoading = false;
        });
        print('❌ Error loading shops: $e');
        print('🔧 Troubleshooting: Check if backend is running and sellers are verified/active');
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verified Suppliers"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopMapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            tooltip: 'View on Map',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShops,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shops.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No suppliers found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shops.length,
        itemBuilder: (context, index) {
          final shop = _shops[index];
          return SupplierCard(
            shop: shop,
            onCall: () => _makePhoneCall(shop.phoneNumber ?? ''),
          );
        },
      ),
    );
  }
}

class SupplierCard extends StatelessWidget {
  final ShopLocation shop;
  final VoidCallback onCall;

  const SupplierCard({
    super.key,
    required this.shop,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Supplier Icon
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: const Icon(Icons.store, color: Colors.green),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (shop.shopLocationName != null && shop.shopLocationName!.isNotEmpty)
                        Text(
                          shop.shopLocationName!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                // Verified Badge
                const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ),
            if (shop.businessAddress != null && shop.businessAddress!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shop.businessAddress!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (shop.businessDescription != null && shop.businessDescription!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shop.businessDescription!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty)
                  _buildActionButton(
                    Icons.call,
                    "Call",
                    Colors.green,
                    onCall,
                  ),
                _buildActionButton(
                  Icons.location_on,
                  "${shop.lat.toStringAsFixed(2)}, ${shop.lng.toStringAsFixed(2)}",
                  Colors.blue,
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback? onTap) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: content,
    );
  }
}