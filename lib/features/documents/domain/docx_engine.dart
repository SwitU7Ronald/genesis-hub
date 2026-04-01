import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../../clients/domain/models.dart';

/// Genesis DOCX Engine — Raw XML Injection
///
/// Works with ANY plain .docx template. No MS Word Developer Tab required.
/// Simply type {{ClientName}}, {{Address}} etc. in your Word document and save.
///
/// The engine handles MS Word's XML run-fragmentation automatically.
class DocxEngine {
  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> generateAgreement(
      Client client, String templatePath) async {
    final replacements = {
      '{{ClientName}}': client.name,
      '{{Name}}': client.name,
      '{{Address}}': client.address,
      '{{Phone}}': client.phone,
      '{{SystemSize}}': '${client.systemSizeKwp.toStringAsFixed(2)} kWp',
      '{{ConsumerNumber}}': client.consumerNumber,
      '{{NpApplicationNumber}}': client.npApplicationNumber ?? '-',
      '{{Date}}': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      '{{Day}}': DateFormat('dd').format(DateTime.now()),
      '{{Month}}': DateFormat('MMMM').format(DateTime.now()),
      '{{Year}}': DateFormat('yyyy').format(DateTime.now()),
      // Inverter summary (first configured inverter)
      '{{InverterBrand}}': client.inverterConfigs.isNotEmpty
          ? client.inverterConfigs.first.brand
          : '-',
      '{{InverterCapacity}}': client.inverterConfigs.isNotEmpty
          ? '${client.inverterConfigs.first.capacityKw} kW'
          : '-',
      '{{InverterCount}}': client.inverterConfigs.isNotEmpty
          ? '${client.inverterConfigs.first.count}'
          : '-',
      // Panel summary (first configured panel)
      '{{PanelBrand}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.brand
          : '-',
      '{{PanelSeries}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.series
          : '-',
      '{{PanelCapacity}}': client.panelConfigs.isNotEmpty
          ? '${client.panelConfigs.first.capacityW} W'
          : '-',
      '{{PanelCount}}': client.panelConfigs.isNotEmpty
          ? '${client.panelConfigs.first.count}'
          : '-',
    };

    final fileName =
        '${client.name.replaceAll(' ', '_')}_Agreement.docx';
    return _injectIntoDocx(
        templatePath: templatePath,
        replacements: replacements,
        outputFileName: fileName);
  }

  static Future<String?> generateSelfCertificate(
      Client client,
      List<String> panels,
      List<String> inverters,
      String templatePath) async {
    // Build panel serial block
    final panelBlock = StringBuffer();
    for (int i = 0; i < panels.length; i++) {
      panelBlock.writeln('${i + 1}. ${panels[i]}');
    }

    // Build inverter serial block
    final inverterBlock = StringBuffer();
    for (int i = 0; i < inverters.length; i++) {
      inverterBlock.writeln('${i + 1}. ${inverters[i]}');
    }

    final replacements = {
      '{{ClientName}}': client.name,
      '{{Name}}': client.name,
      '{{Address}}': client.address,
      '{{Phone}}': client.phone,
      '{{SystemSize}}': '${client.systemSizeKwp.toStringAsFixed(2)} kWp',
      '{{ConsumerNumber}}': client.consumerNumber,
      '{{NpApplicationNumber}}': client.npApplicationNumber ?? '-',
      '{{Date}}': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      '{{Day}}': DateFormat('dd').format(DateTime.now()),
      '{{Month}}': DateFormat('MMMM').format(DateTime.now()),
      '{{Year}}': DateFormat('yyyy').format(DateTime.now()),
      '{{PanelSerials}}': panelBlock.toString().trimRight(),
      '{{InverterSerials}}': inverterBlock.toString().trimRight(),
      '{{PanelCount}}': panels.length.toString(),
      '{{InverterCount}}': inverters.length.toString(),
      // Inverter config
      '{{InverterBrand}}': client.inverterConfigs.isNotEmpty
          ? client.inverterConfigs.first.brand
          : '-',
      '{{InverterCapacity}}': client.inverterConfigs.isNotEmpty
          ? '${client.inverterConfigs.first.capacityKw} kW'
          : '-',
      // Panel config
      '{{PanelBrand}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.brand
          : '-',
      '{{PanelSeries}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.series
          : '-',
      '{{PanelCapacityW}}': client.panelConfigs.isNotEmpty
          ? '${client.panelConfigs.first.capacityW} W'
          : '-',
    };

    final fileName =
        '${client.name.replaceAll(' ', '_')}_SelfCert.docx';
    return _injectIntoDocx(
        templatePath: templatePath,
        replacements: replacements,
        outputFileName: fileName);
  }

