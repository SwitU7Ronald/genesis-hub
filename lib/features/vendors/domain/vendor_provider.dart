import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'vendor_model.dart';

class VendorPartnerNotifier extends Notifier<List<VendorPartner>> {
  static const _vendorsKey = 'genesis_vendors_list';

  @override
  List<VendorPartner> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final vendorsJson = prefs.getString(_vendorsKey);
    
    final defaultVendors = [
      VendorPartner(
        id: 'ronak_khristi_id',
        name: 'RONAKKUMAR KHRISTI',
        witness1Name: 'RONAKKUMAR KHRISTI',
        witness2Name: 'HASMUKHBHAI KHRISTI',
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    if (vendorsJson == null) {
      return defaultVendors;
    }

    try {
      final List<dynamic> decoded = jsonDecode(vendorsJson);
      final list = decoded.map((e) => VendorPartner.fromJson(e as Map<String, dynamic>)).toList();
      
      // Ensure Ronak is always there even if we had previous data
      if (!list.any((v) => v.id == 'ronak_khristi_id')) {
        return [...defaultVendors, ...list];
      }
      return list;
    } catch (e) {
      // If data is incompatible, reset to defaults
      return defaultVendors;
    }
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_vendorsKey, encoded);
  }

  void addVendor(VendorPartner vendor) {
    state = [...state, vendor];
    _save();
  }

  void updateVendor(VendorPartner updatedVendor) {
    state = state.map((v) => v.id == updatedVendor.id ? updatedVendor : v).toList();
    _save();
  }

  void deleteVendor(String id) {
    state = state.where((v) => v.id != id).toList();
    _save();
  }
}

final vendorPartnerProvider = NotifierProvider<VendorPartnerNotifier, List<VendorPartner>>(VendorPartnerNotifier.new);
