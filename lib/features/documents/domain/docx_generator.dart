import 'dart:io';
import 'package:flutter/services.dart';
import '../../clients/domain/models.dart';
import '../../../core/docx_template/docx_template.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';

class DocxGenerator {
  static const String _templatePath = 'assets/templates/';

  /// Generates a document from a DOCX template with local assets.
  static Future<List<int>?> generateDocument({
    required String templateName,
    required Client client,
    List<String>? panels,
    List<String>? inverters,
  }) async {
    final ByteData data = await rootBundle.load('$_templatePath$templateName');
    final List<int> bytes = data.buffer.asUint8List();

    final docx = await DocxTemplate.fromBytes(bytes);
    
    final Content content = Content();
    
    // Core Client Data Mapping
    content.add(TextContent('name', client.name.toUpperCase()));
    content.add(TextContent('address', client.address));
    content.add(TextContent('phone', client.phone));
    content.add(TextContent('consumer_number', client.consumerNumber));
    content.add(TextContent('np_id', client.npApplicationNumber ?? 'N/A'));
    content.add(TextContent('kwp', '${client.systemSizeKwp.toStringAsFixed(2)} kWp'));
    content.add(TextContent('date', DateFormat('dd/MM/yyyy').format(DateTime.now())));
    content.add(TextContent('vendor', client.vendorName));

    // Financial Data (Adaptable for Quotations)
    content.add(TextContent('cost', '₹${CurrencyFormatter.formatINR(client.solarCostRs)}'));
    content.add(TextContent('deposit', '₹${CurrencyFormatter.formatINR(client.initialDepositRs)}'));
    content.add(TextContent('subsidy_status', client.isSubsidy ? 'Eligible' : 'Direct (No Subsidy)'));
    content.add(TextContent('loan_status', client.isLoan ? 'Financed' : 'Self-Funded'));
    
    final netPayable = (client.solarCostRs ?? 0) - (client.initialDepositRs ?? 0);
    content.add(TextContent('net_payable', '₹${CurrencyFormatter.formatINR(netPayable)}'));
    content.add(TextContent('raw_kwp', client.systemSizeKwp.toStringAsFixed(2)));

    // Hardware Data (if applicable)
    if (panels != null && panels.isNotEmpty) {
      final panelDesc = client.panelConfigs.map((p) => '${p.count} x ${p.brand} ${p.capacityW}W').join(', ');
      content.add(TextContent('panel_count', panels.length.toString()));
      content.add(TextContent('panel_brand', client.panelConfigs.map((p) => p.brand).join(', ')));
      content.add(TextContent('panel_details', panelDesc));
      content.add(TextContent('panel_serials', panels.join('\n')));
    }
    
    if (inverters != null && inverters.isNotEmpty) {
      final inverterDesc = client.inverterConfigs.map((i) => '${i.count} x ${i.brand} ${i.capacityKw}kW').join(', ');
      content.add(TextContent('inverter_count', inverters.length.toString()));
      content.add(TextContent('inverter_brand', client.inverterConfigs.map((i) => i.brand).join(', ')));
      content.add(TextContent('inverter_details', inverterDesc));
      content.add(TextContent('inverter_serials', inverters.join('\n')));
    }

    return await docx.generate(content);
  }

  // Pre-defined template calls for convenience
  static Future<List<int>?> createAgreement(Client client) async {
    return generateDocument(templateName: 'NP Agreement Template.docx', client: client);
  }

  static Future<List<int>?> createQuotation(Client client) async {
    return generateDocument(templateName: 'Quotation Template.docx', client: client);
  }

  static Future<List<int>?> createSelfCertificate(Client client, List<String> panels, List<String> inverters) async {
    return generateDocument(
      templateName: 'Self Certificate Template.docx', 
      client: client,
      panels: panels,
      inverters: inverters,
    );
  }
}
