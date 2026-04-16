import 'package:flutter/material.dart';
import 'package:genesis_util/core/widgets/app_card.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';

class HardwareTab extends StatelessWidget {
  const HardwareTab({
    required this.client,
    required this.isWide,
    required this.currentPanelSerials,
    required this.currentInverterSerials,
    required this.onScanPanel,
    required this.onScanInverter,
    required this.onAddPanelManually,
    required this.onAddInverterManually,
    required this.onRemovePanel,
    required this.onRemoveInverter,
    required this.onClearPanels,
    required this.onClearInverters,
    super.key,
  });
  final Client client;
  final bool isWide;
  final List<String> currentPanelSerials;
  final List<String> currentInverterSerials;
  final VoidCallback onScanPanel;
  final VoidCallback onScanInverter;
  final VoidCallback onAddPanelManually;
  final VoidCallback onAddInverterManually;
  final Function(int) onRemovePanel;
  final Function(int) onRemoveInverter;
  final VoidCallback onClearPanels;
  final VoidCallback onClearInverters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildHardwareList(
                        context,
                        title: 'Solar Panels',
                        icon: Icons.solar_power_rounded,
                        serials: currentPanelSerials,
                        onScan: onScanPanel,
                        onManual: onAddPanelManually,
                        onRemove: onRemovePanel,
                        onClear: onClearPanels,
                        emptyText:
                            'Scan panel QR codes during installation to register their warranty.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildHardwareList(
                        context,
                        title: 'Inverters',
                        icon: Icons.electrical_services_rounded,
                        serials: currentInverterSerials,
                        onScan: onScanInverter,
                        onManual: onAddInverterManually,
                        onRemove: onRemoveInverter,
                        onClear: onClearInverters,
                        emptyText:
                            'Scan inverter QR codes or enter MAC addresses manually.',
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildHardwareList(
                    context,
                    title: 'Solar Panels',
                    icon: Icons.solar_power_rounded,
                    serials: currentPanelSerials,
                    onScan: onScanPanel,
                    onManual: onAddPanelManually,
                    onRemove: onRemovePanel,
                    onClear: onClearPanels,
                    emptyText:
                        'Scan panel QR codes during installation to register their warranty.',
                  ),
                  const SizedBox(height: 24),
                  _buildHardwareList(
                    context,
                    title: 'Inverters',
                    icon: Icons.electrical_services_rounded,
                    serials: currentInverterSerials,
                    onScan: onScanInverter,
                    onManual: onAddInverterManually,
                    onRemove: onRemoveInverter,
                    onClear: onClearInverters,
                    emptyText:
                        'Scan inverter QR codes or enter MAC addresses manually.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareList(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> serials,
    required VoidCallback onScan,
    required VoidCallback onManual,
    required Function(int) onRemove,
    required VoidCallback onClear,
    required String emptyText,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      title: title,
      icon: icon,
      padding: EdgeInsets.zero,
      action: serials.isNotEmpty
          ? TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManual,
                    icon: const Icon(Icons.keyboard_alt_rounded),
                    label: const Text('Type'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (serials.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: serials.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    serials[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => onRemove(index),
                    tooltip: 'Remove',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
