import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class AcceptedOrdersScreen extends StatefulWidget {
  final int requestId;

  const AcceptedOrdersScreen({super.key, required this.requestId});

  @override
  State<AcceptedOrdersScreen> createState() => _AcceptedOrdersScreenState();
}

class _AcceptedOrdersScreenState extends State<AcceptedOrdersScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _request;
  List<dynamic> _offers = [];
  Map<String, dynamic>? _acceptedOffer;
  Map<String, dynamic>? _payment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load request details
      final requests = await _apiService.getMySparePartRequests();
      _request = requests.firstWhere((req) => req['id'] == widget.requestId);

      // Load offers
      _offers = await _apiService.getOffersForRequest(widget.requestId);
      try {
        _acceptedOffer = _offers.firstWhere(
          (offer) => offer['status'] == 'accepted',
        );
      } catch (e) {
        _acceptedOffer = null;
      }

      // Load payment if offer is accepted
      if (_acceptedOffer != null) {
        try {
          final payments = await _apiService.getMyPayments();
          try {
            _payment = payments.firstWhere(
              (payment) => payment['offer_id'] == _acceptedOffer!['id'],
            );
          } catch (e) {
            _payment = null;
          }
        } catch (e) {
          // Payment might not exist yet
          _payment = null;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load order details: $e')),
        );
      }
    }
  }

  Future<void> _generateAndSharePDF() async {
    if (_request == null || _acceptedOffer == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdf = pw.Document();

      final seller = _acceptedOffer!['seller'] ?? {};
      final payment = _payment ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Order Confirmation',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Order #${_request!['id']}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Details
              pw.Text(
                'Order Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFRow('Request Title', _request!['title'] ?? 'N/A'),
                    _buildPDFRow('Description', _request!['description'] ?? 'N/A'),
                    _buildPDFRow('Order Date', _formatDate(_request!['created_at'])),
                    _buildPDFRow('Status', 'COMPLETED'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Seller Information
              pw.Text(
                'Seller Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFRow('Business Name', seller['business_name'] ?? 'N/A'),
                    _buildPDFRow('Owner', '${seller['owner_firstname'] ?? ''} ${seller['owner_lastname'] ?? ''}'.trim()),
                    _buildPDFRow('Address', seller['business_address'] ?? seller['shop_location_name'] ?? 'N/A'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Offer Details
              pw.Text(
                'Offer Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFRow('Offer Description', _acceptedOffer!['description'] ?? 'N/A'),
                    _buildPDFRow('Total Amount', 'LKR ${(_acceptedOffer!['price'] as num).toStringAsFixed(2)}'),
                    if (payment.isNotEmpty) ...[
                      _buildPDFRow('Deposit Paid (5%)', 'LKR ${(payment['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildPDFRow('Payment Status', payment['status']?.toUpperCase() ?? 'PENDING'),
                      if (payment['stripe_charge_id'] != null)
                        _buildPDFRow('Transaction ID', payment['stripe_charge_id']),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you for your order!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ];
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/order_${_request!['id']}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Share PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Order Confirmation - Order #${_request!['id']}',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': $value'),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    if (_acceptedOffer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No accepted offer found for this request',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final seller = _acceptedOffer?['seller'] ?? {};
    final payment = _payment ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Order'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateAndSharePDF,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Accepted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Order #${_request!['id']}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Request Details
            _buildSectionCard(
              'Request Details',
              Icons.description,
              [
                _buildDetailRow('Title', _request!['title'] ?? 'N/A'),
                _buildDetailRow('Description', _request!['description'] ?? 'N/A'),
                _buildDetailRow('Date', _formatDate(_request!['created_at'])),
              ],
            ),
            const SizedBox(height: 16),

            // Seller Information
            _buildSectionCard(
              'Seller Information',
              Icons.store,
              [
                _buildDetailRow('Business Name', seller['business_name'] ?? 'N/A'),
                _buildDetailRow('Owner', '${seller['owner_firstname'] ?? ''} ${seller['owner_lastname'] ?? ''}'.trim()),
                _buildDetailRow('Address', seller['business_address'] ?? seller['shop_location_name'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),

            // Offer Details
            if (_acceptedOffer != null)
              _buildSectionCard(
                'Offer Details',
                Icons.local_offer,
                [
                  _buildDetailRow('Description', _acceptedOffer!['description'] ?? 'N/A'),
                  _buildDetailRow('Total Amount', 'LKR ${(_acceptedOffer!['price'] as num).toStringAsFixed(2)}'),
                ],
              ),
            const SizedBox(height: 16),

            // Payment Information
            if (payment.isNotEmpty)
              _buildSectionCard(
                'Payment Information',
                Icons.payment,
                [
                  _buildDetailRow('Deposit (5%)', 'LKR ${(payment['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow('Payment Status', payment['status']?.toUpperCase() ?? 'PENDING'),
                  if (payment['stripe_charge_id'] != null)
                    _buildDetailRow('Transaction ID', payment['stripe_charge_id']),
                  _buildDetailRow('Payment Date', _formatDate(payment['created_at'])),
                ],
              ),
            const SizedBox(height: 20),

            // Download PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateAndSharePDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Order PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

