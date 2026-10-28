import 'package:flutter/material.dart';

import '../../../core/utils/number_formatter.dart';
import '../../calculator/controllers/calculator_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.controller, super.key});

  final CalculatorController controller;
  static const NumberFormatter _formatter = NumberFormatter();

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all saved calculations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (shouldClear == true) await controller.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) => IconButton(
              tooltip: 'Clear history',
              onPressed: controller.history.isEmpty
                  ? null
                  : () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final entries = controller.history;
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 44),
                  SizedBox(height: 12),
                  Text('No calculations yet'),
                  SizedBox(height: 4),
                  Text('Completed calculations will appear here.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                minVerticalPadding: 12,
                title: Text(
                  entry.expression
                      .replaceAll('*', '×')
                      .replaceAll('/', '÷')
                      .replaceAll('-', '−'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _formatter.format(entry.result),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Delete calculation',
                  onPressed: () => controller.deleteHistoryEntry(entry.id),
                  icon: const Icon(Icons.delete_outline),
                ),
                onTap: () {
                  controller.restoreHistory(entry);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
