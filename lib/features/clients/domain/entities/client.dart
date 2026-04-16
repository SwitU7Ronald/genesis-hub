import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:genesis_util/features/clients/domain/entities/hardware_config.dart';

enum SubsidyStatus {
  pendingInstallation,
  meteringInProgress,
  readyForRedemption,
  collected,
}

@immutable
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.consumerNumber,
    required this.systemSizeKwp,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.npApplicationNumber,
    this.inverterConfigs = const [],
    this.panelConfigs = const [],
    this.solarCostRs,
    this.isSubsidy = true,
    this.isLoan = false,
    this.initialDepositRs,
    this.vendorName = 'Genesis',
    this.subsidyStatus = SubsidyStatus.pendingInstallation,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String,
    consumerNumber: json['consumerNumber'] as String,
    systemSizeKwp: (json['systemSizeKwp'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    npApplicationNumber: json['npApplicationNumber'] as String?,
    inverterConfigs:
        (json['inverterConfigs'] as List<dynamic>?)
            ?.map(
              (e) => InverterConfiguration.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [],
    panelConfigs:
        (json['panelConfigs'] as List<dynamic>?)
            ?.map((e) => PanelConfiguration.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    solarCostRs: (json['solarCostRs'] as num?)?.toDouble(),
    isSubsidy: json['isSubsidy'] as bool? ?? true,
    isLoan: json['isLoan'] as bool? ?? false,
    initialDepositRs: (json['initialDepositRs'] as num?)?.toDouble(),
    vendorName: json['vendorName'] as String? ?? 'Genesis',
    subsidyStatus: SubsidyStatus.values.byName(
      json['subsidyStatus'] as String? ?? 'pendingInstallation',
    ),
  );
  final String id;
  final String name;
  final String phone;
  final String address;
  final String consumerNumber;
  final double systemSizeKwp;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  // NP Portal Specific Additions
  final String? npApplicationNumber;
  final List<InverterConfiguration> inverterConfigs;
  final List<PanelConfiguration> panelConfigs;
  final String vendorName; // Genesis, Dipak Choksi, etc.

  // Financial Status
  final double? solarCostRs; // Total project cost
  final bool isSubsidy;
  final bool isLoan;
  final double?
  initialDepositRs; // Cash/Cheque advised to meet loan optimal tier
  final SubsidyStatus subsidyStatus;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'consumerNumber': consumerNumber,
    'systemSizeKwp': systemSizeKwp,
    'createdAt': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'npApplicationNumber': npApplicationNumber,
    'inverterConfigs': inverterConfigs.map((e) => e.toJson()).toList(),
    'panelConfigs': panelConfigs.map((e) => e.toJson()).toList(),
    'solarCostRs': solarCostRs,
    'isSubsidy': isSubsidy,
    'isLoan': isLoan,
    'initialDepositRs': initialDepositRs,
    'vendorName': vendorName,
    'subsidyStatus': subsidyStatus.name,
  };

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? consumerNumber,
    double? systemSizeKwp,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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

  double get subsidyAmount {
    if (!isSubsidy) return 0.0;
    if (systemSizeKwp <= 2.0) {
      return systemSizeKwp * 30000.0;
    } else if (systemSizeKwp < 3.0) {
      return 60000.0 + ((systemSizeKwp - 2.0) * 18000.0);
    } else {
      return 78000.0;
    }
  }

  double get totalQuotation => solarCostRs ?? 0.0;
  double get maxBankLoanLimit => totalQuotation * 0.9;
  double get strategicLoanAmount => isLoan
      ? maxBankLoanLimit
      : 0.0;
  double get advisedDownpayment =>
      isLoan ? (totalQuotation - strategicLoanAmount) : totalQuotation;
  
  // EMI approximation (roughly 1% per month for ~9-10% APR across 10 years)
  double get estimatedMonthlyEmi {
    if (!isLoan) return 0.0;
    final p = strategicLoanAmount;
    final r = 0.09 / 12; // 9% annual interest rate assumption
    final n = 120; // 10 years
    return (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  double get netFinalClientCost =>
      totalQuotation - subsidyAmount;
}
