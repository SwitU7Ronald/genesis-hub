import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../domain/models.dart';
import '../domain/client_provider.dart';
import '../../vendors/domain/vendor_provider.dart';
import '../../scanner/domain/scanner_provider.dart';
import '../../documents/domain/docx_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import '../../../core/services/geo_camera_service.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/utils/currency_formatter.dart';

class ClientDetailsScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends ConsumerState<ClientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, List<String>> _panelBrandData = {
    'Waaree': ['Elite N-Type', 'BiN (Bifacial)', 'Arka', 'Mono PERC', 'Custom Series'],
    'Adani': ['Elan Series', 'Mono PERC Bifacial', 'Nexa', 'Custom Series'],
    'Custom (Other Brand)': ['Standard Module', 'Custom Model'],
  };

  static const Map<String, List<String>> _inverterBrandData = {
    'Polycab': ['PSGM Series', 'Hybrid', 'Custom Model'],
    'Solaryaan': ['Residential On-Grid', 'Hybrid', 'Custom Model'],
    'Custom (Other Brand)': ['On-Grid', 'Hybrid', 'Off-Grid', 'Custom Model'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- BUSINESS LOGIC RESTORED ---

  Future<void> _handlePreviewOrDownload(Client client, ClientDocument doc) async {
    if (doc.type == DocumentType.agreement || doc.type == DocumentType.selfCertificate || doc.type == DocumentType.quotation) {
      List<int>? bytes;
      if (doc.type == DocumentType.agreement) {
        bytes = await DocxGenerator.createAgreement(client);
      } else if (doc.type == DocumentType.selfCertificate) {
        final panels = ref.read(panelSerialsProvider);
        final inverters = ref.read(inverterSerialsProvider);
        bytes = await DocxGenerator.createSelfCertificate(client, panels, inverters);
      } else if (doc.type == DocumentType.quotation) {
        bytes = await DocxGenerator.createQuotation(client);
      }
      
      if (bytes != null) {
        await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: doc.fileName.replaceAll(' ', '_'));
      }
    } else {
      final result = await OpenFilex.open(doc.fileUrl);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
      }
    }
  }

  Future<void> _pickDocument(Client client, DocumentType type, String docName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      final doc = ClientDocument(
        id: uuid.v4(),
        clientId: client.id,
        type: type,
        fileName: result.files.single.name,
        fileUrl: result.files.single.path ?? 'cloud_placeholder',
        uploadedAt: DateTime.now(),
      );
      ref.read(documentsProvider.notifier).addDocument(doc);
    }
  }

  Future<void> _generateAgreement(Client client) async {
    try {
      final bytes = await DocxGenerator.createAgreement(client);
      if (bytes == null) return;
      
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'Agreement_${client.name}.docx');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('✅ Agreement generated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text('❌ Error: $e')));
    }
  }

  Future<void> _scanDocument(Client client, DocumentType type) async {
    try {
      final result = await FlutterDocScanner().getScanDocuments();
      if (result != null && result is List && result.isNotEmpty) {
        final filePath = result.first as String;
        final doc = ClientDocument(
          id: uuid.v4(),
          clientId: client.id,
          type: type,
          fileName: '${type.name.toUpperCase()}_SCAN_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileUrl: filePath,
          uploadedAt: DateTime.now(),
        );
        ref.read(documentsProvider.notifier).addDocument(doc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('✅ Document scanned and saved!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('❌ Scan Error: $e')));
      }
    }
  }

  Future<void> _captureGeoPhoto(Client client, DocumentType type, String label) async {
    try {
      // 1. Professional Permission Check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      // 2. Fetch High-Accuracy Coordinates
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      // 3. System Camera Interface
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 95);
      
      if (photo != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🏷️ Processing Professional GPS Tag...')));
        }
        
        // 4. Reverse Geocoding
        final address = await GeoCameraService.getAddress(position.latitude, position.longitude);
        
        // 5. Watermarking
        final watermarkedFile = await GeoCameraService.applyWatermark(
          imageFile: File(photo.path),
          position: position,
          address: address,
        );

        final fileName = '${type.name.toUpperCase()}_GPS_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final doc = ClientDocument(
          id: uuid.v4(),
          clientId: client.id,
          type: type,
          fileName: fileName,
          fileUrl: watermarkedFile.path,
          uploadedAt: DateTime.now(),
        );
        ref.read(documentsProvider.notifier).addDocument(doc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('✅ Professional GPS photo saved!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('❌ Geo-capture Error: $e')));
      }
    }
  }

  Future<void> _generateSelfCertificate(Client client) async {
    try {
      final panels = ref.read(panelSerialsProvider);
      final inverters = ref.read(inverterSerialsProvider);
      
      final bytes = await DocxGenerator.createSelfCertificate(client, panels, inverters);
      if (bytes == null) return;

      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'SelfCertificate_${client.name}.docx');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('✅ Self Certificate generated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text('❌ Error: $e')));
    }
  }

  Future<void> _generateQuotation(Client client) async {
    try {
      final bytes = await DocxGenerator.createQuotation(client);
      if (bytes == null) return;

      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'Quotation_${client.name}.docx');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('✅ Quotation generated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('❌ Error: $e')));
    }
  }

  Future<void> _scanHardware(bool isPanel) async {
    final scannedValue = await context.push<String>('/scanner');
    if (scannedValue != null && scannedValue.isNotEmpty) {
       if (isPanel) {
        ref.read(panelSerialsProvider.notifier).add(scannedValue);
      } else {
        ref.read(inverterSerialsProvider.notifier).add(scannedValue);
      }
    }
  }

  Future<void> _launchMap(String address) async {
    final query = Uri.encodeComponent(address);
    final Uri appleMapsUri = Uri.parse('https://maps.apple.com/?q=$query');
    final Uri googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(appleMapsUri)) {
      await launchUrl(appleMapsUri);
    } else if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    }
  }

  Future<void> _showEditFinancialsDialog(Client client) async {
    final costController = TextEditingController(text: CurrencyFormatter.formatINR(client.solarCostRs));
    final depositController = TextEditingController(text: CurrencyFormatter.formatINR(client.initialDepositRs));
    bool isSubsidy = client.isSubsidy;
    bool isLoan = client.isLoan;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Project Economics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 24),
              TextField(
                controller: costController,
                onChanged: (v) {
                  final numeric = v.replaceAll(',', '');
                  if (numeric.isEmpty) {
                    costController.text = '';
                    setModalState(() {});
                    return;
                  }
                  final formatted = CurrencyFormatter.formatINR(numeric);
                  if (v != formatted) {
                    costController.value = costController.value.copyWith(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  setModalState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Total Solar Plant Quotation (₹)', 
                  prefixIcon: Icon(Icons.solar_power_rounded),
                  helperText: 'Enter the final price quoted to the client.',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Strategic Logic Preview
              if (CurrencyFormatter.parseINR(costController.text) > 0 && isLoan) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Strategic Loan Cap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            '₹${CurrencyFormatter.formatINR(
                              (CurrencyFormatter.parseINR(costController.text) * 0.9 < 198000) 
                              ? (CurrencyFormatter.parseINR(costController.text) * 0.9) 
                              : 198000
                            )}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Advised Direct Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            '₹${CurrencyFormatter.formatINR(
                              CurrencyFormatter.parseINR(costController.text) - 
                              ((CurrencyFormatter.parseINR(costController.text) * 0.9 < 198000) 
                               ? (CurrencyFormatter.parseINR(costController.text) * 0.9) 
                               : 198000)
                            )}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        (CurrencyFormatter.parseINR(costController.text) * 0.9 > 198000)
                          ? 'Strategic Advice: By capping the loan at ₹1.98L, the client stays in the 5-6% interest bracket.'
                          : 'Optimal: The loan amount is naturally below the ₹1.98L threshold for best interest rates.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SwitchListTile(
                title: const Text('Government Subsidy'),
                subtitle: const Text('Genesis reclaims ₹78k post-installation.'),
                secondary: Icon(Icons.account_balance_rounded, color: isSubsidy ? theme.colorScheme.tertiary : null),
                value: isSubsidy,
                onChanged: (v) => setModalState(() => isSubsidy = v),
              ),
              SwitchListTile(
                title: const Text('Financing (Bank Loan)'),
                subtitle: const Text('Genesis manages the bank loan application.'),
                secondary: Icon(Icons.assured_workload_rounded, color: isLoan ? theme.colorScheme.primary : null),
                value: isLoan,
                onChanged: (v) => setModalState(() => isLoan = v),
              ),
              
              if (isLoan) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: depositController,
                  onChanged: (v) {
                    final numeric = v.replaceAll(',', '');
                    if (numeric.isEmpty) {
                      depositController.text = '';
                      return;
                    }
                    final formatted = CurrencyFormatter.formatINR(numeric);
                    if (v != formatted) {
                      depositController.value = depositController.value.copyWith(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Initial Token Deposit (₹)', 
                    prefixIcon: Icon(Icons.payments_rounded),
                    helperText: 'Token amount paid during booking.',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(clientsProvider.notifier).updateFinancials(
                    client.id,
                    solarCostRs: CurrencyFormatter.parseINR(costController.text),
                    isSubsidy: isSubsidy,
                    isLoan: isLoan,
                    initialDepositRs: isLoan ? CurrencyFormatter.parseINR(depositController.text) : null,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Apply Strategic Plan'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    ),
  );
}

  Future<void> _showEditSystemDNADialog(Client client) async {
    final theme = Theme.of(context);
    List<InverterConfiguration> editedInverters = List.from(client.inverterConfigs);
    List<PanelConfiguration> editedPanels = List.from(client.panelConfigs);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalKwp = editedPanels.fold(0.0, (sum, p) => sum + (p.capacityW * p.count) / 1000.0);
          
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Professional DNA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
                        Text('Configure solar hardware registry', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${totalKwp.toStringAsFixed(2)} kWp',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // PANELS SECTION
                        _buildDNAConfigList(
                          title: 'Solar Panels',
                          icon: Icons.solar_power_rounded,
                          items: editedPanels.map((p) => '${p.brand} ${p.series} (${p.capacityW}W x ${p.count})').toList(),
                          onAdd: () async {
                            final newPanel = await _showAddHardwareDialog<PanelConfiguration>(isPanel: true);
                            if (newPanel != null) {
                              setDialogState(() => editedPanels.add(newPanel));
                            }
                          },
                          onRemove: (index) => setDialogState(() => editedPanels.removeAt(index)),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // INVERTERS SECTION
                        _buildDNAConfigList(
                          title: 'Inverter Units',
                          icon: Icons.power_rounded,
                          items: editedInverters.map((i) => '${i.brand} ${i.model} (${i.capacityKw}kW x ${i.count})').toList(),
                          onAdd: () async {
                            final newInverter = await _showAddHardwareDialog<InverterConfiguration>(isPanel: false);
                            if (newInverter != null) {
                              setDialogState(() => editedInverters.add(newInverter));
                            }
                          },
                          onRemove: (index) => setDialogState(() => editedInverters.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (editedPanels.isEmpty && editedInverters.isEmpty) ? null : () {
                    ref.read(clientsProvider.notifier).updateSystemDNA(
                      client.id,
                      inverters: editedInverters,
                      panels: editedPanels,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Update Professional DNA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDNAConfigList({
    required String title,
    required IconData icon,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              color: theme.colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: const Center(child: Text('No hardware registered', style: TextStyle(fontSize: 12, color: Colors.grey))),
          )
        else
          ...items.asMap().entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              dense: true,
              title: Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.redAccent),
                onPressed: () => onRemove(entry.key),
              ),
            ),
          )),
      ],
    );
  }

  Future<T?> _showAddHardwareDialog<T>({required bool isPanel}) async {
    String selectedBrand = isPanel ? _panelBrandData.keys.first : _inverterBrandData.keys.first;
    String selectedSubModel = isPanel ? _panelBrandData[selectedBrand]!.first : _inverterBrandData[selectedBrand]!.first;
    String customBrand = '';
    String customValue = '';
    String capacityStr = '';
    String countArrStr = '1';
    final theme = Theme.of(context);

    return await showDialog<T>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isPanel ? 'Add Solar Panels' : 'Add Inverters', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 DropdownButtonFormField<String>(
                   value: selectedBrand, 
                   items: (isPanel ? _panelBrandData.keys : _inverterBrandData.keys).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                   onChanged: (v) {
                     setDialogState(() {
                       selectedBrand = v!;
                       // If Custom brand, auto-lock to Custom series/model
                       if (selectedBrand.contains('Custom')) {
                         selectedSubModel = isPanel ? 'Custom Series' : 'Custom Model';
                       } else {
                         selectedSubModel = isPanel ? _panelBrandData[selectedBrand]!.first : _inverterBrandData[selectedBrand]!.first;
                       }
                     });
                   }, 
                   decoration: const InputDecoration(labelText: 'Brand')
                 ),
                 if (selectedBrand.contains('Custom')) ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: InputDecoration(labelText: isPanel ? 'Custom Brand Name' : 'Custom Inverter Name', hintText: 'e.g. Tata Solar'),
                     onChanged: (v) => customBrand = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 if (!selectedBrand.contains('Custom'))
                   DropdownButtonFormField<String>(
                     value: selectedSubModel, 
                     items: (isPanel ? _panelBrandData[selectedBrand]! : _inverterBrandData[selectedBrand]!).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                     onChanged: (v) => setDialogState(() => selectedSubModel = v!), 
                     decoration: InputDecoration(labelText: isPanel ? 'Series Type' : 'System Model')
                   ),
                 if (selectedSubModel.contains('Custom')) ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: InputDecoration(labelText: isPanel ? 'Custom Series Name' : 'Custom Model Name'),
                     onChanged: (v) => customValue = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: InputDecoration(labelText: isPanel ? 'Wattage (W)' : 'Capacity (kW)', hintText: isPanel ? 'e.g. 540' : 'e.g. 5.0'), 
                   keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                   inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                   onChanged: (v) => capacityStr = v
                 ),
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: const InputDecoration(labelText: 'Count', hintText: 'e.g. 1'), 
                   keyboardType: TextInputType.number, 
                   initialValue: '1',
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                   onChanged: (v) => countArrStr = v
                 ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                final finalBrand = selectedBrand.contains('Custom') && customBrand.isNotEmpty ? customBrand : selectedBrand;
                final finalSub = selectedSubModel.contains('Custom') && customValue.isNotEmpty ? customValue : selectedSubModel;
                
                if (isPanel) {
                  Navigator.pop(ctx, PanelConfiguration(
                    brand: finalBrand, 
                    series: finalSub, 
                    capacityW: int.tryParse(capacityStr) ?? 540, 
                    count: int.tryParse(countArrStr) ?? 1
                  ) as T);
                } else {
                  Navigator.pop(ctx, InverterConfiguration(
                    brand: finalBrand, 
                    model: finalSub, 
                    capacityKw: double.tryParse(capacityStr) ?? 5.0, 
                    count: int.tryParse(countArrStr) ?? 1
                  ) as T);
                }
              }, 
              child: Text('ADD', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditContactDialog(Client client) async {
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone);
    final addressController = TextEditingController(text: client.address);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Contact Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Client Name', prefixIcon: Icon(Icons.person_rounded)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_rounded)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Installation Address', prefixIcon: Icon(Icons.location_on_rounded)),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(clientsProvider.notifier).updateContactInfo(
                    client.id,
                    name: nameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Update Contact Info'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditUtilityIDsDialog(Client client) async {
    final consumerController = TextEditingController(text: client.consumerNumber);
    final npIdController = TextEditingController(text: client.npApplicationNumber ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Utility Identifiers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
            const SizedBox(height: 24),
            TextField(
              controller: consumerController,
              decoration: const InputDecoration(labelText: 'Consumer Number', prefixIcon: Icon(Icons.numbers_rounded)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: npIdController,
              decoration: const InputDecoration(labelText: 'NP Application ID', prefixIcon: Icon(Icons.assignment_ind_rounded)),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(clientsProvider.notifier).updateUtilityIDs(
                  client.id,
                  consumerNumber: consumerController.text,
                  npApplicationNumber: npIdController.text.isEmpty ? null : npIdController.text,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Update Identifiers'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final clientIndex = clients.indexWhere((c) => c.id == widget.clientId);
    if (clientIndex == -1) return const Scaffold(body: Center(child: Text('Client not found')));
    
    final client = clients[clientIndex];
    final docs = ref.watch(documentsProvider).where((d) => d.clientId == client.id).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red), 
            onPressed: () async {
              final confirmed = await DialogUtils.showDeleteConfirmation(
                context,
                title: 'Delete Client',
                message: 'This will permanently remove "${client.name}" and all their associated documents. This action can NOT be undone.',
              );
              if (confirmed) {
                ref.read(clientsProvider.notifier).deleteClient(client.id);
                if (mounted) context.pop();
              }
            }
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: "OVERVIEW"),
            Tab(text: "ECONOMICS"),
            Tab(text: "DOCUMENTS"),
            Tab(text: "HARDWARE"),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(client, isWide),
              _buildFinancialsTab(client, isWide),
              _buildDocumentsTab(client, docs, isWide),
              _buildHardwareTab(client, isWide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Client client, bool isWide) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVendorSummary(client),
          const SizedBox(height: 12),
          if (isWide) 
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildGeneralInfo(client)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2, 
                  child: Column(
                    children: [
                      _buildSystemDNA(client),
                      const SizedBox(height: 24),
                      _buildUtilityIDs(client),
                    ],
                  )
                ),
              ],
            )
          else
            Column(
              children: [
                _buildSystemDNA(client),
                const SizedBox(height: 24),
                _buildUtilityIDs(client),
                const SizedBox(height: 24),
                _buildGeneralInfo(client),
              ],
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  }

  Widget _buildSystemDNA(Client client) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildCard(
          title: 'System Technical Specifications',
          icon: Icons.bolt_rounded,
          action: TextButton(onPressed: () => _showEditSystemDNADialog(client), child: const Text('Edit DNA')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total System Size', '${client.systemSizeKwp.toStringAsFixed(2)} kWp', isHero: true),
              const Divider(height: 32),
              
              // Solar Panels Section
              Row(
                children: [
                  Icon(Icons.solar_power_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('SOLAR PANELS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              if (client.panelConfigs.isEmpty)
                const Text('No panel data recorded', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey))
              else
                ...client.panelConfigs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildHardwareDetailRow(
                    title: p.brand,
                    subtitle: p.series,
                    detail: '${p.capacityW}W × ${p.count}',
                  ),
                )),

              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
              const SizedBox(height: 16),

              // Inverters Section
              Row(
                children: [
                  Icon(Icons.power_rounded, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  const Text('INVERTERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              if (client.inverterConfigs.isEmpty)
                const Text('No inverter data recorded', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey))
              else
                ...client.inverterConfigs.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildHardwareDetailRow(
                    title: i.brand,
                    subtitle: 'Grid-Tie Inverter',
                    detail: '${i.capacityKw}kW × ${i.count}',
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityIDs(Client client) {
    return _buildCard(
      title: 'Utility Identifiers',
      icon: Icons.assignment_ind_rounded,
      action: TextButton(onPressed: () => _showEditUtilityIDsDialog(client), child: const Text('Edit IDs')),
      child: Column(
        children: [
          _buildStatRow(
            'Consumer Number', 
            client.consumerNumber,
            onCopy: () => _copyToClipboard(client.consumerNumber, 'Consumer Number'),
          ),
          _buildStatRow(
            'NP Application ID', 
            client.npApplicationNumber ?? 'Pending Registration',
            onCopy: client.npApplicationNumber != null 
              ? () => _copyToClipboard(client.npApplicationNumber!, 'NP ID') 
              : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareDetailRow({required String title, required String subtitle, required String detail}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(detail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
  Widget _buildVendorSummary(Client client) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business_center_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Assigned Authority', 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _buildVendorBadge(client),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _showEditVendorDialog(client),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Change Vendor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfo(Client client) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          title: 'Location & Contact',
          icon: Icons.contact_page_rounded,
          action: TextButton(onPressed: () => _showEditContactDialog(client), child: const Text('Edit Contact')),
          child: Column(
            children: [
              _buildStatRow(
                'Client Name', 
                client.name, 
                onCopy: () => _copyToClipboard(client.name, 'Name'),
              ),
              const Divider(height: 16),
              _buildStatRow(
                'Phone', 
                client.phone, 
                onCopy: () => _copyToClipboard(client.phone, 'Phone'),
                actionIcon: Icons.call_rounded,
                onAction: () => launchUrl(Uri.parse('tel:${client.phone}')),
              ),
              _buildStatRow(
                'Installation Address', 
                client.address, 
                onCopy: () => _copyToClipboard(client.address, 'Address'),
                actionIcon: Icons.map_rounded,
                onAction: () => _launchMap(client.address),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildFinancialsTab(Client client, bool isWide) {
    final theme = Theme.of(context);
    final subsidyAmount = client.isSubsidy ? client.subsidyAmount : 0.0;
    final totalQuotation = client.totalQuotation;
    final strategicLoan = client.strategicLoanAmount;
    final advisedPayment = client.advisedDownpayment;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 20),
      child: Column(
        children: [
          _buildCard(
            title: 'Project Economics',
            icon: Icons.account_balance_wallet_rounded,
            action: TextButton(onPressed: () => _showEditFinancialsDialog(client), child: const Text('Edit Economics')),
            child: Column(
              children: [
                _buildStatRow('Total Project Quotation', '₹${CurrencyFormatter.formatINR(totalQuotation)}', isHero: true),
                const Divider(height: 32),
                _buildStatRow('Funding Model', client.isLoan ? 'Bank Loan Managed' : 'Direct Payment'),
                _buildStatRow('Genesis Subsidy Reclaim', client.isSubsidy ? '₹${CurrencyFormatter.formatINR(subsidyAmount)}' : 'Not Claimed'),
                const Divider(height: 16),
                _buildStatRow('Net Client Payable', '₹${CurrencyFormatter.formatINR(totalQuotation)}', isHero: true),
                
                if (client.isLoan) ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_graph_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'STRATEGIC FUNDING SPLIT', 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: strategicLoan <= 198000 ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            strategicLoan <= 198000 ? 'OPTIMAL' : 'STRATEGIC',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: strategicLoan <= 198000 ? Colors.green : Colors.orange),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Visual Split Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (strategicLoan / totalQuotation * 100).round(),
                            child: Container(color: theme.colorScheme.primary),
                          ),
                          Expanded(
                            flex: (advisedPayment / totalQuotation * 100).round(),
                            child: Container(color: theme.colorScheme.surfaceContainerHighest),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildStatRow('Strategic Bank Loan', '₹${CurrencyFormatter.formatINR(strategicLoan)}', isHero: true),
                  _buildStatRow('Direct Investment (Cash)', '₹${CurrencyFormatter.formatINR(advisedPayment)}'),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            const Text('Genesis Strategy Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strategicLoan <= 198000 
                            ? 'Excellent! Your loan is within the ₹1.98L threshold for the lowest possible interest rates (5-6%).' 
                            : 'Strategic Alert: Capping your loan at ₹1.98L avoids the higher interest (>6%) bracket associated with larger loans.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(Client client, List<ClientDocument> docs, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Generation Section (Pinned)
          _buildDocumentCategory(
            title: 'Automation Hub',
            subtitle: 'One-tap smart PDF generation for official records.',
            theme: Theme.of(context),
            children: [
              _buildAutomationSlot(
                label: 'Agreement Generation',
                subtitle: 'Official solar installation contract with client mapping.',
                icon: Icons.description_rounded,
                onTap: () => _generateAgreement(client),
              ),
              _buildAutomationSlot(
                label: 'Self-Certificate',
                subtitle: 'Technician verification and site safety document.',
                icon: Icons.verified_rounded,
                onTap: () => _generateSelfCertificate(client),
              ),
              _buildAutomationSlot(
                label: 'Professional Quotation',
                subtitle: 'Breakdown of system components and financial summary.',
                icon: Icons.request_quote_rounded,
                onTap: () => _generateQuotation(client),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // 2. Bank Documents
          _buildDocumentCategory(
            title: 'Bank Documents',
            subtitle: 'Passbook and Cancelled Cheque for subsidy processing.',
            theme: Theme.of(context),
            children: [
              _buildDocSlot(client, docs, DocumentType.bankPassbook, 'Bank Passbook'),
              _buildDocSlot(client, docs, DocumentType.cancelledCheque, 'Cancelled Cheque'),
            ],
          ),

          const SizedBox(height: 32),

          // 3. Government Documents
          _buildDocumentCategory(
            title: 'Government Documents',
            subtitle: 'Identity and Property verification proofs.',
            theme: Theme.of(context),
            children: [
              _buildDocSlot(client, docs, DocumentType.aadhar, 'Aadhar Card'),
              _buildDocSlot(client, docs, DocumentType.pan, 'PAN Card'),
              _buildDocSlot(client, docs, DocumentType.verapavti, 'Vera Pavti (Tax)'),
              _buildDocSlot(client, docs, DocumentType.electricityBill, 'Electricity Bill'),
            ],
          ),

          const SizedBox(height: 32),

          // 4. Site Verification (Geo-tagged)
          _buildDocumentCategory(
            title: 'Site Verification',
            subtitle: 'Geo-tagged roof photos for audit and verification.',
            theme: Theme.of(context),
            children: [
              if (client.isLoan) _buildDocSlot(client, docs, DocumentType.roofPhotoPreInstall, 'Without Solar'),
              _buildDocSlot(client, docs, DocumentType.roofPhotoPostInstall, 'Installed Solar'),
            ],
          ),
          
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildDocumentCategory({required String title, required String subtitle, required List<Widget> children, required ThemeData theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDocSlot(Client client, List<ClientDocument> docs, DocumentType type, String label) {
    ClientDocument? existingDoc;
    try {
      existingDoc = docs.firstWhere((d) => d.type == type);
    } catch (_) {
      existingDoc = null;
    }
    
    final hasDoc = existingDoc != null;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDoc ? Colors.green.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasDoc ? Colors.green.withValues(alpha: 0.2) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasDoc ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDoc ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: hasDoc ? Colors.green : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (existingDoc != null) ...[
                  const SizedBox(height: 2),
                  Text(existingDoc.fileName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (existingDoc != null) ...[
            IconButton(onPressed: () => _handlePreviewOrDownload(client, existingDoc!), icon: const Icon(Icons.remove_red_eye_rounded, size: 20)),
            IconButton(
              onPressed: () async {
                final confirmed = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: 'Remove Document',
                  message: 'Are you sure you want to remove "${existingDoc!.fileName}" from this client?',
                );
                if (confirmed) {
                  ref.read(documentsProvider.notifier).removeDocument(existingDoc.id);
                }
              }, 
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red)
            ),
          ] else ...[
            IconButton(
              onPressed: () => _pickDocument(client, type, label), 
              icon: const Icon(Icons.attach_file_rounded, size: 20), 
              tooltip: 'Attach'
            ),
            IconButton(
              onPressed: () {
                final isGeoType = type == DocumentType.roofPhotoPreInstall || type == DocumentType.roofPhotoPostInstall;
                if (isGeoType) {
                  _captureGeoPhoto(client, type, label);
                } else {
                  _scanDocument(client, type);
                }
              }, 
              icon: Icon(
                type == DocumentType.roofPhotoPreInstall || type == DocumentType.roofPhotoPostInstall 
                  ? Icons.add_a_photo_rounded 
                  : Icons.camera_alt_rounded, 
                size: 20
              ), 
              tooltip: 'Camera'
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutomationSlot({
    required String label, 
    required String subtitle, 
    required IconData icon, 
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  subtitle, 
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text('GENERATE'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareTab(Client client, bool isWide) {
    final inverters = ref.watch(inverterSerialsProvider);
    final panels = ref.watch(panelSerialsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 20),
      child: Column(
        children: [
          _buildCard(
            title: 'Scan Hardware',
            icon: Icons.qr_code_scanner_rounded,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        key: const Key('scanInverter'),
                        onPressed: () => _scanHardware(false), 
                        icon: const Icon(Icons.qr_code_scanner_rounded), 
                        label: const Text('Scan Inverter'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showManualSerialDialog(false), 
                        icon: const Icon(Icons.keyboard_outlined, size: 16), 
                        label: const Text('Add Manually', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        key: const Key('scanPanel'),
                        onPressed: () => _scanHardware(true), 
                        icon: const Icon(Icons.qr_code_scanner_rounded), 
                        label: const Text('Scan Panel'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showManualSerialDialog(true), 
                        icon: const Icon(Icons.keyboard_outlined, size: 16), 
                        label: const Text('Add Manually', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildHardwareList('Inverters', inverters, Icons.power_rounded, () async {
            final confirmed = await DialogUtils.showDeleteConfirmation(
              context,
              title: 'Clear Inverters',
              message: 'Are you sure you want to remove all scanned inverter serials?',
            );
            if (confirmed) ref.read(inverterSerialsProvider.notifier).clear();
          }, isPanel: false),
          const SizedBox(height: 24),
          _buildHardwareList('Panels', panels, Icons.solar_power_rounded, () async {
            final confirmed = await DialogUtils.showDeleteConfirmation(
              context,
              title: 'Clear Panels',
              message: 'Are you sure you want to remove all scanned panel serials?',
            );
            if (confirmed) ref.read(panelSerialsProvider.notifier).clear();
          }, isPanel: true),
        ],
      ),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildCard({required String title, required IconData icon, required Widget child, Widget? action}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {IconData? actionIcon, VoidCallback? onAction}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onAction,
        onLongPress: () => _copyToClipboard(value, label),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              if (onAction != null && actionIcon != null)
                IconButton.filledTonal(
                  onPressed: onAction, 
                  icon: Icon(actionIcon, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(40, 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {
    bool isHero = false, 
    VoidCallback? onCopy,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(), 
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5), 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 0.8
                )
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      value, 
                      style: TextStyle(
                        fontWeight: isHero ? FontWeight.bold : FontWeight.w600,
                        fontSize: isHero ? 18 : 15,
                        color: isHero ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onCopy != null) ...[
                        const SizedBox(width: 8),
                        _buildActionCircle(theme, Icons.content_copy_rounded, onCopy, isSecondary: true),
                      ],
                      if (onAction != null && actionIcon != null) ...[
                        const SizedBox(width: 12),
                        _buildActionCircle(theme, actionIcon, onAction, isSecondary: false),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle(ThemeData theme, IconData icon, VoidCallback onTap, {required bool isSecondary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSecondary 
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          size: 16, 
          color: isSecondary 
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.primary
        ),
      ),
    );
  }



  Widget _buildHardwareList(String title, List<String> serials, IconData icon, VoidCallback onClear, {required bool isPanel}) {
    final theme = Theme.of(context);
    return _buildCard(
      title: title, icon: icon,
      action: serials.isNotEmpty ? TextButton(onPressed: onClear, child: const Text('Clear', style: TextStyle(color: Colors.red))) : null,
      child: serials.isEmpty 
        ? const Padding(padding: EdgeInsets.all(16), child: Text('No items scanned', style: TextStyle(fontSize: 12, color: Colors.grey)))
        : ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: serials.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, i) {
              final serial = serials[i];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () => _showEditSerialDialog(serial, isPanel),
                title: Text(serial, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to edit', style: TextStyle(fontSize: 10, color: Colors.grey)),
                trailing: IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.error.withValues(alpha: 0.5)), 
                  onPressed: () async {
                    final confirmed = await DialogUtils.showConfirmation(
                      context,
                      title: 'Remove Serial',
                      message: 'Are you sure you want to remove this serial number?',
                      confirmLabel: 'REMOVE',
                      confirmColor: theme.colorScheme.error,
                    );
                    if (confirmed) {
                      if (isPanel) {
                        ref.read(panelSerialsProvider.notifier).remove(serial);
                      } else {
                        ref.read(inverterSerialsProvider.notifier).remove(serial);
                      }
                    }
                  }
                ),
              );
            },
          ),
    );
  }

  Widget _buildVendorBadge(Client client) {
    final isGenesis = client.vendorName == 'Genesis';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGenesis ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isGenesis ? 'Genesis (Portal Owner)' : 'Vendor: ${client.vendorName}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isGenesis ? Colors.blue.shade700 : Colors.orange.shade800),
      ),
    );
  }

  Future<void> _showEditVendorDialog(Client client) async {
    final theme = Theme.of(context);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final partners = ref.watch(vendorPartnerProvider);
            final currentVendor = client.vendorName;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Change Assigned Vendor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const Text('Select the authority managing this client.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  // Partners
                  ...partners.map((p) => ListTile(
                    onTap: () async {
                      final confirmed = await DialogUtils.showConfirmation(
                        context,
                        title: 'Confirm Assignment',
                        message: 'Are you sure you want to assign this client to ${p.name}?',
                        confirmLabel: 'ASSIGN',
                      );
                      
                      if (confirmed) {
                        ref.read(clientsProvider.notifier).updateVendor(client.id, p.name);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.business_rounded, color: Colors.orange, size: 20),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: currentVendor == p.name ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )),
                  
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showManualSerialDialog(bool isPanel) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manual ${isPanel ? 'Panel' : 'Inverter'} Entry', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Manually type the hardware serial number below.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. SN-123456789',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(isPanel ? Icons.solar_power : Icons.power),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (isPanel) {
                  ref.read(panelSerialsProvider.notifier).add(controller.text.trim());
                } else {
                  ref.read(inverterSerialsProvider.notifier).add(controller.text.trim());
                }
                Navigator.pop(ctx);
              }
            }, 
            child: Text('ADD SERIAL', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSerialDialog(String oldSerial, bool isPanel) async {
    final controller = TextEditingController(text: oldSerial);
    final theme = Theme.of(context);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Serial Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update the serial number for this hardware component.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Updated Serial',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (isPanel) {
                  ref.read(panelSerialsProvider.notifier).update(oldSerial, controller.text.trim());
                } else {
                  ref.read(inverterSerialsProvider.notifier).update(oldSerial, controller.text.trim());
                }
                Navigator.pop(ctx);
              }
            }, 
            child: Text('UPDATE', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getSubsidyStatusLabel(SubsidyStatus status) {
    switch (status) {
      case SubsidyStatus.pendingInstallation: return 'Installation Pending';
      case SubsidyStatus.meteringInProgress: return 'MGVCL Metering';
      case SubsidyStatus.readyForRedemption: return 'Redemption Ready';
      case SubsidyStatus.collected: return 'Collected';
    }
  }

  Widget _buildSubsidyStatusBadge(SubsidyStatus status) {
    final (color, icon) = switch (status) {
      SubsidyStatus.pendingInstallation => (Colors.grey, Icons.schedule_rounded),
      SubsidyStatus.meteringInProgress => (Colors.blue, Icons.electric_meter_rounded),
      SubsidyStatus.readyForRedemption => (Colors.orange, Icons.redeem_rounded),
      SubsidyStatus.collected => (Colors.green, Icons.check_circle_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(_getSubsidyStatusLabel(status).toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
