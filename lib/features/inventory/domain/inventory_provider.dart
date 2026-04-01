import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'inventory_model.dart';

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  static const _inventoryKey = 'genesis_inventory_list';

  @override
  List<InventoryItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final inventoryJson = prefs.getString(_inventoryKey);
    
    if (inventoryJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(inventoryJson);
      return decoded.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_inventoryKey, encoded);
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

final inventoryProvider = NotifierProvider<InventoryNotifier, List<InventoryItem>>(InventoryNotifier.new);
