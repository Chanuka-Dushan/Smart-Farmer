import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/shop_location_model.dart';

class ShopMapScreen extends StatefulWidget {
  const ShopMapScreen({super.key});

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<ShopLocation> _shops = [];
  bool _isLoading = true;
  bool _showListView = false;
  latlong.LatLng? _currentLocation;
  ShopLocation? _selectedShop;

  @override
  void initState() {
    super.initState();
    _loadShopLocations();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentLocation = latlong.LatLng(position.latitude, position.longitude);
        });

        // Move map to current location if it's the first time
        if (_markers.isEmpty) {
          _mapController.move(_currentLocation!, 13.0);
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  Future<void> _loadShopLocations() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final locations = await apiService.getShopLocations();

      print('📍 Loaded ${locations.length} shop locations');
      for (var shop in locations) {
        print('   - ${shop.businessName} at (${shop.lat}, ${shop.lng})');
      }

      setState(() {
        _shops = locations;
        _markers = locations.map((shop) {
          return Marker(
            point: latlong.LatLng(shop.lat, shop.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showShopDetails(shop),
              child: const Icon(
                Icons.store,
                color: Colors.green,
                size: 40,
              ),
            ),
          );
        }).toList();
      });

      // Move map to show all markers if available
      if (locations.isNotEmpty && mounted) {
        final firstShop = locations.first;
        _mapController.move(latlong.LatLng(firstShop.lat, firstShop.lng), 10.0);
      }
    } catch (e) {
      print('❌ Error loading shop locations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading shop locations: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showShopDetails(ShopLocation shop) {
    setState(() => _selectedShop = shop);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.green, size: 28),
                const SizedBox(width: 12),
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
            const Divider(height: 24),
            if (shop.shopLocationName != null && shop.shopLocationName!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.shopLocationName!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (shop.businessAddress != null && shop.businessAddress!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.home, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.businessAddress!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.phoneNumber!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (shop.businessDescription != null && shop.businessDescription!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.businessDescription!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '${shop.lat.toStringAsFixed(6)}, ${shop.lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _mapController.move(latlong.LatLng(shop.lat, shop.lng), 16.0);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                if (shop.phoneNumber != null && shop.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement call functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Call ${shop.phoneNumber}')),
                        );
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
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
        title: const Text('Shop Locations'),
        actions: [
          IconButton(
            icon: Icon(_showListView ? Icons.map : Icons.list),
            onPressed: () {
              setState(() => _showListView = !_showListView);
            },
            tooltip: _showListView ? 'Show map' : 'Show list',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShopLocations,
            tooltip: 'Refresh locations',
          ),
        ],
      ),
      body: _showListView ? _buildListView() : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const latlong.LatLng(6.9271, 79.8612), // Default to Colombo
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_farmer',
              ),
              MarkerLayer(
                markers: _markers,
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Current location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 15.0);
                } else {
                  _getCurrentLocation();
                }
              },
              tooltip: 'Go to my location',
              child: const Icon(Icons.my_location),
            ),
          ),

          // Shop count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_markers.length} shops',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildListView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_shops.isEmpty) return const Center(child: Text('No shops found'));
    return ListView.builder(itemCount: _shops.length, itemBuilder: (ctx, i) => ListTile(title: Text(_shops[i].businessName), onTap: () => _showShopDetails(_shops[i])));
  }
}
