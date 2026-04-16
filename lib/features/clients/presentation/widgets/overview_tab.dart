import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genesis_util/core/widgets/app_card.dart';
import 'package:genesis_util/core/widgets/stat_row.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:url_launcher/url_launcher.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    required this.client,
    required this.isWide,
    required this.onEditContact,
    required this.onEditUtilityIDs,
    required this.onEditSystemDNA,
    required this.onEditVendor,
    super.key,
  });
  final Client client;
  final bool isWide;
  final VoidCallback onEditContact;
  final VoidCallback onEditUtilityIDs;
  final VoidCallback onEditSystemDNA;
  final VoidCallback onEditVendor;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied $label to clipboard')));
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  Future<void> _openMap(
    BuildContext context,
    String address,
    double? lat,
    double? lng,
  ) async {
    Uri launchUri;
    if (lat != null && lng != null) {
      launchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      launchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
    }

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelCapacity = client.panelConfigs.fold<double>(
      0,
      (sum, config) => sum + (config.capacityW * config.count) / 1000.0,
    );
    final totalCapacity = panelCapacity > 0
        ? panelCapacity
        : client.systemSizeKwp;
    final invertersStr = client.inverterConfigs
        .map((c) => '${c.brand} ${c.capacityKw}kW (x${c.count})')
        .join(', ');
    final panelsStr = client.panelConfigs
        .map((c) => '${c.brand} ${c.capacityW}W (x${c.count})')
        .join(', ');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildContactCard(context),
                          const SizedBox(height: 24),
                          _buildVendorCard(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildSystemDNACard(
                            context,
                            totalCapacity,
                            invertersStr,
                            panelsStr,
                          ),
                          const SizedBox(height: 24),
                          _buildUtilityCard(context),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildContactCard(context),
                  const SizedBox(height: 24),
                  _buildSystemDNACard(
                    context,
                    totalCapacity,
                    invertersStr,
                    panelsStr,
                  ),
                  const SizedBox(height: 24),
                  _buildUtilityCard(context),
                  const SizedBox(height: 24),
                  _buildVendorCard(context),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context) {
    return AppCard(
      title: 'Vendor Assignment',
      icon: Icons.business_center_rounded,
      action: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 20),
        onPressed: onEditVendor,
        tooltip: 'Change Vendor',
      ),
      child: StatRow(
        label: 'ASSIGNED PARTNER',
        value: client.vendorName,
        isHero: true,
        icon: Icons.verified_rounded,
      ),
    );
  }

  Widget _buildSystemDNACard(
    BuildContext context,
    double totalCapacity,
    String inverters,
    String panels,
  ) {
    return AppCard(
      title: 'System DNA',
      icon: Icons.solar_power_rounded,
      action: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 20),
        onPressed: onEditSystemDNA,
        tooltip: 'Edit System DNA',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(
            label: 'TOTAL CAPACITY',
            value: '${totalCapacity.toStringAsFixed(2)} kWp',
            isHero: true,
          ),
          if (panels.isNotEmpty)
            StatRow(label: 'PANEL CONFIGURATION', value: panels),
          if (inverters.isNotEmpty)
            StatRow(label: 'INVERTER CONFIGURATION', value: inverters),
          if (panels.isEmpty && inverters.isEmpty)
            Text(
              'No detailed hardware configuration assigned yet.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context) {
    return AppCard(
      title: 'Utility Identifiers',
      icon: Icons.electric_meter_rounded,
      action: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 20),
        onPressed: onEditUtilityIDs,
        tooltip: 'Edit Utility IDs',
      ),
      child: Column(
        children: [
          StatRow(
            label: 'CONSUMER NUMBER',
            value: client.consumerNumber,
            isHero: true,
            onCopy: () => _copyToClipboard(
              context,
              client.consumerNumber,
              'Consumer Number',
            ),
          ),
          if ((client.npApplicationNumber ?? '').isNotEmpty)
            StatRow(
              label: 'NP PORTAL ID',
              value: client.npApplicationNumber ?? 'N/A',
              onCopy: () => _copyToClipboard(
                context,
                client.npApplicationNumber ?? 'N/A',
                'NP Portal ID',
              ),
            )
          else
            const StatRow(
              label: 'NP PORTAL ID',
              value: 'Not assigned',
              isSecondary: true,
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return AppCard(
      title: 'Location & Contact',
      icon: Icons.contact_mail_rounded,
      action: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 20),
        onPressed: onEditContact,
        tooltip: 'Edit Contact Details',
      ),
      child: Column(
        children: [
          StatRow(
            label: 'CLIENT NAME',
            value: client.name,
            icon: Icons.person_rounded,
            onCopy: () => _copyToClipboard(context, client.name, 'Name'),
          ),
          StatRow(
            label: 'PHONE NUMBER',
            value: client.phone,
            icon: Icons.phone_rounded,
            onCopy: () => _copyToClipboard(context, client.phone, 'Phone'),
            onAction: () => _makePhoneCall(context, client.phone),
            actionIcon: Icons.call_rounded,
          ),
          StatRow(
            label: 'SITE ADDRESS',
            value: client.address,
            icon: Icons.location_on_rounded,
            onCopy: () => _copyToClipboard(context, client.address, 'Address'),
            onAction: () => _openMap(
              context,
              client.address,
              client.latitude,
              client.longitude,
            ),
            actionIcon: Icons.map_rounded,
            isSecondary: true,
          ),
          if (client.latitude != null && client.longitude != null)
            Row(
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS: ${client.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${client.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
