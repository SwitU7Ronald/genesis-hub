import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class GeoCameraService {
  /// Reverse geocodes the coordinates to a readable address.
  static Future<String> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}, ${p.administrativeArea}, ${p.country}";
      }
      return "Unknown Address";
    } catch (e) {
      return "Error fetching address: $e";
    }
  }

  /// Appends a professional GPS watermark to the provided image file.
  static Future<File> applyWatermark({
    required File imageFile,
    required Position position,
    required String address,
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return imageFile;

    final width = image.width;
    final height = image.height;

    // 1. Prepare Metadata
    final DateFormat formatter = DateFormat('EEEE, dd/MM/yyyy hh:mm a');
    final String timestamp = formatter.format(DateTime.now());
    final String timezone = "GMT +05:30"; // Standard for India

    // Split address for better layout
    final addressParts = address.split(', ');
    final String cityState = addressParts.length > 2 
        ? "${addressParts[2]}, ${addressParts[4]}, ${addressParts[5]}"
        : address;
    final String subDetails = addressParts.take(3).join(', ');

    // 2. Fetch Map Snippet (Satellite Placeholder or Real API)
    // For production, replace with your Google/Mapbox/Yandex Key
    img.Image? mapSnippet;
    try {
      final mapUrl = "https://static-maps.yandex.ru/1.x/?ll=${position.longitude},${position.latitude}&size=300,300&z=17&l=sat";
      final response = await http.get(Uri.parse(mapUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        mapSnippet = img.decodeImage(response.bodyBytes);
      }
    } catch (_) {
      // Fallback if network fails
    }

    // 3. Define Layout Constants
    final overlayHeight = (height * 0.18).toInt();
    final boxWidth = (width * 0.85).toInt();
    final boxX = (width - boxWidth) ~/ 2;
    final boxY = (height - overlayHeight - (height * 0.05)).toInt();

    // 4. Draw Main Data Box (Dark, Semi-transparent)
    img.fillRect(
      image,
      x1: boxX,
      y1: boxY,
      x2: boxX + boxWidth,
      y2: boxY + overlayHeight,
      color: img.ColorUint8.rgba(0, 0, 0, 180),
    );

    // 5. Draw Map Snippet on the Left side of the box
    final mapSize = (overlayHeight * 0.85).toInt();
    final mapX = boxX + (overlayHeight * 0.07).toInt();
    final mapY = boxY + (overlayHeight * 0.07).toInt();

    if (mapSnippet != null) {
      final resizedMap = img.copyResize(mapSnippet, width: mapSize, height: mapSize);
      img.compositeImage(image, resizedMap, dstX: mapX, dstY: mapY);
      
      // Draw Red Pin in center of map
      img.fillCircle(image, x: mapX + mapSize~/2, y: mapY + mapSize~/2, radius: (mapSize * 0.05).toInt(), color: img.ColorUint8.rgb(255, 0, 0));
      img.drawString(image, "Google", font: img.arial14, x: mapX + 10, y: mapY + mapSize - 20, color: img.ColorUint8.rgb(255, 255, 255));
    }

    // 6. Draw Metadata
    final textX = mapX + mapSize + (width * 0.03).toInt();
    var currentY = mapY;

    // Line 1: City, State, Country
    img.drawString(
      image,
      cityState,
      font: img.arial24,
      x: textX,
      y: currentY,
      color: img.ColorUint8.rgb(255, 255, 255),
    );
    currentY += (overlayHeight * 0.2).toInt();

    // Line 2: Details
    img.drawString(
      image,
      subDetails,
      font: img.arial14,
      x: textX,
      y: currentY,
      color: img.ColorUint8.rgb(230, 230, 230),
    );
    currentY += (overlayHeight * 0.15).toInt();

    // Line 3: Lat/Long
    final latLongStr = "Lat ${position.latitude.toStringAsFixed(6)} Long ${position.longitude.toStringAsFixed(6)}";
    img.drawString(
      image,
      latLongStr,
      font: img.arial14,
      x: textX,
      y: currentY,
      color: img.ColorUint8.rgb(230, 230, 230),
    );
    currentY += (overlayHeight * 0.15).toInt();

    // Line 4: Timestamp
    img.drawString(
      image,
      "$timestamp $timezone",
      font: img.arial14,
      x: textX,
      y: currentY,
      color: img.ColorUint8.rgb(230, 230, 230),
    );

    // 7. Branding: Top Right of Box
    const branding = "GPS Map Camera";
    img.drawString(
      image,
      branding,
      font: img.arial14,
      x: boxX + boxWidth - (branding.length * 9) - 10,
      y: boxY + 10,
      color: img.ColorUint8.rgb(200, 200, 200),
    );

    // 8. Finalize Path and File
    final String newPath = imageFile.path.replaceAll('.jpg', '_geo.jpg');
    final List<int> processedBytes = img.encodeJpg(image, quality: 90);
    final File processedFile = File(newPath);
    await processedFile.writeAsBytes(processedBytes);

    return processedFile;
  }
}
