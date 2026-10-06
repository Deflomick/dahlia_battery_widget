import 'package:flutter/material.dart';

/// Card contenente le preferenze di configurazione dell'utente.
class SettingsCard extends StatelessWidget {
  final bool isFahrenheit;
  final bool enableGlow;
  final int alertThreshold;
  final int refreshIntervalSeconds;
  final ValueChanged<bool> onFahrenheitChanged;
  final ValueChanged<bool> onGlowChanged;
  final ValueChanged<int?> onAlertThresholdChanged;
  final ValueChanged<int?> onRefreshIntervalChanged;

  const SettingsCard({
    super.key,
    required this.isFahrenheit,
    required this.enableGlow,
    required this.alertThreshold,
    required this.refreshIntervalSeconds,
    required this.onFahrenheitChanged,
    required this.onGlowChanged,
    required this.onAlertThresholdChanged,
    required this.onRefreshIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.settings, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Impostazioni Personalizzate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),

            // Unità Temperatura
            SwitchListTile(
              title: const Text('Unità Temperatura in Fahrenheit'),
              subtitle: Text(
                isFahrenheit ? 'Visualizzato in °F' : 'Visualizzato in °C',
              ),
              secondary: const Icon(Icons.thermostat_auto),
              value: isFahrenheit,
              onChanged: onFahrenheitChanged,
            ),

            // Effetto Glow
            SwitchListTile(
              title: const Text('Effetto Glow (Alone Luminoso)'),
              subtitle: const Text('Mostra alone di luce attorno alla Dahlia'),
              secondary: const Icon(Icons.light_mode),
              value: enableGlow,
              onChanged: onGlowChanged,
            ),

            // Avviso Carica
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Notifica Carica Completata'),
              subtitle: Text(
                alertThreshold == 0
                    ? 'Disattivata'
                    : 'Avvisa quando raggiunge il $alertThreshold%',
              ),
              trailing: DropdownButton<int>(
                value: alertThreshold,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Disattivato')),
                  DropdownMenuItem(value: 80, child: Text('80%')),
                  DropdownMenuItem(value: 90, child: Text('90%')),
                  DropdownMenuItem(value: 100, child: Text('100%')),
                ],
                onChanged: onAlertThresholdChanged,
              ),
            ),

            // Frequenza Aggiornamento Background
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Frequenza Aggiornamento Service'),
              subtitle: Text('Controlla ogni $refreshIntervalSeconds secondi'),
              trailing: DropdownButton<int>(
                value: refreshIntervalSeconds,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 sec')),
                  DropdownMenuItem(value: 60, child: Text('1 min')),
                  DropdownMenuItem(value: 300, child: Text('5 min')),
                  DropdownMenuItem(value: 900, child: Text('15 min')),
                ],
                onChanged: onRefreshIntervalChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
