import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/vendor_provider.dart';
import '../domain/vendor_model.dart';
import '../../../core/utils/dialog_utils.dart';

class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allVendors = ref.watch(vendorPartnerProvider);
    final vendors = allVendors.where((v) => v.id != 'ronak_khristi_id').toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Vendor Partners', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: vendors.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text('No partners registered yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: vendors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final v = vendors[index];
                return _VendorCard(vendor: v);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendors/create'),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('New Partner'),
      ),
    );
  }
}

class _VendorCard extends ConsumerWidget {
  final VendorPartner vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () {}, // Maybe details later
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(vendor.name[0], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: () => context.push('/vendors/create', extra: vendor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await DialogUtils.showDeleteConfirmation(
                        context,
                        title: 'Remove Partner',
                        message: 'Are you sure you want to remove "${vendor.name}"? This will not affect existing documents.',
                      );
                      if (confirmed) {
                        ref.read(vendorPartnerProvider.notifier).deleteVendor(vendor.id);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text('Assigned Witnesses:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _WitnessPreview(name: vendor.witness1Name),
                  const SizedBox(width: 24),
                  _WitnessPreview(name: vendor.witness2Name),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WitnessPreview extends StatelessWidget {
  final String name;
  const _WitnessPreview({required this.name});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_pin_rounded, size: 14, color: Colors.blueGrey),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }
}
