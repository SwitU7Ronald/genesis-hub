import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/client_provider.dart';
import '../domain/models.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../vendors/domain/vendor_provider.dart';
import '../../vendors/domain/vendor_model.dart';

const uuid = Uuid();

class CreateClientScreen extends ConsumerStatefulWidget {
  final Client? existingClient;
  const CreateClientScreen({super.key, this.existingClient});

  @override
  ConsumerState<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _ClientDetailsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _ClientDetailsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5))),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CreateClientScreenState extends ConsumerState<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _npAppNumberController = TextEditingController();
  final _solarRateController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  
  String? _selectedVendorId = 'ronak_khristi_id';
  bool _isSubsidy = true;
  bool _isLoan = false;
  
  String? _npApplicationFilePath;
  String? _npApplicationFileName;
  String? _consumerBillFilePath;
  String? _consumerBillFileName;
  
  final List<InverterConfiguration> _inverterConfigs = [];
  final List<PanelConfiguration> _panelConfigs = [];

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
    _phoneFocusNode.addListener(() => setState(() {}));
    if (widget.existingClient != null) {
      final c = widget.existingClient!;
      _nameController.text = c.name;
      _phoneController.text = c.phone;
      _addressController.text = c.address;
      _consumerNumberController.text = c.consumerNumber;
      _npAppNumberController.text = c.npApplicationNumber ?? '';
      _solarRateController.text = CurrencyFormatter.formatINR(c.solarCostRs);
      _isSubsidy = c.isSubsidy;
      _isLoan = c.isLoan;
      _inverterConfigs.addAll(c.inverterConfigs);
      _panelConfigs.addAll(c.panelConfigs);
      if (c.vendorName.isNotEmpty) {
        final vendors = ref.read(vendorPartnerProvider);
        final vendor = vendors.where((v) => v.name == c.vendorName).firstOrNull;
        if (vendor != null) {
          _selectedVendorId = vendor.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _consumerNumberController.dispose();
    _npAppNumberController.dispose();
    _solarRateController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  double get _totalCapacityKwp => _panelConfigs.fold(0.0, (sum, p) => sum + p.totalCapacityKwp);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendors = ref.watch(vendorPartnerProvider);


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.existingClient != null ? 'Edit Client Profile' : 'New Client Onboarding', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? constraints.maxWidth * 0.1 : 20.0, vertical: 32),
            child: Form(
              key: _formKey,
              child: isWide 
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: Column(children: _buildFormSections(vendors))),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildSummarySidebar(theme, vendors)),
                  ])
                : Column(children: [..._buildFormSections(vendors), _buildSummarySidebar(theme, vendors)]),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(theme),
    );
  }

  List<Widget> _buildFormSections(List<VendorPartner> vendors) {
    return [
      _ClientDetailsSection(
        title: 'Vendor & Attribution',
        icon: Icons.business_center_rounded,
        color: const Color(0xFF0F4C81),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedVendorId,
            hint: const Text('Select Managed Partner'),
            decoration: const InputDecoration(labelText: 'Managed By', prefixIcon: Icon(Icons.hub_rounded)),
            items: [
              ...vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
            ],
            onChanged: (val) {
              setState(() => _selectedVendorId = val);
            },
            validator: (v) => v == null ? 'Please select a vendor' : null,
          ),
        ],
      ),
      _ClientDetailsSection(
        title: 'Primary Contact Information',
        icon: Icons.person_pin_rounded,
        color: Colors.blue,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) {
              if (v != v.toUpperCase()) {
                _nameController.value = _nameController.value.copyWith(
                  text: v.toUpperCase(),
                  selection: TextSelection.collapsed(offset: _nameController.selection.baseOffset),
                );
              }
            },
            decoration: const InputDecoration(
              labelText: 'Customer Legal Name', 
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Icon(Icons.person_outline_rounded),
              isDense: true
            ),
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Phone Number', 
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixText: (_phoneFocusNode.hasFocus || _phoneController.text.isNotEmpty) ? '+91 ' : null,
              counterText: "",
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              isDense: true
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Phone number is required';
              if (v.length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              // Title case logic: "main st" -> "Main St"
              if (v.isNotEmpty) {
                final words = v.split(' ');
                final capitalized = words.map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() + word.substring(1).toLowerCase();
                }).join(' ');
                
                if (v != capitalized) {
                  _addressController.value = _addressController.value.copyWith(
                    text: capitalized,
                    selection: TextSelection.collapsed(offset: _addressController.selection.baseOffset),
                  );
                }
              }
            },
            decoration: const InputDecoration(
              labelText: 'Installation Site Address', 
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Icon(Icons.map_rounded),
              isDense: true
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Address is required' : null,
          ),
        ],
      ),
      _ClientDetailsSection(
        title: 'Regulatory Identification',
        icon: Icons.app_registration_rounded,
        color: Colors.orange,
        children: [
          _buildRegulatoryField(
            controller: _consumerNumberController,
            label: 'MGVCL Consumer Number',
            icon: Icons.electric_bolt_rounded,
            filePath: _consumerBillFilePath,
            fileName: _consumerBillFileName,
            onUpload: _pickConsumerBillPdf,
            onScan: () => _scanDocument(isBill: true),
            onDelete: () => setState(() { _consumerBillFilePath = null; _consumerBillFileName = null; }),
          ),
          const SizedBox(height: 20),
          _buildRegulatoryField(
            controller: _npAppNumberController,
            label: 'NP Application ID',
            icon: Icons.assignment_ind_rounded,
            filePath: _npApplicationFilePath,
            fileName: _npApplicationFileName,
            onUpload: _pickNpApplicationPdf,
            onScan: () => _scanDocument(isBill: false),
            onDelete: () => setState(() { _npApplicationFilePath = null; _npApplicationFileName = null; }),
          ),
        ],
      ),
      _ClientDetailsSection(
        title: 'System Component Configuration',
        icon: Icons.solar_power_rounded,
        color: Colors.purple,
        children: [_buildHardwareManagement()],
      ),
      _ClientDetailsSection(
        title: 'Financial & Installation Terms',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.teal,
        children: [
              TextFormField(
                controller: _solarRateController, 
                onChanged: (v) {
                  final numeric = v.replaceAll(',', '');
                  if (numeric.isEmpty) {
                    _solarRateController.text = '';
                    setState(() {});
                    return;
                  }
                  
                  final formatted = CurrencyFormatter.formatINR(numeric);
                  if (v != formatted) {
                    _solarRateController.value = _solarRateController.value.copyWith(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  setState(() {});
                }, 
                keyboardType: TextInputType.number, 
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Professional Solar Rate (₹)', 
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  isDense: true
                ),
              ),
          if (_solarRateController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              isExpanded: true, 
              initialValue: _isLoan, 
              decoration: const InputDecoration(
                labelText: 'Payment Structure / Funding', 
                prefixIcon: Icon(Icons.payments_rounded),
                isDense: true
              ), 
              items: const [
                DropdownMenuItem(value: false, child: Text('Direct Self-Payment')), 
                DropdownMenuItem(value: true, child: Text('Bank Finance / Loan'))
              ], 
              onChanged: (v) => setState(() => _isLoan = v!)
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Government Subsidy (₹78,000)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              value: _isSubsidy,
              onChanged: (v) => setState(() => _isSubsidy = v),
              secondary: const Icon(Icons.volunteer_activism_rounded, color: Colors.orange),
            ),
          ],
        ],
      ),
    ];
  }

  Widget _buildHardwareManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_panelConfigs.isEmpty && _inverterConfigs.isEmpty)
           const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No solar hardware added yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
        else ...[
           ..._panelConfigs.map((p) => Card(
             margin: const EdgeInsets.only(bottom: 8),
             child: ListTile(
               leading: const Icon(Icons.solar_power),
               title: Text('${p.brand} ${p.series}'),
               subtitle: Text('${p.capacityW}W x ${p.count} panels'),
               trailing: IconButton(
                 icon: const Icon(Icons.delete_outline), 
                 onPressed: () async {
                   final confirmed = await DialogUtils.showDeleteConfirmation(
                     context,
                     title: 'Remove Panels',
                     message: 'Are you sure you want to remove ${p.brand} ${p.series} from this project?',
                   );
                   if (confirmed) setState(() => _panelConfigs.remove(p));
                 }
               ),
             ),
           )),
           ..._inverterConfigs.map((i) => Card(
             margin: const EdgeInsets.only(bottom: 8),
             child: ListTile(
               leading: const Icon(Icons.power_rounded),
               title: Text('${i.brand} ${i.model}'),
               subtitle: Text('${i.capacityKw}kW x ${i.count} units'),
               trailing: IconButton(
                 icon: const Icon(Icons.delete_outline), 
                 onPressed: () async {
                   final confirmed = await DialogUtils.showDeleteConfirmation(
                     context,
                     title: 'Remove Inverters',
                     message: 'Are you sure you want to remove ${i.brand} from this project?',
                   );
                   if (confirmed) setState(() => _inverterConfigs.remove(i));
                 }
               ),
             ),
           )),
        ],
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(onPressed: _showAddPanelDialog, icon: const Icon(Icons.solar_power_rounded), label: const Text('Register Solar Panels')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _showAddInverterDialog, icon: const Icon(Icons.power_rounded), label: const Text('Register Inverter Units')),
          ],
        ),
      ],
    );
  }

  void _showAddPanelDialog() {
    String selectedBrand = _panelBrandData.keys.first;
    String selectedSeries = _panelBrandData[selectedBrand]!.first;
    String customBrand = '';
    String customSeries = '';
    String wattage = '540';
    String count = '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Solar Panels'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 DropdownButtonFormField<String>(
                   initialValue: selectedBrand, 
                   items: _panelBrandData.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                   onChanged: (v) {
                     setDialogState(() {
                       selectedBrand = v!;
                       // If Custom brand, auto-lock to Custom series
                       if (selectedBrand.contains('Custom')) {
                         selectedSeries = 'Custom Series';
                       } else {
                         selectedSeries = _panelBrandData[selectedBrand]!.first;
                       }
                     });
                   }, 
                   decoration: const InputDecoration(labelText: 'Brand')
                 ),
                 if (selectedBrand.contains('Custom')) ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: const InputDecoration(labelText: 'Custom Brand Name', hintText: 'e.g. Tata Solar'),
                     onChanged: (v) => customBrand = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 if (!selectedBrand.contains('Custom'))
                   DropdownButtonFormField<String>(
                     initialValue: selectedSeries, 
                     items: _panelBrandData[selectedBrand]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                     onChanged: (v) => setDialogState(() => selectedSeries = v!), 
                     decoration: const InputDecoration(labelText: 'Series Type')
                   ),
                 if (selectedSeries == 'Custom Series') ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: const InputDecoration(labelText: 'Custom Series Name'),
                     onChanged: (v) => customSeries = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: const InputDecoration(labelText: 'Wattage (W)', hintText: 'e.g. 540'), 
                   initialValue: '540',
                   keyboardType: TextInputType.number, 
                   inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                   onChanged: (v) => wattage = v
                 ),
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: const InputDecoration(labelText: 'Count', hintText: 'e.g. 10'), 
                   initialValue: '1',
                   keyboardType: TextInputType.number, 
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                   onChanged: (v) => count = v
                 ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(onPressed: () {
              final finalBrand = selectedBrand.contains('Custom') && customBrand.isNotEmpty ? customBrand : selectedBrand;
              final finalSeries = selectedSeries == 'Custom Series' && customSeries.isNotEmpty ? customSeries : selectedSeries;
              
              setState(() {
                _panelConfigs.add(PanelConfiguration(
                  brand: finalBrand, 
                  series: finalSeries, 
                  capacityW: int.tryParse(wattage) ?? 540, 
                  count: int.tryParse(count) ?? 1
                ));
              });
              Navigator.pop(ctx);
            }, child: const Text('ADD')),
          ],
        ),
      ),
    );
  }

  void _showAddInverterDialog() {
    String selectedBrand = _inverterBrandData.keys.first;
    String selectedModel = _inverterBrandData[selectedBrand]!.first;
    String customBrand = '';
    String customModel = '';
    String capacity = '5.0';
    String count = '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Inverters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 DropdownButtonFormField<String>(
                   initialValue: selectedBrand, 
                   items: _inverterBrandData.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                   onChanged: (v) {
                     setDialogState(() {
                       selectedBrand = v!;
                       // If Custom brand, auto-lock to Custom model
                       if (selectedBrand.contains('Custom')) {
                         selectedModel = 'Custom Model';
                       } else {
                         selectedModel = _inverterBrandData[selectedBrand]!.first;
                       }
                     });
                   }, 
                   decoration: const InputDecoration(labelText: 'Brand')
                 ),
                 if (selectedBrand.contains('Custom')) ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: const InputDecoration(labelText: 'Custom Brand Name', hintText: 'e.g. Tata Solar'),
                     onChanged: (v) => customBrand = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 if (!selectedBrand.contains('Custom'))
                   DropdownButtonFormField<String>(
                     initialValue: selectedModel, 
                     items: _inverterBrandData[selectedBrand]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
                     onChanged: (v) => setDialogState(() => selectedModel = v!), 
                     decoration: const InputDecoration(labelText: 'System Model')
                   ),
                 if (selectedModel == 'Custom Model') ...[
                   const SizedBox(height: 12),
                   TextFormField(
                     decoration: const InputDecoration(labelText: 'Custom Model Name'),
                     onChanged: (v) => customModel = v,
                   ),
                 ],
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: const InputDecoration(labelText: 'Capacity (kW)', hintText: 'e.g. 5.0'), 
                   initialValue: '5.0',
                   keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                   inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                   onChanged: (v) => capacity = v
                 ),
                 const SizedBox(height: 12),
                 TextFormField(
                   decoration: const InputDecoration(labelText: 'Count', hintText: 'e.g. 1'), 
                   initialValue: '1',
                   keyboardType: TextInputType.number, 
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                   onChanged: (v) => count = v
                 ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(onPressed: () {
              final finalBrand = selectedBrand.contains('Custom') && customBrand.isNotEmpty ? customBrand : selectedBrand;
              final finalModel = selectedModel == 'Custom Model' && customModel.isNotEmpty ? customModel : selectedModel;
              
              setState(() {
                _inverterConfigs.add(InverterConfiguration(
                  brand: finalBrand, 
                  model: finalModel, 
                  capacityKw: double.tryParse(capacity) ?? 5.0, 
                  count: int.tryParse(count) ?? 1
                ));
              });
              Navigator.pop(ctx);
            }, child: const Text('ADD')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySidebar(ThemeData theme, List<VendorPartner> vendors) {
    final solarRateText = _solarRateController.text.replaceAll(',', '');
    final solarRate = double.tryParse(solarRateText) ?? 0.0;
    final subsidyAmount = _isSubsidy ? 78000.0 : 0.0;
    final totalQuotation = solarRate;
    final netFinalClientCost = solarRate - subsidyAmount;
    
    // Strategic Finance Metrics (Basis: Total Quotation, not Net)
    final maxBankLimit = totalQuotation * 0.9;
    final strategicLoanAmount = _isLoan ? (maxBankLimit < 198000.0 ? maxBankLimit : 198000.0) : 0.0;
    final advisedDownpayment = _isLoan ? (totalQuotation - strategicLoanAmount) : totalQuotation;
    final wouldBenefitFromStrategicCap = _isLoan && maxBankLimit > 198000.0;

    return Column(
      children: [
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Project Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                _buildAuditRow('System Size', '${_totalCapacityKwp.toStringAsFixed(2)} kWp'),
                _buildAuditRow('Funding', _isLoan ? 'Bank Loan' : 'Direct Payment'),
                const Divider(height: 24),
                _buildAuditRow('Total Quotation (Basis)', '₹${CurrencyFormatter.formatINR(totalQuotation)}'),
                _buildAuditRow('Genesis Subsidy Reclaim', '₹${CurrencyFormatter.formatINR(subsidyAmount)}', color: theme.colorScheme.onSurfaceVariant),
                const Divider(height: 8),
                _buildAuditRow('Net Client Payable', '₹${CurrencyFormatter.formatINR(totalQuotation)}', isBold: true),
                
                if (_isLoan) ...[
                  const Divider(height: 32),
                  _buildAuditRow('Strategic Bank Loan', '₹${CurrencyFormatter.formatINR(strategicLoanAmount)}', color: theme.colorScheme.primary),
                  _buildAuditRow('Initial Direct Payment', '₹${CurrencyFormatter.formatINR(advisedDownpayment)}', color: theme.colorScheme.secondary),
                ],
                const Divider(height: 24),
                _buildAuditRow('Net Project Value', '₹${CurrencyFormatter.formatINR(netFinalClientCost)}', isBold: true),
                const Divider(height: 40),
                Text('Note: ₹78,000 Subsidy is routed to Genesis Bank A/C directly after MGVCL metering completion.', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Text('Professional onboarding ensures zero-error document generation.', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        if (wouldBenefitFromStrategicCap)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              color: Colors.orange.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.orange.withValues(alpha: 0.3))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text('STRATEGIC FINANCE OPTIMIZER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900, letterSpacing: 0.5))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This client is eligible for ₹${CurrencyFormatter.formatINR(maxBankLimit)} loan, but taking more than ₹1.98L will INCREASE the interest rate above 5-6%.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'ADVICE: Cap loan at ₹1,98,000 and collect ₹${CurrencyFormatter.formatINR(advisedDownpayment)} upfront to save the client thousands in interest.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAuditRow(String label, String value, {Color? color, bool isBold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Expanded(child: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: isBold ? 14 : 12))), 
          const SizedBox(width: 16),
          Text(
            value, 
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : (color != null ? FontWeight.bold : FontWeight.normal),
              color: color ?? (isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
              fontSize: isBold ? 14 : 13,
            )
          )
        ]
      )
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)))),
      child: ElevatedButton(onPressed: _saveClient, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white), child: Text(widget.existingClient != null ? 'SAVE CHANGES' : 'CREATE CLIENT PROFILE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
    );
  }

  Widget _buildRegulatoryField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? filePath,
    String? fileName,
    required VoidCallback onUpload,
    required VoidCallback onScan,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final hasFile = filePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(icon),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasFile ? fileName! : 'No document attached',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                    color: hasFile ? theme.colorScheme.primary : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasFile) ...[
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 20),
                  onPressed: () => _openDocumentPreview(filePath),
                  tooltip: 'Preview',
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                onPressed: onUpload,
                tooltip: 'Upload',
              ),
              IconButton(
                icon: const Icon(Icons.document_scanner_outlined, size: 20),
                onPressed: onScan,
                tooltip: 'Scan',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDocumentPreview(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
      }
    }
  }

  Future<void> _scanDocument({required bool isBill}) async {
    try {
      final result = await FlutterDocScanner().getScanDocuments();
      
      if (result != null && result['pdfPath'] != null) {
        final path = result['pdfPath'] as String;
        final name = path.split('/').last;
        setState(() {
          if (isBill) {
            _consumerBillFilePath = path;
            _consumerBillFileName = name;
          } else {
            _npApplicationFilePath = path;
            _npApplicationFileName = name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanner error: $e')));
      }
    }
  }

  Future<void> _pickNpApplicationPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) setState(() { _npApplicationFilePath = result.files.single.path; _npApplicationFileName = result.files.single.name; });
  }

  Future<void> _pickConsumerBillPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) setState(() { _consumerBillFilePath = result.files.single.path; _consumerBillFileName = result.files.single.name; });
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final vendors = ref.read(vendorPartnerProvider);
      final vendorName = vendors.firstWhere((v) => v.id == _selectedVendorId).name;

      final solarRate = CurrencyFormatter.parseINR(_solarRateController.text);

      final newClient = Client(
        id: widget.existingClient?.id ?? uuid.v4(),
        name: _nameController.text.toUpperCase(),
        phone: _phoneController.text,
        address: _addressController.text,
        consumerNumber: _consumerNumberController.text,
        systemSizeKwp: _totalCapacityKwp,
        createdAt: widget.existingClient?.createdAt ?? DateTime.now(),
        npApplicationNumber: _npAppNumberController.text,
        solarCostRs: solarRate,
        isSubsidy: _isSubsidy,
        subsidyAmount: 78000.0,
        isLoan: _isLoan,
        inverterConfigs: List.from(_inverterConfigs),
        panelConfigs: List.from(_panelConfigs),
        vendorName: vendorName,
      );
      if (widget.existingClient != null) {
        ref.read(clientsProvider.notifier).updateClient(newClient);
      } else {
        ref.read(clientsProvider.notifier).addClient(newClient);
      }
      if (_npApplicationFilePath != null) {
        ref.read(documentsProvider.notifier).addDocument(ClientDocument(id: uuid.v4(), clientId: newClient.id, type: DocumentType.npApplication, fileName: _npApplicationFileName!, fileUrl: _npApplicationFilePath!, uploadedAt: DateTime.now()));
      }
      if (_consumerBillFilePath != null) {
        ref.read(documentsProvider.notifier).addDocument(ClientDocument(id: uuid.v4(), clientId: newClient.id, type: DocumentType.electricityBill, fileName: _consumerBillFileName!, fileUrl: _consumerBillFilePath!, uploadedAt: DateTime.now()));
      }
      context.pop();
    }
  }
}
