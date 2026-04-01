import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../scanner/domain/scanner_provider.dart';
import '../domain/docx_generator.dart';
import '../../clients/domain/models.dart';
import '../../clients/domain/client_provider.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key});

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _systemSizeController = TextEditingController();
  Client? _selectedClient;

  @override
  void dispose() {
    _clientNameController.dispose();
    _systemSizeController.dispose();
    super.dispose();
  }

  Future<void> _generateDocument(String type) async {
    final client = _selectedClient ?? Client(
      id: 'quick',
      name: _clientNameController.text.toUpperCase(),
      phone: '',
      address: 'Quick Entry',
      consumerNumber: 'N/A',
      systemSizeKwp: double.tryParse(_systemSizeController.text) ?? 5.0,
      createdAt: DateTime.now(),
    );

    if (client.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or enter a client name')));
      return;
    }

    final panels = ref.read(panelSerialsProvider);
    final inverters = ref.read(inverterSerialsProvider);
    
    List<int>? bytes;
    String fileName = '';

    try {
      if (type == 'AGREEMENT') {
        bytes = await DocxGenerator.createAgreement(client);
        fileName = 'Agreement_${client.name}.docx';
      } else if (type == 'QUOTATION') {
        bytes = await DocxGenerator.createQuotation(client);
        fileName = 'Quotation_${client.name}.docx';
      } else if (type == 'CERTIFICATE') {
        bytes = await DocxGenerator.createSelfCertificate(client, panels, inverters);
        fileName = 'SelfCertificate_${client.name}.docx';
      }

      if (bytes != null) {
        // Since we are generating DOCX, Printing.layoutPdf won't work directly.
        // We will share the file so the user can open it in Word/Pages.
        await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating $type: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clients = ref.watch(clientsProvider);
    final panels = ref.watch(panelSerialsProvider);
    final inverters = ref.watch(inverterSerialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agreement Engine', style: TextStyle(fontWeight: FontWeight.bold))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? constraints.maxWidth * 0.15 : 20.0,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Generation', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
                const SizedBox(height: 8),
                Text('Instantly generate standard agreements and self-certificates without permanent onboarding.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 48),
                
                // Client Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_search_rounded, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            const Text('Select Loaded Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<Client>(
                          value: _selectedClient,
                          hint: const Text('Search active clients...'),
                          isExpanded: true,
                          items: clients.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.consumerNumber})'))).toList(),
                          onChanged: (val) => setState(() {
                            _selectedClient = val;
                            if (val != null) {
                              _clientNameController.text = val.name;
                              _systemSizeController.text = val.systemSizeKwp.toString();
                            }
                          }),
                        ),
                        if (_selectedClient == null) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          Text('Or Manual Quick Entry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _clientNameController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Customer Full Name', prefixIcon: Icon(Icons.edit_note_rounded)),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _systemSizeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'System Size (kWp)', prefixIcon: Icon(Icons.bolt_rounded)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Scanned Data Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 32, color: theme.colorScheme.primary),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hardware Payloads', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${panels.length} Panels, ${inverters.length} Inverters currently in cache.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: () => context.push('/scanner'), child: const Text('SCAN MORE')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Action Grid
                Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () => _generateDocument('AGREEMENT'),
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('GENERATE NP AGREEMENT'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 60),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                            onPressed: () => _generateDocument('QUOTATION'),
                            icon: const Icon(Icons.request_quote_rounded),
                            label: const Text('QUOTATION'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 60),
                              backgroundColor: theme.colorScheme.tertiary,
                              foregroundColor: theme.colorScheme.onTertiary,
                            ),
                            onPressed: () => _generateDocument('CERTIFICATE'),
                            icon: const Icon(Icons.verified_rounded),
                            label: const Text('CERTIFICATE'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
