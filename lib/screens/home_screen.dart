import 'package:flutter/material.dart';
import 'camera_scan_screen.dart';

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
        title: const Text("Smart Farmer Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications), // For WhatsApp alerts
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            const Text(
              "Hello, Farmer!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("Your machinery status is currently Good."),
            const SizedBox(height: 20),

            // 1. Predictive Analytics Card (Feature 1)
            _buildFeatureCard(
              context,
              title: "Lifespan Forecast",
              subtitle: "Check remaining hours for your parts",
              icon: Icons.timelapse,
              color: Colors.orange.shade100,
              iconColor: Colors.orange,
            ),
            
            // 2. Camera Scan Card (Feature 2)
            _buildFeatureCard(
              context,
              title: "Scan Spare Part",
              subtitle: "Detect wear & tear instantly",
              icon: Icons.camera_enhance,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
            ),

            // 3. Supplier Map Card (Feature 3)
            _buildFeatureCard(
              context,
              title: "Find Suppliers",
              subtitle: "Locate verified sellers nearby",
              icon: Icons.map,
              color: Colors.green.shade100,
              iconColor: Colors.green,
            ),
            
            // 4. Blockchain Card (Feature 4)
             _buildFeatureCard(
              context,
              title: "My Reservations",
              subtitle: "View secure blockchain contracts",
              icon: Icons.qr_code,
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
            ),
          ],
        ),
      ),
      
      // Bottom Navigation for easy access
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          // Navigate to camera when scan is clicked
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CameraScanScreen(),
              ),
            ).then((_) {
              // Reset to home after returning from camera
              setState(() {
                _selectedIndex = 0;
              });
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required Color iconColor}) {
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
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}