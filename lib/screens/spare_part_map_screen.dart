import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';


import '../services/api_service.dart';
import '../models/shop_location_model.dart';


class SparePartMapScreen extends StatefulWidget {
  final List<dynamic> offers;

  const SparePartMapScreen({super.key, required this.offers});

  @override
  State<SparePartMapScreen> createState() => _SparePartMapScreenState();
}

class _SparePartMapScreenState extends State<SparePartMapScreen> {
  LatLng? _currentPosition;
  List<Marker> _markers = [];
  dynamic _nearestOffer;
  double? _minDistance;
  List<ShopLocation> _allShops = [];
  bool _isLoadingShops = true;

  @override
  void initState() {
    super.initState();
    _loadLocationAndMarkers();
  }

  Future<void> _loadLocationAndMarkers() async {
    try {
      // Load all shop locations
      final shops = await ApiService().getShopLocations();
      setState(() {
        _allShops = shops;
        _isLoadingShops = false;
      });

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _calculateMarkers(position);
    } catch (e) {
      setState(() {
        _isLoadingShops = false;
      });
    }
  }

  void _calculateMarkers(Position currentPos) {
    List<Marker> markers = [];
    double? minDistance;
    dynamic nearestOffer;
    Set<int> offerSellerIds = {};

    // Add current location marker
    markers.add(
      Marker(
        point: LatLng(currentPos.latitude, currentPos.longitude),
        width: 80,
        height: 80,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
      ),
    );

    // First, add markers for sellers with offers
    for (var offer in widget.offers) {
      final seller = offer['seller'];
      if (seller != null &&
          seller['latitude'] != null &&
          seller['longitude'] != null) {
        final lat = double.tryParse(seller['latitude'].toString());
        final lng = double.tryParse(seller['longitude'].toString());
        final sellerId = seller['id'];

        if (lat != null && lng != null && sellerId != null) {
          offerSellerIds.add(sellerId);

          final distance = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            lat,
            lng,
          );

          if (minDistance == null || distance < minDistance) {
            minDistance = distance;
            nearestOffer = offer;
          }

          final status = offer['status'] ?? 'pending';
          final isAccepted = status == 'accepted';

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showOfferDetails(offer, distance),
                child: Icon(
                  isAccepted ? Icons.check_circle : Icons.store,
                  color: isAccepted ? Colors.green : Colors.orange,
                  size: 40,
                ),
              ),
            ),
          );
        }
      }
    }

    // Add markers for all other shops (without offers)
    for (var shop in _allShops) {
      // Skip if this shop already has an offer
      if (offerSellerIds.contains(shop.id)) continue;

      if (shop.lat != null && shop.lng != null) {
        markers.add(
          Marker(
            point: LatLng(shop.lat!, shop.lng!),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showShopDetails(shop),
              child: const Icon(
                Icons.location_on,
                color: Colors.grey,
                size: 40,
              ),
            ),
          ),
        );
      }
    }

    // Add a special marker for the nearest offer (if any)
    if (nearestOffer != null) {
      final seller = nearestOffer['seller'];
      final lat = double.parse(seller['latitude'].toString());
      final lng = double.parse(seller['longitude'].toString());

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 90,
          height: 90,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
            ),
            child: GestureDetector(
              onTap: () => _showOfferDetails(nearestOffer, minDistance!),
              child: const Icon(Icons.star, color: Colors.orange, size: 45),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _nearestOffer = nearestOffer;
      _minDistance = minDistance;
    });
  }

  void _showOfferDetails(dynamic offer, double distanceInMeters) {
    final seller = offer['seller'];
    final distanceKm = (distanceInMeters / 1000).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,

      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(seller['business_name'] ?? 'Store', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$distanceKm km away', style: const TextStyle(color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            Text('Price: ${offer['price']}', style: const TextStyle(fontSize: 18, color: Colors.orange)),
            Text(offer['description'] ?? ''),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),

      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        seller['business_name'] ?? 'Store',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '📍 ${distanceKm} km away',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 16,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('Offer Price: ', style: TextStyle(fontSize: 16)),
                    Text(
                      'LKR ${offer['price'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (offer['description'] != null &&
                    offer['description'].toString().isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        offer['status'] == 'accepted'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        offer['status'] == 'accepted'
                            ? Icons.check_circle
                            : Icons.pending,
                        color:
                            offer['status'] == 'accepted'
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${offer['status'] ?? 'pending'}',
                        style: TextStyle(
                          color:
                              offer['status'] == 'accepted'
                                  ? Colors.green
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],

            ),
          ),
    );
  }

  void _showShopDetails(ShopLocation shop) {
    if (_currentPosition == null) return;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      shop.lat!,
      shop.lng!,
    );
    final distanceKm = (distance / 1000).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.store_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.businessName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '📍 ${distanceKm} km away',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                if (shop.shopLocationName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${shop.shopLocationName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This shop has not submitted an offer yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shops & Offers'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body:
          _currentPosition == null || _isLoadingShops
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Legend
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem(
                          Icons.store,
                          Colors.orange,
                          'With Offer',
                        ),
                        _buildLegendItem(
                          Icons.check_circle,
                          Colors.green,
                          'Accepted',
                        ),
                        _buildLegendItem(
                          Icons.location_on,
                          Colors.grey,
                          'No Offer',
                        ),
                        _buildLegendItem(Icons.my_location, Colors.blue, 'You'),
                      ],
                    ),
                  ),
                  // Map
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.smart_farmer',
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          _nearestOffer != null
              ? FloatingActionButton.extended(
                onPressed: () {},
                label: Text(
                  'Nearest Offer: ${(_minDistance! / 1000).toStringAsFixed(1)}km',
                ),
                icon: const Icon(Icons.near_me),
                backgroundColor: Colors.orange,
              )
              : null,
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
