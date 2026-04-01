class VendorPartner {
  final String id;
  final String name;
  
  // Witness Details Mandatory for Partner-managed agreements
  final String witness1Name;
  final String witness2Name;
  
  final DateTime createdAt;

  const VendorPartner({
    required this.id,
    required this.name,
    required this.witness1Name,
    required this.witness2Name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'witness1Name': witness1Name,
    'witness2Name': witness2Name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VendorPartner.fromJson(Map<String, dynamic> json) => VendorPartner(
    id: json['id'] as String,
    name: json['name'] as String,
    witness1Name: json['witness1Name'] as String,
    witness2Name: json['witness2Name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  VendorPartner copyWith({
    String? name,
    String? witness1Name,
    String? witness1NamePhone, // This field is being removed, but keeping method sig minimal if needed. Actually let's clean up.
    String? witness2Name,
  }) {
    return VendorPartner(
      id: id,
      name: name ?? this.name,
      witness1Name: witness1Name ?? this.witness1Name,
      witness2Name: witness2Name ?? this.witness2Name,
      createdAt: createdAt,
    );
  }
}
