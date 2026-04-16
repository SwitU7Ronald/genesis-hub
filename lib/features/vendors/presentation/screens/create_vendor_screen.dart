import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/features/vendors/domain/entities/vendor.dart';
import 'package:genesis_util/features/vendors/domain/providers/vendor_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class CreateVendorScreen extends ConsumerStatefulWidget {
  const CreateVendorScreen({super.key, this.existingVendor});
  final Vendor? existingVendor;

  @override
  ConsumerState<CreateVendorScreen> createState() => _CreateVendorScreenState();
}

class _CreateVendorScreenState extends ConsumerState<CreateVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _w1NameController;
  late final TextEditingController _w2NameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingVendor?.name);
    _w1NameController = TextEditingController(
      text: widget.existingVendor?.witness1Name,
    );
    _w2NameController = TextEditingController(
      text: widget.existingVendor?.witness2Name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _w1NameController.dispose();
    _w2NameController.dispose();
    super.dispose();
  }

  void _saveVendor() {
    if (_formKey.currentState!.validate()) {
      final vendor = Vendor(
        id: widget.existingVendor?.id ?? const Uuid().v4(),
        name: _nameController.text.toUpperCase(),
        witness1Name: _w1NameController.text.toUpperCase(),
        witness2Name: _w2NameController.text.toUpperCase(),
        createdAt: widget.existingVendor?.createdAt ?? DateTime.now(),
      );

      if (widget.existingVendor != null) {
        ref.read(vendorsProvider.notifier).updateVendor(vendor);
      } else {
        ref.read(vendorsProvider.notifier).addVendor(vendor);
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingVendor != null ? 'Edit Vendor' : 'Register Vendor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Vendor Identity', Icons.business_rounded),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name (e.g. DIPAK CHOKSI)',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
                textCapitalization: TextCapitalization.characters,
              ),

              const SizedBox(height: 48),
              _buildSectionHeader(
                'Legal Witnesses',
                Icons.verified_user_rounded,
              ),
              Text(
                'Witnesses must be available for signing the NP agreement.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildWitnessCard(1, _w1NameController),
              const SizedBox(height: 16),
              _buildWitnessCard(2, _w2NameController),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveVendor,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  'SAVE VENDOR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWitnessCard(int index, TextEditingController name) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Witness $index Full Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surface,
                hintText: 'Enter full name...',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Witness name required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
