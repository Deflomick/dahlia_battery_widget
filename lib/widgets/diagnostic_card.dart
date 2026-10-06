import 'package:flutter/material.dart';

/// Card che mostra i valori diagnostici in tempo reale della batteria.
class DiagnosticCard extends StatelessWidget {
  final String health;
  final double temp;
  final double voltage;
  final String technology;
  final bool isFahrenheit;

  const DiagnosticCard({
    super.key,
    required this.health,
    required this.temp,
    required this.voltage,
    required this.technology,
    required this.isFahrenheit,
  });

  @override
  Widget build(BuildContext context) {
    final double displayTemp = isFahrenheit ? (temp * 9 / 5) + 32 : temp;
    final String tempUnit = isFahrenheit ? "°F" : "°C";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Diagnostica Batteria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _diagnosticItem(
                  "Salute",
                  health,
                  Icons.favorite,
                  Colors.green,
                ),
                _diagnosticItem(
                  "Temperatura",
                  "${displayTemp.toStringAsFixed(1)}$tempUnit",
                  Icons.thermostat,
                  temp > 38 ? Colors.red : Colors.orange,
                ),
                _diagnosticItem(
                  "Voltaggio",
                  "${voltage.toStringAsFixed(2)} V",
                  Icons.electric_bolt,
                  Colors.amber,
                ),
                _diagnosticItem(
                  "Tecnologia",
                  technology,
                  Icons.memory,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagnosticItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
