import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'scan_screen.dart';
import 'supplier_screen.dart';
import 'profile_screen.dart';
import 'shop_map_screen.dart';
import 'spare_part_scan_screen.dart';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'nlp_search_screen.dart';
import 'compatibility_screen.dart';
import 'inventory_optimization_screen.dart';
import 'lifecycle_prediction_screen.dart';
import 'upload_image_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _greeting = "";
  String _weatherTemp = "--";
  String _weatherDescription = "Loading weather...";
  String _locationName = "Detecting location...";
  IconData _weatherIcon = Icons.wb_cloudy_outlined;
  
  // Seller stats
  int _totalOffers = 0;
  int _activeRequests = 0;
  int _completedDeals = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
      _loadSellerStats();
    });
    _updateGreeting();
    _loadLocationAndWeather();
  }

  void _checkOnboarding() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isSeller && auth.seller != null && !auth.seller!.onboardingCompleted) {
      Navigator.pushReplacementNamed(context, '/seller-onboarding');
    }
  }
  
  Future<void> _loadSellerStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isSeller) return;
    
    try {
      final apiService = ApiService();
      // Fetch seller's offer count
      final offersResponse = await apiService.getMyOffers();
      if (offersResponse is List) {
        setState(() {
          _totalOffers = offersResponse.length;
          _completedDeals = offersResponse.where((o) => o['status'] == 'accepted').length;
        });
      }
      
      // Fetch active requests count
      final requestsResponse = await apiService.getSparePartRequests();
      if (requestsResponse is List) {
        setState(() {
          _activeRequests = requestsResponse.where((r) => r['status'] == 'active').length;
        });
      }
    } catch (e) {
      // Silently fail, keep default values
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      _greeting = "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      _greeting = "Good Evening";
    } else {
      _greeting = "Good Night";
    }
  }

  Future<void> _loadLocationAndWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationName = "Location denied";
            _weatherDescription = "Enable GPS";
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Explicitly request Celsius to avoid any region-based defaults
      final weatherResponse = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true&temperature_unit=celsius'));

      // Nominatim requires a User-Agent identifying the app
      final geoResponse = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10'),
        headers: {'User-Agent': 'SmartFarmerApp/1.0'},
      );

      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final current = weatherData['current_weather'];
        
        if (current != null) {
          final dynamic tempValue = current['temperature'];
          final int code = current['weathercode'] ?? 0;

          String desc;
          IconData icon;
          if (code == 0) { desc = "Clear Sky"; icon = Icons.wb_sunny_rounded; }
          else if (code <= 3) { desc = "Cloudy"; icon = Icons.wb_cloudy_rounded; }
          else if (code <= 67) { desc = "Rainy"; icon = Icons.umbrella_rounded; }
          else { desc = "Cloudy"; icon = Icons.cloud_rounded; }

          String cityName = "My Farm";
          if (geoResponse.statusCode == 200) {
            final geoData = json.decode(geoResponse.body);
            cityName = geoData['address']['city'] ?? geoData['address']['town'] ?? geoData['address']['village'] ?? "Nearby";
          }

          if (mounted) {
            setState(() {
              _weatherTemp = tempValue != null ? "${tempValue.round()}°C" : "--°C";
              _weatherDescription = desc;
              _weatherIcon = icon;
              _locationName = cityName;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
      if (mounted) {
        setState(() {
          _locationName = "Sri Lanka";
          _weatherDescription = "Weather error";
          _weatherTemp = "--°C";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('dashboard'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final String displayName = auth.isSeller ? (auth.seller?.businessName ?? "Store") : (auth.user?.fullName ?? "Farmer");
                final String email = auth.isSeller ? (auth.seller?.email ?? "") : (auth.user?.email ?? "");
                final String? picUrl = auth.isSeller ? auth.seller?.logoUrl : auth.user?.profilePictureUrl;
                
                // Debug logging
                print('🖼️ Profile picture URL: $picUrl');
                if (picUrl == null || picUrl.isEmpty) {
                  print('⚠️ No profile picture URL available');
                }
                
                return UserAccountsDrawerHeader(
                  accountName: Text(displayName),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: picUrl != null && picUrl.isNotEmpty
                      ? NetworkImage(
                          picUrl,
                          headers: {
                            'Cache-Control': 'no-cache',
                          },
                        ) as ImageProvider
                      : null,
                    child: picUrl == null || picUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF2E7D32))
                      : null,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            if (Provider.of<AuthProvider>(context, listen: false).isSeller) ...[
               ListTile(
                 leading: const Icon(Icons.list_alt_rounded),
                 title: const Text("Spare Part Requests"),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.pushNamed(context, '/seller-spare-part-requests');
                 },
               ),
            ] else ...[
               ListTile(
                 leading: const Icon(Icons.search_rounded),
                 title: const Text("Find a Spare Part"),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.pushNamed(context, '/find-spare-part');
                 },
               ),
               ListTile(
                 leading: const Icon(Icons.history_rounded),
                 title: const Text("My Requests"),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.pushNamed(context, '/my-spare-part-requests');
                 },
               ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),

          ],
        ),
      ),

          

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Greeting & Weather Section (Animated) ---
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_greeting,",
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              final name = auth.isSeller 
                                ? (auth.seller?.businessName ?? "Store") 
                                : (auth.user?.firstname ?? context.tr('hello_farmer'));
                              return Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(_weatherIcon, color: Colors.blueAccent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _weatherTemp,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        _locationName,
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.cloud_queue, size: 14, color: Colors.blueGrey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _weatherDescription,
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // --- Seller Stats ---
            if (Provider.of<AuthProvider>(context, listen: false).isSeller) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Active Requests",
                      value: _activeRequests.toString(),
                      icon: Icons.work_outline,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "My Offers",
                      value: _totalOffers.toString(),
                      icon: Icons.local_offer_outlined,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Completed",
                      value: _completedDeals.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Success Rate",
                      value: _totalOffers > 0 ? "${((_completedDeals / _totalOffers) * 100).toStringAsFixed(0)}%" : "0%",
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            
            // --- Feature Cards ---
            if (!Provider.of<AuthProvider>(context, listen: false).isSeller) ...[
            _buildAnimatedCard(
              index: 2,
              child: _buildFeatureCard(
                context,
                title: context.tr('scan_spare_part'),
                subtitle: context.tr('detect_wear_tear'),
                icon: Icons.document_scanner_rounded,
                color: Colors.blue.withOpacity(0.1),
                iconColor: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SparePartScanScreen())),
              ),
            ),

            _buildAnimatedCard(
              index: 3,
              child: _buildFeatureCard(
                context,
                title: context.tr('find_suppliers'),
                subtitle: context.tr('locate_verified_sellers'),
                icon: Icons.map_rounded,
                color: Colors.green.withOpacity(0.1),
                iconColor: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierScreen())),
              ),
            ),

            _buildAnimatedCard(
              index: 4,
              child: _buildFeatureCard(
                context,
                title: "My Reservations",
                subtitle: "View secure blockchain contracts",
                icon: Icons.vpn_key_rounded,
                color: Colors.purple.withOpacity(0.1),
                iconColor: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.tr('blockchain_coming_soon'))),
                  );
                },
              ),
            ),
            ], // Close the conditional for farmer features

             // ================= Identification Section =================
          const SizedBox(height: 20),
          const Text(
            "Identification",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            title: "Upload Spare Part Image",
            subtitle: "Identify and analyze parts",
            icon: Icons.upload_rounded,
            color: Colors.blue.shade100,
            iconColor: Colors.blue.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadImageScreen()),
              );
            },
          ),

          // ================= Smart Recommendation System =================
          const SizedBox(height: 20),
          const Text(
            "Smart Recommendation System",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            title: "NLP Spare Part Search",
            subtitle: "Search parts using natural language",
            icon: Icons.search,
            color: Colors.green.shade100,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NlpSearchScreen()),
              );
            },
          ),

          _buildFeatureCard(
            context,
            title: "Compatibility Recommender",
            subtitle: "Find alternative compatible parts",
            icon: Icons.sync_alt,
            color: Colors.teal.shade100,
            iconColor: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CompatibilityScreen()),
              );
            },
          ),

          _buildFeatureCard(
            context,
            title: "Inventory Optimization",
            subtitle: "Predict demand & optimize stock",
            icon: Icons.inventory_2,
            color: Colors.lime.shade100,
            iconColor: Colors.lime.shade800,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventoryOptimizationScreen()),
              );
            },
          ),
          
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SparePartScanScreen()))
                .then((_) => setState(() => _selectedIndex = 0));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
                .then((_) => setState(() => _selectedIndex = 0));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 150)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required Color iconColor,
      required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
