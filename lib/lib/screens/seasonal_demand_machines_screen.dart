import 'package:flutter/material.dart';

class SeasonalMachineScreen extends StatelessWidget {
  const SeasonalMachineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("High Demand Machines"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _machines.map((machine) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.agriculture,
                  color: Color(0xFF2E7D32)),
              title: Text(machine),
              subtitle: const Text("Peak seasonal demand"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/inventory-details',
                  arguments: machine,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

final List<String> _machines = [
  "TAFE 45 DI",
  "John Deere 5045D",
  "Massey Ferguson 240",
  "Kubota L4508",
  "New Holland 3630",
];
