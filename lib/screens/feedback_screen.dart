import 'package:flutter/material.dart';
import '../services/compatibility_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String? _selectedFeedback;
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit({
    required int queryPartId,
    required int recommendedPartId,
  }) async {
    if (_selectedFeedback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Accept or Reject')),
      );
      return;
    }

    if (_selectedFeedback == 'reject' &&
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for rejection')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await CompatibilityService.submitFeedback(
        queryPartId: queryPartId,
        recommendedPartId: recommendedPartId,
        feedback: _selectedFeedback!,
        reason: _selectedFeedback == 'reject'
            ? _reasonController.text.trim()
            : null,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Feedback Submitted'),
          content: Text(
            result['message'] ?? 'Your feedback has been saved successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      String displayMessage = message;
      if (message.contains('already submitted feedback')) {
        displayMessage = 'You already submitted feedback';
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Feedback not allowed'),
          content: Text(
            displayMessage.isEmpty
                ? 'You already submitted feedback'
                : displayMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int queryPartId = args['queryPartId'];
    final int recommendedPartId = args['recommendedPartId'];
    final String queryPartName = args['queryPartName'] ?? '';
    final String recommendedPartName = args['recommendedPartName'] ?? '';

    const themeGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Feedback'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback for recommendation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text('Original Part: $queryPartName'),
                const SizedBox(height: 4),
                Text('Recommended Alternative: $recommendedPartName'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RadioListTile<String>(
            value: 'accept',
            groupValue: _selectedFeedback,
            activeColor: themeGreen,
            title: const Text('Accept'),
            subtitle: const Text('This alternative looks suitable'),
            onChanged: (value) => setState(() => _selectedFeedback = value),
          ),
          RadioListTile<String>(
            value: 'reject',
            groupValue: _selectedFeedback,
            activeColor: themeGreen,
            title: const Text('Reject'),
            subtitle: const Text('This alternative is not suitable'),
            onChanged: (value) => setState(() => _selectedFeedback = value),
          ),
          if (_selectedFeedback == 'reject') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Explain why this alternative is not suitable',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _submit(
                        queryPartId: queryPartId,
                        recommendedPartId: recommendedPartId,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting...' : 'Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}