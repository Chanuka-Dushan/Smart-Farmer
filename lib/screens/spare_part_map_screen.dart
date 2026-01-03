import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLocationAndMarkers();
  }

  Future<void> _loadLocationAndMarkers() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _calculateMarkers(position);
    } catch (e) {
      // Handle error
    }
  }

  void _calculateMarkers(Position currentPos) {
    List<Marker> markers = [];
    double? minDistance;
    dynamic nearestOffer;

    // Add current location marker
    markers.add(
      Marker(
        point: LatLng(currentPos.latitude, currentPos.longitude),
        width: 80, height: 80,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
      ),
    );

    for (var offer in widget.offers) {
      final seller = offer['seller'];
      if (seller != null && seller['latitude'] != null && seller['longitude'] != null) {
        final lat = double.tryParse(seller['latitude'].toString());
        final lng = double.tryParse(seller['longitude'].toString());

        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(
            currentPos.latitude, currentPos.longitude, lat, lng
          );

          if (minDistance == null || distance < minDistance) {
            minDistance = distance;
            nearestOffer = offer;
          }

          final status = offer['status'] ?? 'pending';
          final isApproved = status == 'approved';

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 80, height: 80,
              child: GestureDetector(
                onTap: () => _showOfferDetails(offer, distance),
                child: Icon(
                  isApproved ? Icons.check_circle : Icons.location_on,
                  color: isApproved ? Colors.green : Colors.red,
                  size: 40,
                ),
              ),
            )
          );
        }
      }
    }

    // Add a special marker for the nearest
    if (nearestOffer != null) {
       final seller = nearestOffer['seller'];
       final lat = double.parse(seller['latitude'].toString());
       final lng = double.parse(seller['longitude'].toString());
       
       markers.add(
         Marker(
           point: LatLng(lat, lng),
           width: 80, height: 80,
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
         )
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
        title: const Text('Stores Near You'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null 
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_farmer',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
      floatingActionButton: _nearestOffer != null 
        ? FloatingActionButton.extended(
            onPressed: () {},
            label: Text('Nearest Store: ${(_minDistance! / 1000).toStringAsFixed(1)}km'),
            icon: const Icon(Icons.near_me),
            backgroundColor: Colors.orange,
          )
        : null,
    );
  }
}
