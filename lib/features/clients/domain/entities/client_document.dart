import 'package:flutter/foundation.dart';

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
  other,
}

@immutable
class ClientDocument {
  const ClientDocument({
    required this.id,
    required this.clientId,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory ClientDocument.fromJson(Map<String, dynamic> json) => ClientDocument(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    type: DocumentType.values.byName(json['type'] as String),
    fileName: json['fileName'] as String,
    fileUrl: json['fileUrl'] as String,
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
  );
  final String id;
  final String clientId;
  final DocumentType type;
  final String fileName;
  final String fileUrl; // Local path or cloud URL
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'type': type.name,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'uploadedAt': uploadedAt.toIso8601String(),
  };
}
