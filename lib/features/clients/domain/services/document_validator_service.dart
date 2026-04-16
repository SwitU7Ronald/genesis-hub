import 'package:genesis_util/features/clients/domain/entities/client.dart';

class ValidationResult {
  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.missingFields = const [],
  });

  final bool isValid;
  final String? errorMessage;
  final List<String> missingFields;
}

class DocumentValidatorService {
  /// Strictly checks if a client is completely ready to receive an officially generated Quoation.
  static ValidationResult validateQuotation(Client client) {
    if (!client.isLoan) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Quotations can only be generated for Bank Financed Loan Clients.',
      );
    }

    final missingFields = <String>[];

    if (client.address.trim().isEmpty) {
      missingFields.add('Client Residential Address');
    }
    if (client.phone.trim().isEmpty) {
      missingFields.add('Client Primary Phone Number');
    }
    if (client.consumerNumber.trim().isEmpty) {
      missingFields.add('Electricity Grid Consumer Number');
    }
    if (client.systemSizeKwp <= 0) {
      missingFields.add('System Capacity (Total kWp)');
    }
    if (client.solarCostRs == null || client.solarCostRs == 0) {
      missingFields.add('Total Project Quotation Cost Rs.');
    }

    if (missingFields.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        missingFields: missingFields,
      );
    }

    return ValidationResult(isValid: true);
  }
}
