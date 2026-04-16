import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/core/providers/theme_provider.dart';
import 'package:genesis_util/features/inventory/data/repositories/inventory_repository.dart';
import 'package:genesis_util/features/inventory/domain/entities/inventory_item.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return InventoryRepository(prefs);
});

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() {
    return ref.watch(inventoryRepositoryProvider).getInventory();
  }

  Future<void> _save() async {
    try {
      await ref.read(inventoryRepositoryProvider).saveInventory(state);
    } catch (e, stackTrace) {
      log(
        'Critical Error: Failed to save inventory to local storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void addItem(InventoryItem item) {
    state = [...state, item];
    _save();
  }

  void updateItem(InventoryItem updatedItem) {
    state = state.map((i) => i.id == updatedItem.id ? updatedItem : i).toList();
    _save();
  }

  void deleteItem(String id) {
    state = state.where((i) => i.id != id).toList();
    _save();
  }
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, List<InventoryItem>>(
      InventoryNotifier.new,
    );
