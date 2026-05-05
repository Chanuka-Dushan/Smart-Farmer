import 'package:flutter/material.dart';

class InventoryOptimizationScreen extends StatelessWidget {
  InventoryOptimizationScreen({super.key});

  final Color primaryGreen = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Optimization"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InventoryMenuCard(
              title: "Demand Forecast",
              subtitle:
                  "Forecast next-month part demand using historical sales and exponential smoothing.",
              icon: Icons.show_chart,
              color: primaryGreen,
              onTap: () {
                Navigator.pushNamed(context, '/inventory-forecast');
              },
            ),
            const SizedBox(height: 16),
            _InventoryMenuCard(
              title: "Inventory Recommendations",
              subtitle:
                  "View reorder suggestions and compatible substitutes ranked by feedback.",
              icon: Icons.inventory_2_outlined,
              color: primaryGreen,
              onTap: () {
                Navigator.pushNamed(context, '/inventory-recommendations');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InventoryMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}