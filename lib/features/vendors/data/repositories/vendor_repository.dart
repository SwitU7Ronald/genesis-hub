import 'dart:convert';

import 'package:genesis_util/features/vendors/domain/entities/vendor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorRepository {
  VendorRepository(this._prefs);
  final SharedPreferences _prefs;
  static const String _vendorsKey = 'genesis_vendors_list';

  List<Vendor> getVendors() {
    final vendorsJson = _prefs.getString(_vendorsKey);

    final defaultVendors = [
      Vendor(
        id: 'ronak_khristi_id',
        name: 'RONAKKUMAR KHRISTI',
        witness1Name: 'RONAKKUMAR KHRISTI',
        witness2Name: 'HASMUKHBHAI KHRISTI',
        createdAt: DateTime(2024),
      ),
    ];

    if (vendorsJson == null) {
      return defaultVendors;
    }

    try {
      final List<dynamic> decoded = jsonDecode(vendorsJson) as List<dynamic>;
      final list = decoded
          .map((e) => Vendor.fromJson(e as Map<String, dynamic>))
          .toList();

      // Ensure specific default vendor is always present
      if (!list.any((v) => v.id == 'ronak_khristi_id')) {
        return [...defaultVendors, ...list];
      }
      return list;
    } catch (e, stack) {
      throw Exception('Data corruption detected in vendors: $e\n$stack');
    }
  }

  Future<void> saveVendors(List<Vendor> vendors) async {
    final encoded = jsonEncode(vendors.map((e) => e.toJson()).toList());
    await _prefs.setString(_vendorsKey, encoded);
  }
}
