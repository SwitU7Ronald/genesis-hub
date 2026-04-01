import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../clients/domain/models.dart';

class PdfGenerator {
  static Future<Uint8List> createAgreement(Client client) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("AGREEMENT FOR SOLAR ROOFTOP INSTALLATION", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text("This Agreement is made on $dateStr by and between:", style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.Text("GENESIS ELECTRICAL, hereinafter referred to as the 'Vendor'.", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("AND"),
            pw.SizedBox(height: 10),
            pw.Text("${client.name}, residing at ${client.address}, hereinafter referred to as the 'Applicant'.", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("WHEREAS the Applicant wishes to install a Grid-Connected Solar Rooftop System of ${client.systemSizeKwp.toStringAsFixed(2)} kWp capacity at the aforementioned address.", style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Text("The Parties hereby agree to the following terms and conditions:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildAgreementClause("1. PERMISSIONS:", "The Applicant hereby grants permission to Vendor and its authorized personnel to enter the Applicant Site for conducting feasibility study, storing, installing, inspecting, and maintaining the RTS System."),
            _buildAgreementClause("2. WARRANTIES:", "Product Warranty is limited to the warranty given by the manufacturer. Installation Warranty: Vendor warrants that all installations shall be free from workmanship defects for a period of five years. Exceptions: Any attempt by any person other than Vendor to adjust or repair the RTS System shall disentitle the Applicant of the warranty."),
            _buildAgreementClause("3. PERFORMANCE GUARANTEE:", "Vendor guarantees minimum system performance ratio of 75% as per performance ratio test carried out in adherence to IEC 61724 for a period of five years."),
            _buildAgreementClause("4. INSURANCE:", "Vendor may obtain insurance covering risks during transit until installation. Thereafter, all risk shall pass on to the Applicant."),
            _buildAgreementClause("5. LIABILITIES & INDEMNITY:", "Vendor's liability for any breach is limited to repairing or replacing the RTS System, or refunding moneys paid if unfulfilled."),
            _buildAgreementClause("6. FORCE MAJEURE:", "Neither Party shall be in default due to any delay or failure caused by acts of God, war, riot, earthquake, fire, or acts of government."),
            pw.SizedBox(height: 60),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text("Signature of Applicant", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(client.name),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text("Signature of Vendor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("GENESIS ELECTRICAL"),
                  ]
                ),
              ]
            )
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildAgreementClause(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.justify),
        ]
      )
    );
  }

  static Future<Uint8List> createSelfCertificate(Client client, List<String> panels, List<String> inverters) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    String panelSumStr = client.panelConfigs.map((p) => '${p.count} X ${p.capacityW} Wp = ${(p.count * p.capacityW)} Wp').join(' & ');
    if (panelSumStr.isEmpty) panelSumStr = '0 Wp';
    String totalKwp = '${(client.systemSizeKwp * 1000).toInt()} Wp';
    
    // table arrays
    final List<List<String>> tableData = [
      ['No.', 'Particular', 'Modules', 'Inverter'],
      ['1.', 'Make', client.panelConfigs.map((p) => p.brand).join('\n'), client.inverterConfigs.map((i) => i.brand).join('\n')],
      ['2.', 'Capacity', client.panelConfigs.map((p) => '${p.capacityW}W').join('\n'), client.inverterConfigs.map((i) => '${i.capacityKw} kW').join('\n')],
      ['3.', 'No. of Modules/Inverter', client.panelConfigs.map((p) => '${p.count}').join('\n'), client.inverterConfigs.fold<int>(0, (sum, i) => sum + i.count).toString()],
      ['4.', 'Total Capacity', totalKwp, '${client.inverterConfigs.fold<double>(0.0, (sum, i) => sum + i.totalCapacityKw).toStringAsFixed(2)} kW'],
      ['5.', 'Voltage', '41.6V', '230 Vac'],
      ['6.', 'Sr No.', panels.isNotEmpty ? 'Attached Separate Sheet' : 'Pending', inverters.isNotEmpty ? inverters.join(',\n') : 'Pending'],
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Center(child: pw.Text("Self-Certification for Solar Roof top Installations up to 10KW", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            ),
            pw.SizedBox(height: 10),
            pw.Text("This is to certify that the installation of Solar roof top power plant along with its associated equipment of capacity $panelSumStr | TOTAL = $totalKwp at ${client.address}, Has been carried out by us/me and the details of the Installation as well as the test results are as under:", style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 16),
            pw.Text("1. Details of Consumer:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(children: [ pw.SizedBox(width: 150, child: pw.Text("Name :")), pw.Text(client.name) ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [ pw.SizedBox(width: 150, child: pw.Text("Address :")), pw.Expanded(child: pw.Text(client.address)) ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [ pw.SizedBox(width: 150, child: pw.Text("Electricity Connection No. :")), pw.Text(client.consumerNumber) ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [ pw.SizedBox(width: 150, child: pw.Text("DisCom registration No. :")), pw.Text(client.npApplicationNumber ?? 'N/A') ]),
            pw.SizedBox(height: 16),
            
            pw.Text("2. Details of Solar PV cells and Inverter:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            
            pw.SizedBox(height: 16),
            pw.Text("3. Test Results:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Earthing:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Earth Tester Sr No.-11204\nEarth Resistance values for all Earth Pits:\n• 0.67 \u03A9\n• 0.45 \u03A9\n• 0.80 \u03A9 - LA", style: const pw.TextStyle(fontSize: 10)),
                ])),
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Insulation resistance:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Megger Sr No. and voltage:18254 and 1000 V\nInsulation Resistance:\n• Phase to Neutral: 476M\u03A9\n• Phase to Earth: 482M\u03A9", style: const pw.TextStyle(fontSize: 10)),
                ])),
              ]
            ),
            pw.SizedBox(height: 16),
            pw.Text("The work of aforesaid installation has been completed by us on $dateStr and it is to hereby declare that:"),
            pw.Bullet(text: "All PV modules and its supporting structures have enough mechanical strength and it conforms to the relevant codes/guidelines prescribed in this behalf.", style: const pw.TextStyle(fontSize: 10)),
            pw.Bullet(text: "All cables/wires, protective switchgears as well as Earthlings are of adequate ratings/size and they conforms to the requirements of Central Electricity Authority (Measures relating to safety and electrical supply), Regulations 2010.", style: const pw.TextStyle(fontSize: 10)),
            pw.Bullet(text: "The installation is tested by us and is found safe to be energized.", style: const pw.TextStyle(fontSize: 10)),
            
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text(client.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text("GENESIS ELECTRICAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                ),
              ]
            )
          ];
        },
      ),
    );

    // Page 2: Serials
    if (panels.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text("Hardware Serial Numbers", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text("Client: ${client.name}\nAddress: ${client.address}", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text("Panel Serials (${panels.length} units):", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 10,
                runSpacing: 5,
                children: panels.map((p) => pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Text(p, style: const pw.TextStyle(fontSize: 10))
                )).toList()
              )
            ];
          }
        )
      );
    }

    return pdf.save();
  }
}
