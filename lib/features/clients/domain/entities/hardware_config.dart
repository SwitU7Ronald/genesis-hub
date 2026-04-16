import 'package:flutter/foundation.dart';

@immutable
class PanelConfiguration {
  // e.g. 22.95

  const PanelConfiguration({
    required this.brand,
    required this.series,
    required this.capacityW,
    required this.count,
  });

  factory PanelConfiguration.fromJson(Map<String, dynamic> json) =>
      PanelConfiguration(
        brand: json['brand'] as String,
        series: json['series'] as String,
        capacityW: json['capacityW'] as int,
        count: json['count'] as int,
      );
  final String brand;
  final String series;
  final int capacityW;
  final int count;

  double get totalCapacityKwp => (capacityW * count) / 1000.0;

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'series': series,
    'capacityW': capacityW,
    'count': count,
  };

  PanelConfiguration copyWith({
    String? brand,
    String? series,
    int? capacityW,
    int? count,
  }) {
    return PanelConfiguration(
      brand: brand ?? this.brand,
      series: series ?? this.series,
      capacityW: capacityW ?? this.capacityW,
      count: count ?? this.count,
    );
  }
}

@immutable
class InverterConfiguration {
  const InverterConfiguration({
    required this.brand,
    required this.model,
    required this.capacityKw,
    required this.count,
  });

  factory InverterConfiguration.fromJson(Map<String, dynamic> json) =>
      InverterConfiguration(
        brand: json['brand'] as String,
        model: json['model'] as String? ?? '',
        capacityKw: (json['capacityKw'] as num).toDouble(),
        count: json['count'] as int,
      );
  final String brand;
  final String model;
  final double capacityKw;
  final int count;

  double get totalCapacityKw => capacityKw * count;

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'model': model,
    'capacityKw': capacityKw,
    'count': count,
  };
}
