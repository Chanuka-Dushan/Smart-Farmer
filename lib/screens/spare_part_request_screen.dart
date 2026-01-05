import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';

class SparePartRequestScreen extends StatefulWidget {
  const SparePartRequestScreen({super.key});

  @override
  State<SparePartRequestScreen> createState() => _SparePartRequestScreenState();
}

class _SparePartRequestScreenState extends State<SparePartRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String _selectedCategory = 'Engine Parts'; // Default category

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Store translations before async operations using listen: false
    final successMessage = context.l10n.tr('request_sent_success');

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      // Upload image first if exists, then create request with the image URL
      String? imageUrl;
      if (_image != null) {
        imageUrl = await apiService.uploadSparePartImage(_image!.path);
      }

      // Create request with image URL
      await apiService.createSparePartRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('find_spare_part')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('describe_part_header'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr('part_title'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('part_description'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                "Upload Image", // context.tr('upload_image')
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image: _image != null 
                      ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) 
                      : null,
                  ),
                  child: _image == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Add a photo of the part", style: TextStyle(color: Colors.grey)),
                        ],
                      ) 
                    : null,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(context.tr('send_request'), style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
