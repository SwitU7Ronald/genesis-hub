import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/inventory_provider.dart';
import '../domain/inventory_model.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Inventory Control', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: inventory.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text('Inventory is empty.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: () => _showAddItemDialog(context, ref), icon: const Icon(Icons.add_rounded), label: const Text('Add First Item')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(_getIconForType(item.type), color: theme.colorScheme.primary),
                    title: Text('${item.brand} ${item.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Category: ${item.type.name.toUpperCase()}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Text('${item.stockCount} ${item.unit}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: inventory.isEmpty ? null : FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  IconData _getIconForType(InventoryType type) {
    switch (type) {
      case InventoryType.panel: return Icons.solar_power_rounded;
      case InventoryType.inverter: return Icons.electric_bolt_rounded;
      case InventoryType.cable: return Icons.cable_rounded;
      default: return Icons.conveyor_belt;
    }
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final countController = TextEditingController();
    InventoryType type = InventoryType.panel;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<InventoryType>(
              initialValue: type,
              items: InventoryType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(labelText: 'Item Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
            const SizedBox(height: 12),
            TextFormField(controller: modelController, decoration: const InputDecoration(labelText: 'Model Name')),
            const SizedBox(height: 12),
            TextFormField(controller: countController, decoration: const InputDecoration(labelText: 'Stock Count'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final item = InventoryItem(
                id: const Uuid().v4(),
                brand: brandController.text,
                model: modelController.text,
                type: type,
                stockCount: int.tryParse(countController.text) ?? 0,
                lastUpdated: DateTime.now(),
              );
              ref.read(inventoryProvider.notifier).addItem(item);
              Navigator.pop(ctx);
            }, 
            child: const Text('ADD TO STOCK')
          ),
        ],
      ),
    );
  }
}
