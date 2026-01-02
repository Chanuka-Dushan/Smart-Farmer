import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';
import '../services/api_service.dart';

// TODO: For production deployment, consider implementing:
// 1. Proper geocoding service (Google Maps Platform, Mapbox, or OpenStreetMap Nominatim)
// 2. Location validation and reverse geocoding
// 3. Offline map tiles for areas with poor connectivity
// 4. Location accuracy improvements
// 5. Privacy policy compliance for location data

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _shopLocationNameController = TextEditingController();
  final _searchController = TextEditingController();

  String _userType = 'buyer'; // 'buyer' or 'seller'
  bool _isSeller = false;
  late MapController _mapController;
  latlong.LatLng? _selectedLocation;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _shopLocationNameController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onUserTypeChanged(String? value) {
    setState(() {
      _userType = value!;
      _isSeller = value == 'seller';
      // Don't automatically get location - let user choose
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!_isSeller) return;

    setState(() => _isLocationLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Please enable location services in settings.')),
          );
        }
        setState(() => _isLocationLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _selectedLocation = latlong.LatLng(position.latitude, position.longitude);
          _isLocationLoading = false;
        });

        // Move map to current location
        _mapController.move(_selectedLocation!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLocationLoading = true);

    try {
      // TODO: Implement proper geocoding service for production
      // Consider using Google Maps Platform, Mapbox, or OpenStreetMap Nominatim API
      // Example: https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5
      // For now, using a local database of Sri Lankan locations

      // For production, implement proper geocoding API
      // For now, we'll use a more comprehensive location database
      final searchResults = [
        // Major cities in Sri Lanka
        {'name': 'Colombo', 'lat': 6.9271, 'lng': 79.8612},
        {'name': 'Kandy', 'lat': 7.2906, 'lng': 80.6337},
        {'name': 'Galle', 'lat': 6.0329, 'lng': 80.2168},
        {'name': 'Jaffna', 'lat': 9.6615, 'lng': 80.0255},
        {'name': 'Negombo', 'lat': 7.2083, 'lng': 79.8358},
        {'name': 'Anuradhapura', 'lat': 8.3114, 'lng': 80.4037},
        {'name': 'Trincomalee', 'lat': 8.5874, 'lng': 81.2152},
        {'name': 'Batticaloa', 'lat': 7.7300, 'lng': 81.6747},
        {'name': 'Matara', 'lat': 5.9549, 'lng': 80.5550},
        {'name': 'Kurunegala', 'lat': 7.4863, 'lng': 80.3628},
        // Popular locations in Colombo
        {'name': 'Colombo City Center', 'lat': 6.9271, 'lng': 79.8612},
        {'name': 'Pettah Market', 'lat': 6.9320, 'lng': 79.8547},
        {'name': 'Fort Railway Station', 'lat': 6.9328, 'lng': 79.8431},
        {'name': 'Liberty Plaza', 'lat': 6.9178, 'lng': 79.8547},
        {'name': 'Majestic City', 'lat': 6.9275, 'lng': 79.8433},
        {'name': 'Unity Plaza', 'lat': 6.9271, 'lng': 79.8612},
        {'name': 'Odel', 'lat': 6.9271, 'lng': 79.8612},
      ];

      // Find matching results (case-insensitive partial match)
      final matchingResults = searchResults.where(
        (location) => (location['name'] as String).toLowerCase().contains(query.toLowerCase()),
      ).toList();

      if (matchingResults.isNotEmpty) {
        final result = matchingResults.first;
        final newLocation = latlong.LatLng(result['lat'] as double, result['lng'] as double);

        if (mounted) {
          setState(() {
            _selectedLocation = newLocation;
            _shopLocationNameController.text = result['name'] as String;
            _isLocationLoading = false;
          });

          // Move map to searched location
          _mapController.move(newLocation, 16.0);
        }
      } else {
        // If no match found, show helpful message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not found in database. Try using "Current Location" or tap on the map to set your exact location.'),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _isLocationLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching location: $e')),
        );
      }
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSeller && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your shop location on the map')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_isSeller) {
      success = await authProvider.registerSeller(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessName: _businessNameController.text.trim(),
        ownerFirstname: _firstnameController.text.trim(),
        ownerLastname: _lastnameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty ? null : _businessAddressController.text.trim(),
        latitude: _selectedLocation?.latitude.toString(),
        longitude: _selectedLocation?.longitude.toString(),
        shopLocationName: _shopLocationNameController.text.trim().isEmpty ? null : _shopLocationNameController.text.trim(),
      );
    } else {
      success = await authProvider.register(
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('account_created')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.tr('registration_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('create_account'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // User Type Selection
                Text(
                  'I want to register as:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Buyer'),
                        value: 'buyer',
                        groupValue: _userType,
                        onChanged: _onUserTypeChanged,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Seller'),
                        value: 'seller',
                        groupValue: _userType,
                        onChanged: _onUserTypeChanged,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Basic Information
                TextFormField(
                  controller: _firstnameController,
                  decoration: InputDecoration(
                    labelText: '${context.tr('first_name')} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_first_name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastnameController,
                  decoration: InputDecoration(
                    labelText: '${context.tr('last_name')} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_last_name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '${context.tr('email')} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_email');
                    }
                    if (!value.contains('@')) {
                      return context.tr('please_enter_valid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '${context.tr('password')} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    helperText: context.tr('password_min_length'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_password');
                    }
                    if (value.length < 6) {
                      return context.tr('password_too_short');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '${context.tr('phone')} (${context.tr('optional')})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${context.tr('address')} (${context.tr('optional')})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),

                // Seller-specific fields
                if (_isSeller) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Business Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (_isSeller && (value == null || value.isEmpty)) {
                        return 'Please enter your business name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Business Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (_isSeller && (value == null || value.isEmpty)) {
                        return 'Please enter your business address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Shop Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search for your shop location or tap on the map to set it',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search bar for location
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for cities/towns in Sri Lanka (e.g., Colombo, Kandy, Galle)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLocationLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: _searchLocation,
                  ),

                  const SizedBox(height: 16),

                  // Shop location name
                  TextFormField(
                    controller: _shopLocationNameController,
                    decoration: const InputDecoration(
                      labelText: 'Shop Location Name *',
                      hintText: 'Enter a name for this location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (_isSeller && (value == null || value.isEmpty)) {
                        return 'Please enter a shop location name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Map for location selection
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isLocationLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation ?? const latlong.LatLng(7.8731, 80.7718), // Default to Sri Lanka center
                                initialZoom: _selectedLocation != null ? 16.0 : 8.0, // Zoom in if location selected, zoom out for country view
                                onTap: (tapPosition, point) {
                                  setState(() {
                                    _selectedLocation = point;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.smart_farmer',
                                  tileProvider: NetworkTileProvider(),
                                ),
                                if (_selectedLocation != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _selectedLocation!,
                                        width: 40,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedLocation != null
                              ? 'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                              : 'Tap on the map to set your shop location',
                          style: TextStyle(
                            fontSize: 12, 
                            color: _selectedLocation != null ? Colors.green : Colors.grey
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Use Current Location'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(context.tr('register')),
                          );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(context.tr('already_have_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}