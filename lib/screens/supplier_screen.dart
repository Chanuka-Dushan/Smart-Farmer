import 'package:flutter/material.dart';

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verified Suppliers"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.map)), // Map View Toggle
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SupplierCard(
            name: "Gampaha Agro Spares",
            distance: "2.5 km",
            rating: 4.8,
            status: "Verified",
          ),
          SupplierCard(
            name: "Lanka Tractors & Parts",
            distance: "5.1 km",
            rating: 4.2,
            status: "Verified",
          ),
          SupplierCard(
            name: "Rajarata Farm House",
            distance: "12.0 km",
            rating: 3.9,
            status: "Unverified",
          ),
        ],
      ),
    );
  }
}

class SupplierCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;
  final String status;

  const SupplierCard({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.status,
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
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("$distance away", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Verified Badge
                if (status == "Verified")
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.call, "Call", Colors.green),
                _buildActionButton(Icons.directions, "Directions", Colors.blue),
                _buildActionButton(Icons.star, rating.toString(), Colors.orange),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}