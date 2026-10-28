import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'APPEARANCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Dark theme'),
              subtitle: const Text('Use the charcoal calculator theme'),
              value: controller.isDarkTheme,
              onChanged: controller.setDarkTheme,
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const Divider(indent: 20, endIndent: 20),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'FEEDBACK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Haptic feedback'),
              subtitle: const Text('A subtle touch response for keypad taps'),
              value: controller.hapticsEnabled,
              onChanged: controller.setHapticsEnabled,
              secondary: const Icon(Icons.vibration_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
