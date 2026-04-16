import 'dart:convert';

import 'package:genesis_util/features/inventory/domain/entities/inventory_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryRepository {
  InventoryRepository(this._prefs);
  final SharedPreferences _prefs;
  static const String _inventoryKey = 'genesis_inventory_list';

  List<InventoryItem> getInventory() {
    final inventoryJson = _prefs.getString(_inventoryKey);

    if (inventoryJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(inventoryJson) as List<dynamic>;
      return decoded
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      throw Exception('Data corruption detected in inventory: $e\n$stack');
    }
  }

  Future<void> saveInventory(List<InventoryItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_inventoryKey, encoded);
  }
}
