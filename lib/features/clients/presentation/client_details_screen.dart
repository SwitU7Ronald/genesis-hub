import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/core/services/document_service.dart';

import 'package:genesis_util/core/utils/dialog_utils.dart';
import 'package:genesis_util/features/clients/domain/constants/hardware_constants.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:genesis_util/features/clients/domain/entities/hardware_config.dart';
import 'package:genesis_util/features/clients/domain/providers/client_providers.dart';
import 'package:genesis_util/features/clients/domain/providers/hardware_providers.dart';
import 'package:genesis_util/features/clients/presentation/controllers/client_details_controller.dart';
import 'package:genesis_util/features/clients/presentation/widgets/documents_tab.dart';
import 'package:genesis_util/features/clients/domain/services/document_validator_service.dart';
import 'package:genesis_util/features/clients/presentation/widgets/economics_tab.dart';
import 'package:genesis_util/features/clients/presentation/widgets/hardware_tab.dart';
import 'package:genesis_util/features/clients/presentation/widgets/overview_tab.dart';
import 'package:genesis_util/features/scanner/domain/providers/scanner_provider.dart';
import 'package:genesis_util/features/vendors/domain/providers/vendor_providers.dart';
import 'package:go_router/go_router.dart';

class ClientDetailsScreen extends ConsumerStatefulWidget {
  const ClientDetailsScreen({required this.clientId, super.key});
  final String clientId;

  @override
  ConsumerState<ClientDetailsScreen> createState() =>
      _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends ConsumerState<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  // --- Document Operations ---

  // --- Document Operations (Delegated to Professional Service Layer) ---

  Future<void> _previewDocument(ClientDocument doc) async =>
      ref.read(documentServiceProvider).previewDocument(context, doc);

  Future<void> _downloadDocument(ClientDocument doc) async =>
      ref.read(documentServiceProvider).downloadDocument(context, doc);

