import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genesis_util/core/services/geo_camera_service.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:genesis_util/core/services/image_compression_service.dart';

class DocumentService {
  final Uuid _uuid = const Uuid();

  Future<void> previewDocument(BuildContext context, ClientDocument doc) async {
    try {
      final file = File(doc.fileUrl);
      if (!(await file.exists())) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ File not found on local storage.')),
          );
        }
        return;
      }

      if (Platform.isMacOS) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(doc.fileUrl)], subject: doc.fileName),
        );
      } else {
        final result = await OpenFilex.open(doc.fileUrl);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Preview Error: $e')));
      }
    }
  }

  Future<void> downloadDocument(
    BuildContext context,
    ClientDocument doc,
  ) async {
    try {
      if (Platform.isMacOS) {
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Select Save Location',
          fileName: doc.fileName,
          type: FileType.custom,
          allowedExtensions: ['docx', 'pdf', 'jpg', 'png'],
        );

        if (outputFile != null) {
          final sourceFile = File(doc.fileUrl);
          if (await sourceFile.exists()) {
            await sourceFile.copy(outputFile);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blue,
                  content: Text(
                    '📥 Document saved to: ${p.basename(outputFile)}',
                  ),
                ),
              );
            }
          }
        }
      } else {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(doc.fileUrl)], subject: doc.fileName),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Export Error: $e')));
      }
    }
  }



  Future<ClientDocument?> pickAndPrepareDocument(
    String clientId,
    DocumentType type,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        var finalPath = result.files.single.path!;
        final ext = p.extension(finalPath).toLowerCase();
        if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
          final compressedFile = await ImageCompressionService.compressForPortal(File(finalPath));
          if (compressedFile != null) finalPath = compressedFile.path;
        }
        
        return ClientDocument(
          id: _uuid.v4(),
          clientId: clientId,
          type: type,
          fileName: p.basename(finalPath),
          fileUrl: finalPath,
          uploadedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
    return null;
  }

  Future<ClientDocument?> scanDocument(
    String clientId,
    DocumentType type,
  ) async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        try {
          final result = await FlutterDocScanner().getScanDocuments();

          if (result != null && result['pdfPath'] != null) {
            final path = result['pdfPath'] as String;
            return ClientDocument(
              id: _uuid.v4(),
              clientId: clientId,
              type: type,
              fileName: p.basename(path),
              fileUrl: path,
              uploadedAt: DateTime.now(),
            );
          }
        } catch (scanError) {
          debugPrint(
            'Scanner failed (possibly running on Simulator). Falling back to image picker: $scanError',
          );
          // If scanner fails (like on iOS simulator), fall back to standard file/image picker.
          return pickAndPrepareDocument(clientId, type);
        }
      } else {
        // Fallback to pick file on desktop platforms
        return pickAndPrepareDocument(clientId, type);
      }
    } catch (e) {
      debugPrint('Error scanning document: $e');
    }
    return null;
  }

  Future<ClientDocument?> takeCameraPhoto(
    String clientId,
    DocumentType type,
  ) async {
    try {
      final picker = ImagePicker();
      XFile? photo;

      if (Platform.isIOS || Platform.isAndroid) {
        photo = await picker.pickImage(source: ImageSource.camera);
      } else {
        // Fallback to gallery on desktop since camera isn't natively supported out of the box
        photo = await picker.pickImage(source: ImageSource.gallery);
      }

      if (photo != null) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        var savedImage = File(photo.path);

        if (serviceEnabled &&
            (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always)) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
          final address = await GeoCameraService.getAddress(
            position.latitude,
            position.longitude,
          );

          savedImage = await GeoCameraService.applyWatermark(
            imageFile: savedImage,
            position: position,
            address: address,
          );
        }
        
        // EXPORT PIPELINE - ENFORCE PORTAL COMPLIANCE
        final compressed = await ImageCompressionService.compressForPortal(savedImage);
        if (compressed != null) savedImage = compressed;

        return ClientDocument(
          id: _uuid.v4(),
          clientId: clientId,
          type: type,
          fileName: p.basename(savedImage.path),
          fileUrl: savedImage.path,
          uploadedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }
}

final documentServiceProvider = Provider<DocumentService>(
  (ref) => DocumentService(),
);
