import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
import 'spare_part_offers_screen.dart';

class MySparePartRequestsScreen extends StatefulWidget {
  const MySparePartRequestsScreen({super.key});

  @override
  State<MySparePartRequestsScreen> createState() => _MySparePartRequestsScreenState();
}

class _MySparePartRequestsScreenState extends State<MySparePartRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await ApiService().getMySparePartRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_spare_part_requests')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _requests.isEmpty 
          ? Center(child: Text(context.tr('no_requests_found')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                final status = req['status'] ?? 'pending';
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: req['image_url'] != null && req['image_url'].toString().isNotEmpty && !req['image_url'].toString().contains('placeholder')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            req['image_url'].startsWith('http') 
                              ? req['image_url'] 
                              : '${ApiService().baseUrl}${req['image_url']}',
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.image_not_supported, color: Colors.white),
                            ),
                          ),
                        )
                      : const CircleAvatar(child: Icon(Icons.settings_suggest)),
                    title: Text(req['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(req['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => SparePartOffersScreen(requestId: req['id'], requestTitle: req['title']),
                        )
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
