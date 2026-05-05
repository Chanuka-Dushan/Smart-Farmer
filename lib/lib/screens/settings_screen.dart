import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';
import '../services/theme_service.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _profileImagePath;
  String selectedLanguage = 'en';
  bool _isEditing = false;
  
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
    {'code': 'si', 'name': 'Sinhala', 'nativeName': 'සිංහල', 'flag': '🇱🇰'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇱🇰'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load from AuthProvider if user is logged in
      if (authProvider.isAuthenticated) {
        if (authProvider.isSeller && authProvider.seller != null) {
          _nameController.text = authProvider.seller!.businessName;
          _emailController.text = authProvider.seller!.email;
          _phoneController.text = authProvider.seller!.phoneNumber ?? '';
          _profileImagePath = authProvider.seller!.logoUrl;
        } else if (authProvider.user != null) {
          _nameController.text = authProvider.user!.fullName;
          _emailController.text = authProvider.user!.email;
          _phoneController.text = authProvider.user!.phoneNumber ?? '';
          _profileImagePath = authProvider.user!.profilePictureUrl;
        }
      } else {
        // Fallback to SharedPreferences
        _nameController.text = prefs.getString('user_name') ?? '';
        _emailController.text = prefs.getString('user_email') ?? '';
        _phoneController.text = prefs.getString('user_phone') ?? '';
        _profileImagePath = prefs.getString('profile_image_path');
      }
      
      selectedLanguage = prefs.getString('selected_language') ?? 'en';
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString('user_phone', _phoneController.text);
    await prefs.setString('selected_language', selectedLanguage);
    await context.l10n.setLanguage(selectedLanguage);
    
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    }
    
    setState(() => _isEditing = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.tr('profile_updated'))),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.tr('take_photo')),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() => _profileImagePath = image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('choose_from_gallery')),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => _profileImagePath = image.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('select_language_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              value: lang['code']!,
              groupValue: selectedLanguage,
              title: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(lang['nativeName']!),
                ],
              ),
              onChanged: (value) async {
                setState(() => selectedLanguage = value!);
                await context.l10n.setLanguage(value!);
                Navigator.pop(dialogContext);
                // UI will auto-refresh via Provider
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveUserData,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Photo Section
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.2),
                      child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                          ? ClipOval(
                              child: _profileImagePath!.startsWith('http')
                                  ? Image.network(
                                      _profileImagePath!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
                                    )
                                  : Image.file(
                                      File(_profileImagePath!),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
                                    ),
                            )
                          : const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
                    ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // User Data Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('profile_information'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: context.tr('full_name'),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: context.tr('email'),
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: context.tr('phone_number'),
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Language Selection Section
                  Text(
                    context.tr('language'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Text(
                        languages.firstWhere((l) => l['code'] == selectedLanguage)['flag']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        languages.firstWhere((l) => l['code'] == selectedLanguage)['nativeName']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        languages.firstWhere((l) => l['code'] == selectedLanguage)['name']!,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showLanguageDialog,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Additional Settings
                  Text(
                    context.tr('app_settings'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications, color: Color(0xFF2E7D32)),
                          title: Text(context.tr('notifications')),
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.dark_mode, color: Color(0xFF2E7D32)),
                          title: Text(context.tr('dark_mode')),
                          trailing: Switch(
                            value: Provider.of<ThemeService>(context).isDarkMode,
                            onChanged: (value) {
                              Provider.of<ThemeService>(context, listen: false).toggleTheme();
                            },
                            activeColor: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(context.tr('logout')),
                            content: Text(context.tr('logout_confirm')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(context.tr('cancel')),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: Text(context.tr('logout'), style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.tr('logout'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
