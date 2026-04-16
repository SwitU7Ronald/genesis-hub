import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/core/providers/theme_provider.dart';
import 'package:genesis_util/features/vendors/data/repositories/vendor_repository.dart';
import 'package:genesis_util/features/vendors/domain/entities/vendor.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VendorRepository(prefs);
});

class VendorsNotifier extends Notifier<List<Vendor>> {
  @override
  List<Vendor> build() {
    return ref.watch(vendorRepositoryProvider).getVendors();
  }

  Future<void> _save() async {
    try {
      await ref.read(vendorRepositoryProvider).saveVendors(state);
    } catch (e, stackTrace) {
      log(
        'Critical Error: Failed to save vendors to local storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void addVendor(Vendor vendor) {
    state = [...state, vendor];
    _save();
  }

  void updateVendor(Vendor updatedVendor) {
    state = state
        .map((v) => v.id == updatedVendor.id ? updatedVendor : v)
        .toList();
    _save();
  }

  void deleteVendor(String id) {
    state = state.where((v) => v.id != id).toList();
    _save();
  }
}

final vendorsProvider = NotifierProvider<VendorsNotifier, List<Vendor>>(
  VendorsNotifier.new,
);
