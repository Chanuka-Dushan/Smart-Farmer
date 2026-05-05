import 'package:flutter/material.dart';
import '../models/compatibility_models.dart';
import '../services/compatibility_service.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final TextEditingController _partController = TextEditingController();

  List<String> _machineModels = [];
  String? _selectedMachineModel;
  bool _loadingModels = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadMachineModels();
  }

  Future<void> _loadMachineModels() async {
    try {
      final models = await CompatibilityService.fetchMachineModels();
      setState(() {
        _machineModels = models;
        _loadingModels = false;
      });
    } catch (e) {
      setState(() => _loadingModels = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load machine models: $e')),
      );
    }
  }

  @override
  void dispose() {
    _partController.dispose();
    super.dispose();
  }

  Future<void> _findAlternatives() async {
    final partText = _partController.text.trim();

    if (_selectedMachineModel == null || _selectedMachineModel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a machine model')),
      );
      return;
    }

    if (partText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a spare part name')),
      );
      return;
    }

    setState(() => _searching = true);

    try {
      final ResolvedPart resolvedPart = await CompatibilityService.resolvePart(
        machineModel: _selectedMachineModel!,
        partText: partText,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/alternative-parts',
        arguments: {
          'partId': resolvedPart.id,
          'partName': resolvedPart.name,
          'machineModel': resolvedPart.machineModel,
        },
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Not found'),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
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
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Compatibility Recommender'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: _loadingModels
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find an alternative part',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select a machine model and enter the spare part name to find the best compatible alternatives.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedMachineModel,
                  decoration: InputDecoration(
                    labelText: 'Machine Model',
                    prefixIcon: const Icon(Icons.agriculture),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _machineModels
                      .map(
                        (model) => DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedMachineModel = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _partController,
                  decoration: InputDecoration(
                    labelText: 'Spare Part Name',
                    hintText: 'e.g. Fuel Filter',
                    prefixIcon: const Icon(Icons.build),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _searching ? null : _findAlternatives,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_searching ? 'Searching...' : 'Find Alternatives'),
                  ),
                ),
              ],
            ),
    );
  }
}