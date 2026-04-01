class PanelConfiguration {
  final String brand;
  final String series;
  final int capacityW;
  final int count;

  const PanelConfiguration({
    required this.brand,
    required this.series,
    required this.capacityW,
    required this.count,
  });

  double get totalCapacityKwp => (capacityW * count) / 1000.0;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'series': series,
        'capacityW': capacityW,
        'count': count,
      };

  factory PanelConfiguration.fromJson(Map<String, dynamic> json) =>
      PanelConfiguration(
        brand: json['brand'] as String,
        series: json['series'] as String,
        capacityW: json['capacityW'] as int,
        count: json['count'] as int,
      );
}

class InverterConfiguration {
  final String brand;
  final String model;
  final double capacityKw;
  final int count;

  const InverterConfiguration({
    required this.brand,
    required this.model,
    required this.capacityKw,
    required this.count,
  });

  double get totalCapacityKw => capacityKw * count;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'capacityKw': capacityKw,
        'count': count,
      };

  factory InverterConfiguration.fromJson(Map<String, dynamic> json) =>
      InverterConfiguration(
        brand: json['brand'] as String,
        model: json['model'] as String? ?? '',
        capacityKw: (json['capacityKw'] as num).toDouble(),
        count: json['count'] as int,
      );
}

class Client {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String consumerNumber;
  final double systemSizeKwp;
  final DateTime createdAt;
  
  // NP Portal Specific Additions
  final String? npApplicationNumber;
  final List<InverterConfiguration> inverterConfigs;
  final List<PanelConfiguration> panelConfigs;
  final String vendorName; // Genesis, Dipak Choksi, etc.

  // Financial Status
  final double? solarCostRs; // Total project cost
  final bool isSubsidy;
  final double subsidyAmount;
  final bool isLoan;
  final double? initialDepositRs; // Cash/Cheque advised to meet loan optimal tier
  final SubsidyStatus subsidyStatus;

  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.consumerNumber,
    required this.systemSizeKwp,
    required this.createdAt,
    this.npApplicationNumber,
    this.inverterConfigs = const [],
    this.panelConfigs = const [],
    this.solarCostRs,
    this.isSubsidy = true,
    this.subsidyAmount = 78000.0,
    this.isLoan = false,
    this.initialDepositRs,
    this.vendorName = 'Genesis',
    this.subsidyStatus = SubsidyStatus.pendingInstallation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'consumerNumber': consumerNumber,
        'systemSizeKwp': systemSizeKwp,
        'createdAt': createdAt.toIso8601String(),
        'npApplicationNumber': npApplicationNumber,
        'inverterConfigs': inverterConfigs.map((e) => e.toJson()).toList(),
        'panelConfigs': panelConfigs.map((e) => e.toJson()).toList(),
        'solarCostRs': solarCostRs,
        'isSubsidy': isSubsidy,
        'subsidyAmount': subsidyAmount,
        'isLoan': isLoan,
        'initialDepositRs': initialDepositRs,
        'vendorName': vendorName,
        'subsidyStatus': subsidyStatus.name,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        consumerNumber: json['consumerNumber'] as String,
        systemSizeKwp: (json['systemSizeKwp'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        npApplicationNumber: json['npApplicationNumber'] as String?,
        inverterConfigs: (json['inverterConfigs'] as List<dynamic>?)
                ?.map((e) =>
                    InverterConfiguration.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        panelConfigs: (json['panelConfigs'] as List<dynamic>?)
                ?.map((e) =>
                    PanelConfiguration.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        solarCostRs: (json['solarCostRs'] as num?)?.toDouble(),
        isSubsidy: json['isSubsidy'] as bool? ?? true,
        subsidyAmount: (json['subsidyAmount'] as num?)?.toDouble() ?? 78000.0,
        isLoan: json['isLoan'] as bool? ?? false,
        initialDepositRs: (json['initialDepositRs'] as num?)?.toDouble(),
        vendorName: json['vendorName'] as String? ?? 'Genesis',
        subsidyStatus: SubsidyStatus.values.byName(json['subsidyStatus'] as String? ?? 'pendingInstallation'),
      );

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? consumerNumber,
    double? systemSizeKwp,
    DateTime? createdAt,
    String? npApplicationNumber,
    List<InverterConfiguration>? inverterConfigs,
    List<PanelConfiguration>? panelConfigs,
    double? solarCostRs,
    bool? isSubsidy,
    bool? isLoan,
    double? initialDepositRs,
    String? vendorName,
    SubsidyStatus? subsidyStatus,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      systemSizeKwp: systemSizeKwp ?? this.systemSizeKwp,
      createdAt: createdAt ?? this.createdAt,
      npApplicationNumber: npApplicationNumber ?? this.npApplicationNumber,
      inverterConfigs: inverterConfigs ?? this.inverterConfigs,
      panelConfigs: panelConfigs ?? this.panelConfigs,
      solarCostRs: solarCostRs ?? this.solarCostRs,
      isSubsidy: isSubsidy ?? this.isSubsidy,
      isLoan: isLoan ?? this.isLoan,
      initialDepositRs: initialDepositRs ?? this.initialDepositRs,
      vendorName: vendorName ?? this.vendorName,
      subsidyStatus: subsidyStatus ?? this.subsidyStatus,
    );
  }

  // --- STRATEGIC FINANCE OPTIMIZER ---
  
  /// The full project amount which is the basis for bank loan calculations.
  double get totalQuotation => solarCostRs ?? 0.0;
  
  /// Banks never give 100% of the quotation; they cap at 90%.
  double get maxBankLoanLimit => totalQuotation * 0.9;
  
  /// Strategic recommendation: Cap loan at 1,98,000 for lower interest (5-6%).
  /// This takes the minimum of 1.98L and the actual bank 90% limit.
  double get strategicLoanAmount => isLoan 
    ? (maxBankLoanLimit < 198000.0 ? maxBankLoanLimit : 198000.0) 
    : 0.0;

  /// The amount advising to be paid directly (Cash/Cheque).
  /// This is the Total Quotation minus the Strategic Loan.
  double get advisedDownpayment => isLoan 
    ? (totalQuotation - strategicLoanAmount) 
    : totalQuotation;

  /// The final net cost to the client after Genesis successfully reclaims the subsidy.
  double get netFinalClientCost => totalQuotation - (isSubsidy ? subsidyAmount : 0.0);
}

enum DocumentType {
  aadhar,
  pan,
  identityProof,
  bankPassbook,
  cancelledCheque,
  electricityBill,
  verapavti,
  sitePhoto,
  npApplication,
  agreement,
  selfCertificate,
  quotation,
  roofPhotoPreInstall,
  roofPhotoPostInstall,
  other
}

class ClientDocument {
  final String id;
  final String clientId;
  final DocumentType type;
  final String fileName;
  final String fileUrl; // Local path or cloud URL
  final DateTime uploadedAt;

  const ClientDocument({
    required this.id,
    required this.clientId,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'type': type.name,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory ClientDocument.fromJson(Map<String, dynamic> json) => ClientDocument(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        type: DocumentType.values.byName(json['type'] as String),
        fileName: json['fileName'] as String,
        fileUrl: json['fileUrl'] as String,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );
}

enum SubsidyStatus {
  pendingInstallation,
  meteringInProgress,
  readyForRedemption,
  collected
}