  Future<void> _attachDocument(Client client, DocumentType type) async {
    if (!_checkDocumentLockout(client, type)) return;
    final doc = await ref
        .read(documentServiceProvider)
        .pickAndPrepareDocument(client.id, type);
    if (doc != null) {
      ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Document attached successfully.')),
        );
      }
    }
  }

  Future<void> _scanDocument(Client client, DocumentType type) async {
    if (!_checkDocumentLockout(client, type)) return;
    final doc = await ref
        .read(documentServiceProvider)
        .scanDocument(client.id, type);
    if (doc != null) {
      ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Document scanned successfully.')),
        );
      }
    }
  }

  Future<void> _takeCameraPhoto(Client client, DocumentType type) async {
    if (!_checkDocumentLockout(client, type)) return;
    final doc = await ref
        .read(documentServiceProvider)
        .takeCameraPhoto(client.id, type);
    if (doc != null) {
      ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Camera photo attached successfully.'),
          ),
        );
      }
    }
  }

  bool _checkDocumentLockout(Client client, DocumentType type) {
    if (type == DocumentType.quotation ||
        type == DocumentType.agreement ||
        type == DocumentType.selfCertificate) {
      final result = DocumentValidatorService.validateQuotation(client);
      if (!result.isValid) {
        _showValidationBottomSheet(context, type, result);
        return false;
      }
    }
    return true;
  }

  void _showValidationBottomSheet(
    BuildContext context,
    DocumentType type,
    ValidationResult result,
  ) {
    var docName = type.name;
    if (type == DocumentType.selfCertificate) docName = 'Self Certificate';
    if (type == DocumentType.agreement) docName = 'Agreement';
    if (type == DocumentType.quotation) docName = 'Quotation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_person_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Documentation Locked',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result.errorMessage != null) ...[
              Text(
                result.errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                'Cannot attach $docName. Please complete the following missing details first:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ...result.missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

    


  Future<void> _deleteDocument(ClientDocument doc) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Remove Document',
      message: 'Permanently delete this document from client records?',
    );
    if (confirmed == true) {
      ref.read(documentsProvider.notifier).removeDocument(doc.id);
    }
  }

  // --- Hardware Operations ---

  Future<void> _scanHardware(bool isPanel) async {
    final result = await ref.read(scannerProvider.notifier).scanSerial();
    if (result != null && result.isNotEmpty) {
      if (isPanel) {
        ref.read(panelSerialsProvider.notifier).add(result);
      } else {
        ref.read(inverterSerialsProvider.notifier).add(result);
      }
    }
  }

  // --- Dialogs (Simplified) ---

  Future<void> _showEditFinancials(Client client) async {
    final costController = TextEditingController(
      text: client.solarCostRs?.toString() ?? '',
    );
    final depositController = TextEditingController(
      text: client.initialDepositRs?.toString() ?? '',
    );
    var isSubsidy = client.isSubsidy;
    var isLoan = client.isLoan;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Refine Project Economics'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Total Quotation (₹)',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Subsidy Applicable'),
                  value: isSubsidy,
                  onChanged: (v) => setState(() => isSubsidy = v),
                ),
                SwitchListTile(
                  title: const Text('Bank Loan Required'),
                  value: isLoan,
                  onChanged: (v) => setState(() => isLoan = v),
                ),
                if (isLoan)
                  TextField(
                    controller: depositController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Deposit (₹)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(clientDetailsControllerProvider(client.id))
                    .updateFinancials(
                      solarCostRs: double.tryParse(costController.text),
                      isSubsidy: isSubsidy,
                      isLoan: isLoan,
                      initialDepositRs: double.tryParse(depositController.text),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('SAVE CHANGES'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditContactInfo(Client client) async {
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone);
    final addressController = TextEditingController(text: client.address);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Contact Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Site Address'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(clientsProvider.notifier)
                  .updateContactInfo(
                    client.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualSerialDialog(bool isPanel) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manual ${isPanel ? "Panel" : "Inverter"} Entry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter Serial Number'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (isPanel) {
                  ref
                      .read(panelSerialsProvider.notifier)
                      .add(controller.text.trim().toUpperCase());
                } else {
                  ref
                      .read(inverterSerialsProvider.notifier)
                      .add(controller.text.trim().toUpperCase());
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUtilityIDs(Client client) async {
    final consumerController = TextEditingController(
      text: client.consumerNumber,
    );
    final npController = TextEditingController(
      text: client.npApplicationNumber ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Utility Identifiers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: consumerController,
              decoration: const InputDecoration(labelText: 'Consumer Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: npController,
              decoration: const InputDecoration(labelText: 'NP Portal ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(clientsProvider.notifier)
                  .updateUtilityIDs(
                    client.id,
                    consumerNumber: consumerController.text.trim(),
                    npApplicationNumber: npController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSystemDNA(Client client) async {
    final panelConfigs = List<PanelConfiguration>.from(client.panelConfigs);
    final inverterConfigs = List<InverterConfiguration>.from(
      client.inverterConfigs,
    );

    final pConfig = panelConfigs.isNotEmpty ? panelConfigs.first : null;
    final iConfig = inverterConfigs.isNotEmpty ? inverterConfigs.first : null;

    var pBrand =
        pConfig?.brand ??
        (HardwareConstants.panelBrandData.keys.isNotEmpty
            ? HardwareConstants.panelBrandData.keys.first
            : 'Custom (User Defined)');
    final isCustomPanelBrand = !HardwareConstants.panelBrandData.containsKey(
      pBrand,
    );
    var pCustomBrand = isCustomPanelBrand ? pBrand : '';
    if (isCustomPanelBrand) pBrand = 'Custom (Other Brand)';

    var pSeries =
        pConfig?.series ??
        (HardwareConstants.panelBrandData[pBrand]?.isNotEmpty ?? false
            ? (HardwareConstants.panelBrandData[pBrand]?.first ?? 'Custom Series')
            : 'Custom Series');
    final isCustomPanelSeries =
        pBrand != 'Custom (Other Brand)' &&
        (HardwareConstants.panelBrandData[pBrand] == null ||
            !(HardwareConstants.panelBrandData[pBrand]?.contains(pSeries) ?? false));
    var pCustomSeries = isCustomPanelSeries ? pSeries : '';
    if (isCustomPanelSeries || pBrand == 'Custom (Other Brand)') {
      pSeries = 'Custom Series';
    }

    final panelWattsController = TextEditingController(
      text: pConfig?.capacityW.toString() ?? '540',
    );
    final panelCountController = TextEditingController(
      text: pConfig?.count.toString() ?? '1',
    );


    var iBrand =
        iConfig?.brand ??
        (HardwareConstants.inverterBrandData.keys.isNotEmpty
            ? HardwareConstants.inverterBrandData.keys.first
            : 'Custom (User Defined)');
    final isCustomInvBrand = !HardwareConstants.inverterBrandData.containsKey(
      iBrand,
    );
    var iCustomBrand = isCustomInvBrand ? iBrand : '';
    if (isCustomInvBrand) iBrand = 'Custom (Other Brand)';

    var iModel =
        iConfig?.model ??
        (HardwareConstants.inverterBrandData[iBrand]?.isNotEmpty ?? false
            ? (HardwareConstants.inverterBrandData[iBrand]?.first ?? 'Custom Model')
            : 'Custom Model');
    final isCustomInvModel =
        iBrand != 'Custom (Other Brand)' &&
        (HardwareConstants.inverterBrandData[iBrand] == null ||
            !(HardwareConstants.inverterBrandData[iBrand]?.contains(iModel) ?? false));
    var iCustomModel = isCustomInvModel ? iModel : '';
    if (isCustomInvModel || iBrand == 'Custom (Other Brand)') {
      iModel = 'Custom Model';
    }

    final invKwController = TextEditingController(
      text: iConfig?.capacityKw.toString() ?? '5.0',
    );
    final invCountController = TextEditingController(
      text: iConfig?.count.toString() ?? '1',
    );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configure Main Hardware'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRIMARY PANELS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: HardwareConstants.panelBrandData.keys.contains(pBrand)
                      ? pBrand
                      : 'Custom (Other Brand)',
                  items: HardwareConstants.panelBrandData.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      pBrand = v ?? '';
                      if (pBrand.contains('Custom')) {
                        pSeries = 'Custom Series';
                      } else {
                        pSeries =
                            HardwareConstants
                                    .panelBrandData[pBrand]
                                    ?.isNotEmpty ?? false
                            ? (HardwareConstants.panelBrandData[pBrand]?.first ?? '')
                            : '';
                      }

                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Panel Brand',
                    isDense: true,
                  ),
                ),
                if (pBrand.contains('Custom')) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: pCustomBrand,
                    decoration: const InputDecoration(
                      labelText: 'Custom Brand Name',
                      isDense: true,
                    ),
                    onChanged: (v) => pCustomBrand = v,
                  ),
                ],
                const SizedBox(height: 12),
                if (!pBrand.contains('Custom'))
                  DropdownButtonFormField<String>(
                    initialValue:
                        (HardwareConstants.panelBrandData[pBrand] ?? [])
                            .contains(pSeries)
                        ? pSeries
                        : (HardwareConstants.panelBrandData[pBrand]?.first ??
                              ''),
                    items: (HardwareConstants.panelBrandData[pBrand] ?? [])
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        pSeries = v ?? '';

                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Series Type',
                      isDense: true,
                    ),
                  ),
                if (pSeries == 'Custom Series') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: pCustomSeries,
                    decoration: const InputDecoration(
                      labelText: 'Custom Series Name',
                      isDense: true,
                    ),
                    onChanged: (v) => pCustomSeries = v,
                  ),
                ],
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: panelWattsController,
                        decoration: const InputDecoration(
                          labelText: 'Wattage (W)',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: panelCountController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'PRIMARY INVERTER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue:
                      HardwareConstants.inverterBrandData.keys.contains(iBrand)
                      ? iBrand
                      : 'Custom (Other Brand)',
                  items: HardwareConstants.inverterBrandData.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      iBrand = v ?? '';
                      if (iBrand.contains('Custom')) {
                        iModel = 'Custom Model';
                      } else {
                        iModel =
                            HardwareConstants
                                    .inverterBrandData[iBrand]
                                    ?.isNotEmpty ?? false
                            ? (HardwareConstants.inverterBrandData[iBrand]?.first ?? '')
                            : '';
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Inverter Brand',
                    isDense: true,
                  ),
                ),
                if (iBrand.contains('Custom')) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: iCustomBrand,
                    decoration: const InputDecoration(
                      labelText: 'Custom Brand Name',
                      isDense: true,
                    ),
                    onChanged: (v) => iCustomBrand = v,
                  ),
                ],
                const SizedBox(height: 12),
                if (!iBrand.contains('Custom'))
                  DropdownButtonFormField<String>(
                    initialValue:
                        (HardwareConstants.inverterBrandData[iBrand] ?? [])
                            .contains(iModel)
                        ? iModel
                        : (HardwareConstants.inverterBrandData[iBrand]?.first ??
                              ''),
                    items: (HardwareConstants.inverterBrandData[iBrand] ?? [])
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => iModel = v ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'System Model',
                      isDense: true,
                    ),
                  ),
                if (iModel == 'Custom Model') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: iCustomModel,
                    decoration: const InputDecoration(
                      labelText: 'Custom Model Name',
                      isDense: true,
                    ),
                    onChanged: (v) => iCustomModel = v,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: invKwController,
                        decoration: const InputDecoration(
                          labelText: 'Capacity (kW)',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: invCountController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final finalPanels = <PanelConfiguration>[];
                final bP = pBrand == 'Custom (Other Brand)'
                    ? pCustomBrand
                    : pBrand;
                final sP = pSeries == 'Custom Series' ? pCustomSeries : pSeries;
                if (bP.isNotEmpty &&
                    sP.isNotEmpty &&
                    panelWattsController.text.isNotEmpty &&
                    panelCountController.text.isNotEmpty) {
                  finalPanels.add(
                    PanelConfiguration(
                      brand: bP.trim(),
                      series: sP.trim(),
                      capacityW:
                          int.tryParse(panelWattsController.text.trim()) ?? 0,
                      count:
                          int.tryParse(panelCountController.text.trim()) ?? 0,
                    ),
                  );
                }
                final finalInverters = <InverterConfiguration>[];
                final bI = iBrand == 'Custom (Other Brand)'
                    ? iCustomBrand
                    : iBrand;
                final sI = iModel == 'Custom Model' ? iCustomModel : iModel;
                if (bI.isNotEmpty &&
                    sI.isNotEmpty &&
                    invKwController.text.isNotEmpty &&
                    invCountController.text.isNotEmpty) {
                  finalInverters.add(
                    InverterConfiguration(
                      brand: bI.trim(),
                      model: sI.trim(),
                      capacityKw:
                          double.tryParse(invKwController.text.trim()) ?? 0.0,
                      count: int.tryParse(invCountController.text.trim()) ?? 0,
                    ),
                  );
                }
                ref
                    .read(clientsProvider.notifier)
                    .updateSystemDNA(
                      client.id,
                      inverters: finalInverters,
                      panels: finalPanels,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('SAVE DNA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeVendor(Client client) async {
    final vendors = ref.read(vendorsProvider);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Installation Partner'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vendors.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(vendors[index].name),
              onTap: () {
                ref
                    .read(clientDetailsControllerProvider(client.id))
                    .updateVendor(vendors[index].name);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Client',
      message:
          'Are you sure you want to permanently delete ${client.name}? All documents and configurations will be lost.',
    );
    if (confirmed == true) {
      if (mounted) {
        context.pop();
        ref.read(documentsProvider.notifier).removeAllForClient(client.id);
        ref.read(clientsProvider.notifier).deleteClient(client.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final client = clients.where((c) => c.id == widget.clientId).firstOrNull;
    
    // Real-time Firestore stream for this specific client's documents
    final clientDocs = ref.watch(documentsStreamProvider(widget.clientId)).value ?? [];

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: const Center(
          child: Text(
            'The requested client does not exist or has been deleted.',
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;
    final panelSerials = ref.watch(panelSerialsProvider);
    final inverterSerials = ref.watch(inverterSerialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Client File: ${client.name.split(' ').first}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteClient(client),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: !isWide,
          tabAlignment: !isWide ? TabAlignment.start : TabAlignment.fill,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'ECONOMICS'),
            Tab(text: 'DOCUMENTS'),
            Tab(text: 'HARDWARE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            client: client,
            isWide: isWide,
            onEditContact: () => _showEditContactInfo(client),
            onEditUtilityIDs: () => _showEditUtilityIDs(client),
            onEditSystemDNA: () => _showEditSystemDNA(client),
            onEditVendor: () => _showChangeVendor(client),
          ),
          EconomicsTab(
            client: client,
            isWide: isWide,
            onEditFinancials: () => _showEditFinancials(client),
          ),
          DocumentsTab(
            client: client,
            isWide: isWide,
            documents: clientDocs,
            onPreview: _previewDocument,
            onDownload: _downloadDocument,
            onUpload: _attachDocument,
            onScan: _scanDocument,
            onCamera: _takeCameraPhoto,

            onDelete: _deleteDocument,
          ),
          HardwareTab(
            client: client,
            isWide: isWide,
            currentPanelSerials: panelSerials,
            currentInverterSerials: inverterSerials,
            onScanPanel: () => _scanHardware(true),
            onScanInverter: () => _scanHardware(false),
            onAddPanelManually: () => _showManualSerialDialog(true),
            onAddInverterManually: () => _showManualSerialDialog(false),
            onRemovePanel: (i) =>
                ref.read(panelSerialsProvider.notifier).remove(i),
            onRemoveInverter: (i) =>
                ref.read(inverterSerialsProvider.notifier).remove(i),
            onClearPanels: () =>
                ref.read(panelSerialsProvider.notifier).clear(),
            onClearInverters: () =>
                ref.read(inverterSerialsProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }
}
