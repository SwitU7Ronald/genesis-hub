import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCompressionService {
  /// Compresses the image for National Portal compliance
  /// Strict parameters: max 1920x1920, 75% quality, strictly JPEG.
  static Future<File?> compressForPortal(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${const Uuid().v4()}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1920,
      minHeight: 1920,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    return File(result.path);
  }
}