  static Future<String?> generateQuotation(
      Client client, String templatePath) async {
    final replacements = {
      '{{ClientName}}': client.name,
      '{{Name}}': client.name,
      '{{Address}}': client.address,
      '{{Phone}}': client.phone,
      '{{SystemSize}}': '${client.systemSizeKwp.toStringAsFixed(2)} kWp',
      '{{ConsumerNumber}}': client.consumerNumber,
      '{{NpApplicationNumber}}': client.npApplicationNumber ?? '-',
      '{{Date}}': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      '{{Day}}': DateFormat('dd').format(DateTime.now()),
      '{{Month}}': DateFormat('MMMM').format(DateTime.now()),
      '{{Year}}': DateFormat('yyyy').format(DateTime.now()),
      // Inverter summary
      '{{InverterBrand}}': client.inverterConfigs.isNotEmpty
          ? client.inverterConfigs.first.brand
          : '-',
      '{{InverterCapacity}}': client.inverterConfigs.isNotEmpty
          ? '${client.inverterConfigs.first.capacityKw} kW'
          : '-',
      '{{InverterCount}}': client.inverterConfigs.isNotEmpty
          ? '${client.inverterConfigs.first.count}'
          : '-',
      // Panel summary
      '{{PanelBrand}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.brand
          : '-',
      '{{PanelSeries}}': client.panelConfigs.isNotEmpty
          ? client.panelConfigs.first.series
          : '-',
      '{{PanelCapacity}}': client.panelConfigs.isNotEmpty
          ? '${client.panelConfigs.first.capacityW} W'
          : '-',
      '{{PanelCount}}': client.panelConfigs.isNotEmpty
          ? '${client.panelConfigs.first.count}'
          : '-',
    };

    final fileName =
        '${client.name.replaceAll(' ', '_')}_Quotation.docx';
    return _injectIntoDocx(
        templatePath: templatePath,
        replacements: replacements,
        outputFileName: fileName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORE ENGINE — Raw XML ZIP manipulation
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> _injectIntoDocx({
    required String templatePath,
    required Map<String, String> replacements,
    required String outputFileName,
  }) async {
    final templateFile = File(templatePath);
    if (!await templateFile.exists()) return null;

    final rawBytes = await templateFile.readAsBytes();

    // Decode the ZIP, making every file a fresh mutable copy
    final srcArchive = ZipDecoder().decodeBytes(rawBytes);
    final outArchive = Archive();

    for (final file in srcArchive.files) {
      if (!file.isFile) {
        outArchive.addFile(file);
        continue;
      }

      final isXml = file.name.endsWith('.xml') ||
          file.name.endsWith('.rels') ||
          file.name == 'word/document.xml';

      if (isXml && file.name == 'word/document.xml') {
        // ── Process the main document XML ──────────────────────────────────
        final rawContent = List<int>.from(file.content as List<int>);
        String xmlText = utf8.decode(rawContent, allowMalformed: true);

        // Step 1: De-fragment MS Word's split XML runs so {{tags}} are intact
        xmlText = _defragmentXml(xmlText);

        // Step 2: Apply all replacements
        for (final entry in replacements.entries) {
          xmlText = xmlText.replaceAll(entry.key, _escapeXml(entry.value));
        }

        final newBytes = utf8.encode(xmlText);
        outArchive.addFile(
            ArchiveFile(file.name, newBytes.length, List<int>.from(newBytes)));
      } else {
        // Copy all other files unchanged (images, styles, fonts, etc.)
        outArchive.addFile(
            ArchiveFile(file.name, file.size, List<int>.from(file.content as List<int>)));
      }
    }

    // Encode result back to ZIP bytes (ZipEncoder.encode always returns List<int> in archive v4)
    final outBytes = ZipEncoder().encode(outArchive, level: DeflateLevel.bestSpeed);

    final tempDir = Directory.systemTemp;
    final outPath = '${tempDir.path}/$outputFileName';
    await File(outPath).writeAsBytes(outBytes);
    return outPath;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // XML DEFRAGMENTATION
  //
  // MS Word's OOXML format splits text across multiple <w:r><w:t> run elements.
  // For example, "{{ClientName}}" typed in Word may be stored as:
  //   <w:r><w:t>{{Cl</w:t></w:r><w:r><w:t>ientName}}</w:t></w:r>
  //
  // This function merges consecutive runs inside a paragraph to reconstruct
  // the original text before performing replacements.
  // ─────────────────────────────────────────────────────────────────────────
  static String _defragmentXml(String xml) {
    // Strategy: for each paragraph (<w:p>...</w:p>), collect all text from
    // <w:t> elements, find {{tags}}, then re-inject via the FIRST <w:t>
    // and blank out subsequent ones.
    //
    // We use a line-based regex approach which is much safer than a full
    // XML parser and handles all fragmentation cases.
    
    // Pass 1: Remove XML-escaped curly braces if Word escaped them
    xml = xml.replaceAll('&#123;', '{').replaceAll('&#125;', '}');
    xml = xml.replaceAll('&amp;#123;', '{').replaceAll('&amp;#125;', '}');

    // Pass 2: Collapse runs. Find all paragraphs and within each paragraph
    // merge <w:t> text content across run boundaries.
    // We do this by replacing </w:t>...<w:t follow by optional attributes...>
    // with nothing (merging consecutive text nodes inside the same paragraph).
    //
    // Real MS Word XML looks like:
    //   <w:t>{{Cl</w:t></w:r><w:r><w:rPr>...</w:rPr><w:t>ientName}}</w:t>
    // We want to merge just the text content.
    
    // Paragraph-by-paragraph processing
    final paragraphRegex = RegExp(r'<w:p[ >].*?</w:p>', dotAll: true);
    
    xml = xml.replaceAllMapped(paragraphRegex, (match) {
      String para = match.group(0)!;
      
      // Collect all (run-text) pairs in this paragraph
      // Merge them so {{tags}} crossing run boundaries are reassembled
      final runTextRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
      final texts = runTextRegex.allMatches(para).map((m) => m.group(1)!).toList();
      final combined = texts.join();
      
      // Only bother if this paragraph contains a {{ tag
      if (!combined.contains('{{') && !combined.contains('}}')) {
        return para;
      }

      // Re-inject: put the full combined text into the FIRST <w:t>
      // and replace all subsequent <w:t>...</w:t> with <w:t/>
      bool first = true;
      para = para.replaceAllMapped(runTextRegex, (m) {
        if (first) {
          first = false;
          return '<w:t xml:space="preserve">${_escapeXml(combined)}</w:t>';
        }
        return '<w:t/>';
      });
      
      return para;
    });

    return xml;
  }

  /// Escape special XML characters in replacement values
  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
