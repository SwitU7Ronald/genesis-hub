enum InventoryType { panel, inverter, structure, cable, other }

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.brand,
    required this.model,
    required this.type,
    required this.stockCount,
    required this.lastUpdated,
    this.unit = 'units',
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    type: InventoryType.values.byName(json['type'] as String),
    stockCount: json['stockCount'] as int,
    unit: json['unit'] as String? ?? 'units',
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
  final String id;
  final String brand;
  final String model;
  final InventoryType type;
  final int stockCount;
  final String unit; // units, meters, sets, etc.
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'type': type.name,
    'stockCount': stockCount,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  InventoryItem copyWith({
    String? brand,
    String? model,
    InventoryType? type,
    int? stockCount,
    String? unit,
  }) {
    return InventoryItem(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      type: type ?? this.type,
      stockCount: stockCount ?? this.stockCount,
      unit: unit ?? this.unit,
      lastUpdated: DateTime.now(),
    );
  }
}
