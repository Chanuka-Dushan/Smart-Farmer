import 'package:flutter/material.dart';
import 'predict_screen.dart';
import 'scan_screen.dart';
import 'supplier_screen.dart';
import 'profile_screen.dart';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';

import 'nlp_search_screen.dart';
import 'compatibility_screen.dart';
import 'inventory_optimization_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('no_new_notifications'))),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              context.tr('hello_farmer'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(context.tr('machinery_status_good')),
            const SizedBox(height: 20),

            // 1. Predictive Analytics
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PredictScreen()),
                );
              },
              child: _buildFeatureCard(
                context,
                title: context.tr('lifespan_forecast'),
                subtitle: context.tr('check_remaining_hours'),
                icon: Icons.timelapse,
                color: Colors.orange.shade100,
                iconColor: Colors.orange,
              ),
            ),

            // 2. Camera Scan
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              child: _buildFeatureCard(
                context,
                title: context.tr('scan_spare_part'),
                subtitle: context.tr('detect_wear_tear'),
                icon: Icons.camera_enhance,
                color: Colors.blue.shade100,
                iconColor: Colors.blue,
              ),
            ),

            // 3. Supplier Map
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupplierScreen()),
                );
              },
              child: _buildFeatureCard(
                context,
                title: context.tr('find_suppliers'),
                subtitle: context.tr('locate_verified_sellers'),
                icon: Icons.map,
                color: Colors.green.shade100,
                iconColor: Colors.green,
              ),
            ),

            // 4. Blockchain (existing)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('blockchain_coming_soon')),
                  ),
                );
              },
              child: _buildFeatureCard(
                context,
                title: "My Reservations",
                subtitle: "View secure blockchain contracts",
                icon: Icons.qr_code,
                color: Colors.purple.shade100,
                iconColor: Colors.purple,
              ),
            ),

            // ================= YOUR SECTION =================
            const SizedBox(height: 20),
            const Text(
              "Smart Recommendation System",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // NLP Spare Part Search
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NlpSearchScreen(),
                  ),
                );
              },
              child: _buildFeatureCard(
                context,
                title: "NLP Spare Part Search",
                subtitle: "Search parts using natural language",
                icon: Icons.search,
                color: Colors.green.shade100,
                iconColor: Colors.green,
              ),
            ),

            // Compatibility Recommender
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompatibilityScreen(),
                  ),
                );
              },
              child: _buildFeatureCard(
                context,
                title: "Compatibility Recommender",
                subtitle: "Find alternative compatible parts",
                icon: Icons.sync_alt,
                color: Colors.teal.shade100,
                iconColor: Colors.teal,
              ),
            ),

            // Inventory Optimization
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryOptimizationScreen(),
                  ),
                );
              },
              child: _buildFeatureCard(
                context,
                title: "Inventory Optimization",
                subtitle: "Predict demand & optimize stock",
                icon: Icons.inventory_2,
                color: Colors.lime.shade100,
                iconColor: Colors.lime.shade800,
              ),
            ),
          ],
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
