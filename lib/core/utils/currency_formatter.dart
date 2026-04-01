import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat('#,##,###', 'en_IN');

  /// Formats any numeric value to Indian Rupee comma-separated string (e.g., 1,50,000)
  static String formatINR(dynamic value) {
    if (value == null) return '0';
    
    double num;
    if (value is String) {
      num = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    } else if (value is int) {
      num = value.toDouble();
    } else if (value is double) {
      num = value;
    } else {
      return '0';
    }
    
    return _inrFormatter.format(num.round());
  }

  /// Strips commas and returns a valid double for calculations
  static double parseINR(String value) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }
}
