import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SellerPaymentsScreen extends StatefulWidget {
  const SellerPaymentsScreen({super.key});

  @override
  State<SellerPaymentsScreen> createState() => _SellerPaymentsScreenState();
}

class _SellerPaymentsScreenState extends State<SellerPaymentsScreen> {
  final _apiService = ApiService();
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      final payments = await _apiService.getSellerPayments();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Payments'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? const Center(
                  child: Text('No approved payments found'),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      final offer = payment['offer'] ?? {};
                      final user = payment['user'] ?? {};

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['email'] ?? 'No email',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Deposit Received:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'LKR ${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Order:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'LKR ${payment['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (offer['description'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Description: ${offer['description']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Payment Date: ${payment['created_at'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}



